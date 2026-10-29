import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
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
  }) : _repository = repository,
       _clock = clock,
       super(PendingRequestsState(serverNow: clock.now()));

  final InnkeeperRepository _repository;
  final ServerClockService _clock;

  StreamSubscription<List<PendingRequest>>? _subscription;
  Timer? _resubscribeTimer;
  int _attempt = 0;
  bool _isTerminated = false;

  void start() => _subscribe();

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
    _resubscribeTimer?.cancel();
    unawaited(_subscription?.cancel());
    emit(state.copyWith(isForbidden: true));
  }

  @override
  Future<void> close() {
    _resubscribeTimer?.cancel();
    return Future.wait([?_subscription?.cancel(), super.close()]);
  }
}
