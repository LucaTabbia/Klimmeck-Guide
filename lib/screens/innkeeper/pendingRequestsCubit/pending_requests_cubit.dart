import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/backoff.dart';

part 'pending_requests_state.dart';

/// Unico consumatore di `pendingRequestsUpdated` (graphql.md), creato con la
/// route del pannello e chiuso con essa (10-CONTEXT D-04/D-10). Riconnessione
/// silenziosa con backoff limitato; FORBIDDEN è terminale. Il BE manda uno
/// snapshot a ogni sottoscrizione: dopo una riconnessione non serve rileggere
/// (C5).
class PendingRequestsCubit extends Cubit<PendingRequestsState>
    with SafeEmit<PendingRequestsState> {
  PendingRequestsCubit({
    required InnkeeperRepository repository,
    required ServerClockService clock,
    required AppLifecycleEvents lifecycle,
    this.tick = defaultTick,
    this.rereadDelays = arrivalRereadDelays,
  }) : _repository = repository,
       _clock = clock,
       _lifecycle = lifecycle,
       super(PendingRequestsState(serverNow: clock.now()));

  static const Duration defaultTick = Duration(seconds: 1);

  /// Il BE chiude un viaggio libero per job o sweep, fino a ~60 s dopo
  /// `endTime`, senza emettere sulla coda (C5).
  static const List<Duration> arrivalRereadDelays = [
    Duration(seconds: 5),
    Duration(seconds: 65),
  ];

  final Duration tick;
  final List<Duration> rereadDelays;

  final InnkeeperRepository _repository;
  final ServerClockService _clock;
  final AppLifecycleEvents _lifecycle;

  StreamSubscription<List<PendingRequest>>? _subscription;
  StreamSubscription<void>? _foregroundSubscription;
  Timer? _resubscribeTimer;
  Timer? _tickTimer;
  final List<Timer> _rereadTimers = [];

  /// Una coppia di riletture per personaggio, `endTime` e ritardo.
  final Set<String> _scheduledRereads = {};
  int _attempt = 0;
  bool _isTerminated = false;
  Future<void>? _refetchInFlight;

  void start() {
    _subscribe();
    _foregroundSubscription = _lifecycle.foregrounded.listen(
      (_) => unawaited(refetch()),
    );
  }

  /// Rilettura silenziosa, una alla volta: resume, arrivi, richiesta della UI.
  Future<void> refetch() => _refetchInFlight ??= _performRefetch().whenComplete(
    () => _refetchInFlight = null,
  );

  /// Rimozione ottimistica dopo il completamento (D-13): la carta resta
  /// nascosta finché uno snapshot non la toglie. Se lo snapshot l'ha già
  /// tolta non c'è nulla da nascondere: una futura richiesta sulla stessa
  /// quest deve restare visibile.
  void markCompleted(String questId) {
    if (!state.requests.any((request) => request.quest.id == questId)) return;
    emit(state.copyWith(hiddenQuestIds: {...state.hiddenQuestIds, questId}));
  }

  /// Un fallimento non FORBIDDEN resta muto: ritenta il prossimo innesco,
  /// mai un ciclo.
  Future<void> _performRefetch() async {
    if (isClosed || _isTerminated) return;
    try {
      final requests = await _repository.fetchQueue();
      if (isClosed || _isTerminated) return;
      _applySnapshot(requests);
    } on InnkeeperException catch (error) {
      if (error.failure == InnkeeperFailure.forbidden) _terminate();
    }
  }

  void _subscribe() {
    _subscription = _repository.watchQueue().listen(
      _onSnapshot,
      onError: _onStreamError,
      onDone: _onStreamDone,
    );
  }

  void _onSnapshot(List<PendingRequest> requests) {
    _attempt = 0;
    _applySnapshot(requests);
  }

  void _applySnapshot(List<PendingRequest> requests) {
    emit(
      state.copyWith(
        requests: List.unmodifiable(requests),
        isLoaded: true,
        serverNow: _clock.now(),
        hiddenQuestIds: {
          for (final questId in state.hiddenQuestIds)
            if (requests.any((request) => request.quest.id == questId)) questId,
        },
      ),
    );
    _scheduleArrivalRereads();
    _syncTick();
  }

  /// Viaggi dei partecipanti visibili: le corsie occupate non hanno carta.
  Iterable<({String characterId, DateTime endTime})> get _travels => [
    for (final PendingRequest(:character) in state.requests)
      if (!character.isBusy)
        if (character.travel case final travel?)
          (characterId: character.id, endTime: travel.endTime),
  ];

  bool get _hasRunningTravel {
    final now = _clock.now();
    return _travels.any((travel) => now.isBefore(travel.endTime));
  }

  void _scheduleArrivalRereads() {
    for (final (:characterId, :endTime) in _travels) {
      for (final (index, delay) in rereadDelays.indexed) {
        final key = '$characterId|${endTime.toIso8601String()}|$index';
        if (!_scheduledRereads.add(key)) continue;
        _rereadTimers.add(
          Timer(_untilServerTime(endTime.add(delay)), _onReread),
        );
      }
    }
  }

  Duration _untilServerTime(DateTime moment) {
    final wait = moment.difference(_clock.now());
    return wait.isNegative ? Duration.zero : wait;
  }

  void _onReread() {
    if (isClosed || _isTerminated) return;
    unawaited(refetch());
  }

  void _syncTick() {
    if (!_hasRunningTravel) return _stopTick();
    _tickTimer ??= Timer.periodic(tick, (_) => _onTick());
  }

  void _onTick() {
    if (isClosed || _isTerminated) return _stopTick();
    emit(state.copyWith(serverNow: _clock.now()));
    if (!_hasRunningTravel) _stopTick();
  }

  void _stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _cancelTimers() {
    _resubscribeTimer?.cancel();
    _stopTick();
    for (final timer in _rereadTimers) {
      timer.cancel();
    }
    _rereadTimers.clear();
  }

  /// Evento malformato: saltato, lo stream resta aperto. FORBIDDEN: il ruolo
  /// è stato revocato, stop definitivo (T-10-11).
  void _onStreamError(Object error) {
    if (error is FormatException) return;
    if (error is SubscriptionStreamException && error.code == forbiddenCode) {
      _terminate();
      return;
    }
    _scheduleResubscribe();
  }

  void _onStreamDone() {
    if (isClosed || _isTerminated) return;
    _scheduleResubscribe();
  }

  void _scheduleResubscribe() {
    if (_resubscribeTimer != null || isClosed || _isTerminated) return;
    unawaited(_subscription?.cancel());
    _resubscribeTimer = Timer(
      exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay),
      () {
        _resubscribeTimer = null;
        if (isClosed || _isTerminated) return;
        _subscribe();
      },
    );
  }

  void _terminate() {
    if (_isTerminated) return;
    _isTerminated = true;
    _cancelTimers();
    unawaited(_subscription?.cancel());
    emit(state.copyWith(isForbidden: true));
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return Future.wait([
      ?_subscription?.cancel(),
      ?_foregroundSubscription?.cancel(),
      super.close(),
    ]);
  }
}
