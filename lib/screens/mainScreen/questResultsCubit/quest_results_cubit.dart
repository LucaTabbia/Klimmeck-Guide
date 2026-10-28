import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_delivery_ports.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/repository/quest_result_repository.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_result_notice.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/backend_identifier.dart';
import 'package:klimmeck_guide/utils/backoff.dart';
import 'package:klimmeck_guide/utils/silent_retry.dart';

part 'quest_results_state.dart';

/// Unico proprietario dei risultati dovuti nella shell (09-CONTEXT D-08..D-13):
/// tre sorgenti, una coda per id in ordine di `resolvedAt`, conferma alla
/// chiusura. Non decide dove si apre un foglio: lo fa il presenter, che legge
/// questo stato insieme a `MapAvailabilityCubit` (un Cubit non chiama Cubit).
class QuestResultsCubit extends Cubit<QuestResultsState>
    with SafeEmit<QuestResultsState> {
  QuestResultsCubit({
    required String characterId,
    required QuestResultRepository repository,
    required PendingQuestResults pending,
    required QuestResultAcknowledger acknowledger,
    required AppLifecycleEvents lifecycle,
    required ConnectionRestoredEvents connectionRestored,
    required UserRefreshRequests userRefresh,
  }) : _characterId = characterId,
       _repository = repository,
       _pending = pending,
       _acknowledger = acknowledger,
       _lifecycle = lifecycle,
       _connectionRestored = connectionRestored,
       _userRefresh = userRefresh,
       super(const QuestResultsState());

  /// Le porte non garantiscono una risposta: un `Future` appeso fermerebbe
  /// il single-flight della rilettura e la fila delle conferme, morte
  /// compresa (09-REVIEW WR-04). `TimeoutException` è un fallimento come gli
  /// altri: rilettura ritentata, conferma pendente, morte `failed`.
  static const Duration portTimeout = Duration(seconds: 15);

  final String _characterId;
  final QuestResultRepository _repository;
  final PendingQuestResults _pending;
  final QuestResultAcknowledger _acknowledger;
  final AppLifecycleEvents _lifecycle;
  final ConnectionRestoredEvents _connectionRestored;
  final UserRefreshRequests _userRefresh;

  /// Fogli chiusi in questa sessione: dedup locale (D-10).
  final Set<String> _closedIds = {};

  /// Conferme fallite, ritentate al prossimo resume (D-10).
  final Set<String> _pendingAcks = {};

  /// Conferme riuscite (la morte è confermata prima della chiusura).
  final Set<String> _acknowledgedIds = {};

  /// Le mutation dello stesso cubit partono in fila (il BE potrebbe
  /// riordinare quelle parallele).
  Future<void> _acknowledgementTail = Future<void>.value();
  bool _hasRequestedRefreshAfterDeath = false;

  StreamSubscription<QuestResult>? _subscription;
  StreamSubscription<void>? _foregroundSubscription;
  StreamSubscription<void>? _restoredSubscription;
  Timer? _resubscribeTimer;
  int _attempt = 0;
  bool _isStreamTerminated = false;
  Future<void>? _refetchInFlight;

  /// Apre le tre sorgenti per la vita della shell (D-09): subscription,
  /// rilettura al cold start, al resume e alla riconnessione.
  void start() {
    _subscribe();
    _foregroundSubscription = _lifecycle.foregrounded.listen(
      (_) => _onForeground(),
    );
    _restoredSubscription = _connectionRestored.restored.listen(
      (_) => unawaited(refetchPending()),
    );
    unawaited(refetchPending());
  }

  /// Rilegge i risultati non confermati (D-09 c), una lettura alla volta:
  /// prima ritenta le conferme fallite (D-10), poi la lettura in silenzio.
  Future<void> refetchPending() => _refetchInFlight ??= _performRefetch()
      .whenComplete(() => _refetchInFlight = null);

  /// Tap su `questEnd` (D-11): solo l'id del payload, filtrato, e il risultato
  /// sempre riletto dal BE. NOT_FOUND/FORBIDDEN diventano un avviso; gli
  /// errori di rete restano muti (li copre la rilettura al resume).
  Future<void> requestFromTap(String? id) async {
    final resultId = validBackendIdentifier(id);
    if (resultId == null || _isKnown(resultId)) return;
    try {
      _accept(await _repository.fetch(resultId), isLive: false);
    } on QuestResultException catch (error) {
      if (!_isNoticeWorthy(error.failure)) return;
      emit(
        state.copyWith(
          notice: QuestResultNotice(
            resultId: resultId,
            failure: error.failure,
            serial: (state.notice?.serial ?? 0) + 1,
          ),
        ),
      );
    }
  }

  /// Il presenter ha aperto il foglio in testa alla coda.
  void presented(String id) {
    final head = state.head;
    if (head == null || head.id != id) return;
    emit(
      state.copyWith(
        queue: List.unmodifiable(state.queue.skip(1)),
        showing: head,
        position: state.position + 1,
      ),
    );
  }

  /// Bottone del foglio (D-05, D-10): conferma best-effort; una conferma
  /// fallita resta pendente e invisibile.
  void closed(String id) {
    if (state.showing?.id != id) return;
    _closedIds.add(id);
    emit(
      state.withoutShowing(
        queue: state.queue,
        position: state.queue.isEmpty ? 0 : state.position,
      ),
    );
    if (_acknowledgedIds.contains(id)) return;
    unawaited(_acknowledgeQuietly(id));
  }

  /// Foglio tolto da un pop esterno (logout, cambio sessione): torna in coda
  /// al suo posto senza conferma, non è stato visto (D-10).
  void dismissedExternally(String id) {
    final showing = state.showing;
    if (showing == null || showing.id != id) return;
    emit(
      state.withoutShowing(
        queue: _merged([showing]),
        position: state.position > 0 ? state.position - 1 : 0,
      ),
    );
  }

  /// Conferma attesa del foglio di morte (D-10, D-13): solo questa stacca il
  /// personaggio morto sul BE. Un fallimento lascia il foglio aperto.
  Future<void> acknowledgeDeath(String id) async {
    final showing = state.showing;
    if (showing == null || showing.id != id || !showing.isDeath) return;
    if (state.deathAcknowledgement == DeathAcknowledgement.inFlight ||
        state.deathAcknowledgement == DeathAcknowledgement.done) {
      return;
    }
    emit(state.copyWith(deathAcknowledgement: DeathAcknowledgement.inFlight));
    try {
      await _serialised(() => _acknowledger.acknowledge(id));
    } on Object {
      emit(state.copyWith(deathAcknowledgement: DeathAcknowledgement.failed));
      return;
    }
    _acknowledgedIds.add(id);
    emit(state.copyWith(deathAcknowledgement: DeathAcknowledgement.done));
    _requestUserRefreshAfterDeath();
  }

  /// Dopo la conferma il BE stacca `currentCharacter`: un refetch di `me`
  /// porta alla creazione anche se `userUpdated` si perde in una caduta del
  /// WS (D-13, checker W2). Una sola volta per vita del cubit.
  void _requestUserRefreshAfterDeath() {
    if (_hasRequestedRefreshAfterDeath) return;
    _hasRequestedRefreshAfterDeath = true;
    _userRefresh.requestUserRefresh();
  }

  void _onForeground() {
    final showing = state.showing;
    if (showing != null &&
        showing.isDeath &&
        state.deathAcknowledgement == DeathAcknowledgement.failed) {
      unawaited(acknowledgeDeath(showing.id));
    }
    unawaited(refetchPending());
  }

  Future<void> _performRefetch() async {
    emit(state.copyWith(pendingRefetch: PendingRefetch.inFlight));
    await _retryPendingAcknowledgements();
    var hasGivenUp = false;
    final results = await silentRetry(
      () => _pending.fetchUnacknowledged().timeout(portTimeout),
      isCancelled: () => isClosed,
      shouldRetry: _isTransient,
      onGiveUp: (_) => hasGivenUp = true,
    );
    emit(
      state.copyWith(
        queue: _merged(_unseen(results ?? const [])),
        pendingRefetch: hasGivenUp
            ? PendingRefetch.failed
            : PendingRefetch.done,
      ),
    );
  }

  /// Il lotto entra in un solo passo, già ordinato: il primo foglio aperto è
  /// il più vecchio qualunque sia l'ordine del BE (09-REVIEW IN-01).
  List<QuestResult> _unseen(List<QuestResult> results) {
    final unseen = <String, QuestResult>{};
    for (final result in results) {
      if (result.acknowledgedAt != null || _isKnown(result.id)) continue;
      unseen.putIfAbsent(result.id, () => result);
    }
    return unseen.values.toList();
  }

  Future<void> _retryPendingAcknowledgements() async {
    for (final id in List<String>.of(_pendingAcks)) {
      if (isClosed) return;
      await _acknowledgeQuietly(id);
    }
  }

  static bool _isTransient(Object error) =>
      error is! QuestResultException ||
      !const {
        QuestResultFailure.forbidden,
        QuestResultFailure.unauthenticated,
        QuestResultFailure.notFound,
      }.contains(error.failure);

  static bool _isNoticeWorthy(QuestResultFailure failure) =>
      failure == QuestResultFailure.notFound ||
      failure == QuestResultFailure.forbidden;

  void _subscribe() {
    _subscription = _repository
        .watch(_characterId)
        .listen(_onLiveResult, onError: _onStreamError, onDone: _onStreamDone);
  }

  void _onLiveResult(QuestResult result) {
    _attempt = 0;
    _accept(result, isLive: true);
  }

  /// Evento malformato: saltato, lo stream resta aperto. FORBIDDEN/NOT_FOUND:
  /// il personaggio è morto o archiviato, stop definitivo e una rilettura,
  /// perché il foglio di morte può stare solo nella lista non confermata
  /// (D-13, checker I2). Il refresh dell'utente spetta a `CharacterCubit`.
  void _onStreamError(Object error) {
    if (error is FormatException) return;
    if (isAccessDeniedError(error)) {
      _terminateStream();
      return;
    }
    _scheduleResubscribe();
  }

  void _onStreamDone() {
    if (isClosed || _isStreamTerminated) return;
    _scheduleResubscribe();
  }

  void _terminateStream() {
    if (_isStreamTerminated) return;
    _isStreamTerminated = true;
    unawaited(_subscription?.cancel());
    unawaited(refetchPending());
  }

  /// La subscription non ha snapshot (BACKEND-NOTES §1): dopo averla
  /// riaperta si rilegge la lista, così nessun risultato risolto durante il
  /// backoff resta perso (09-REVIEW WR-01).
  void _scheduleResubscribe() {
    if (_resubscribeTimer != null || isClosed || _isStreamTerminated) return;
    unawaited(_subscription?.cancel());
    _resubscribeTimer = Timer(
      exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay),
      () {
        _resubscribeTimer = null;
        if (isClosed || _isStreamTerminated) return;
        _subscribe();
        unawaited(refetchPending());
      },
    );
  }

  Future<void> _acknowledgeQuietly(String id) async {
    try {
      await _serialised(() => _acknowledger.acknowledge(id));
      _pendingAcks.remove(id);
      _acknowledgedIds.add(id);
    } on Object {
      _pendingAcks.add(id);
    }
  }

  Future<void> _serialised(Future<void> Function() mutation) {
    final run = _acknowledgementTail.then(
      (_) => mutation().timeout(portTimeout),
    );
    _acknowledgementTail = run.catchError((Object _) {});
    return run;
  }

  /// Una sola istanza per id; scarta chiusi, pendenti, confermati sul BE
  /// (D-09, D-10). `isLive` segna l'arrivo per il banner del presenter.
  void _accept(QuestResult result, {required bool isLive}) {
    if (result.acknowledgedAt != null || _isKnown(result.id)) return;
    emit(
      state.copyWith(
        queue: _merged([result]),
        arrival: isLive ? result : null,
        arrivalSerial: isLive ? state.arrivalSerial + 1 : null,
      ),
    );
  }

  bool _isKnown(String id) =>
      _closedIds.contains(id) ||
      _pendingAcks.contains(id) ||
      _acknowledgedIds.contains(id) ||
      state.showing?.id == id ||
      state.queue.any((queued) => queued.id == id);

  List<QuestResult> _merged(Iterable<QuestResult> results) =>
      List<QuestResult>.unmodifiable(
        <QuestResult>[...state.queue, ...results]..sort(_byResolution),
      );

  static int _byResolution(QuestResult a, QuestResult b) {
    final byTime = a.resolvedAt.compareTo(b.resolvedAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  @override
  Future<void> close() {
    _resubscribeTimer?.cancel();
    return Future.wait([
      ?_subscription?.cancel(),
      ?_foregroundSubscription?.cancel(),
      ?_restoredSubscription?.cancel(),
      super.close(),
    ]);
  }
}
