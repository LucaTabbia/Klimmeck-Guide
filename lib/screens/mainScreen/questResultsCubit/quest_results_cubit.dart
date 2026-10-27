import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_delivery_ports.dart';
import 'package:klimmeck_guide/repository/quest_result_repository.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_result_notice.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

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
  }) : _pending = pending,
       _acknowledger = acknowledger,
       _userRefresh = userRefresh,
       super(const QuestResultsState());

  final PendingQuestResults _pending;
  final QuestResultAcknowledger _acknowledger;
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

  Future<void> refetchPending() async {
    final results = await _pending.fetchUnacknowledged();
    for (final result in results) {
      _accept(result, isLive: false);
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
        queue: _inserted(showing),
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
    final run = _acknowledgementTail.then((_) => mutation());
    _acknowledgementTail = run.catchError((Object _) {});
    return run;
  }

  /// Una sola istanza per id; scarta chiusi, pendenti, confermati sul BE
  /// (D-09, D-10). `isLive` segna l'arrivo per il banner del presenter.
  void _accept(QuestResult result, {required bool isLive}) {
    if (result.acknowledgedAt != null || _isKnown(result.id)) return;
    emit(
      state.copyWith(
        queue: _inserted(result),
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

  List<QuestResult> _inserted(QuestResult result) =>
      List<QuestResult>.unmodifiable(
        <QuestResult>[...state.queue, result]..sort(_byResolution),
      );

  static int _byResolution(QuestResult a, QuestResult b) {
    final byTime = a.resolvedAt.compareTo(b.resolvedAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }
}
