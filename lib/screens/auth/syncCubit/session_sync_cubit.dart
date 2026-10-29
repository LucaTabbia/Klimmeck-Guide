import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_watchdog.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/backoff.dart';
import 'package:klimmeck_guide/utils/silent_retry.dart';

part 'session_sync_state.dart';

/// Unico consumer di `userUpdated` per tutta la sessione autenticata
/// (graphql.md). Vive nel sottoalbero di sessione chiavato su `user.id`
/// (teardown D-11) e fa entrare ogni evento nella sessione tramite
/// `AuthTokenService.adoptUser` (D-07).
///
/// FORBIDDEN/NOT_FOUND sullo stream e' terminale (vincolo backend): ritentare
/// martellerebbe il server, l'unico rimedio e' un singolo refetch di `me`.
/// Errori e chiusure transitorie ri-sottoscrivono in silenzio con backoff
/// limitato (D-14); socket e stream alimentano il watchdog (D-15). Ogni
/// riconnessione del socket dopo la prima connessione va sul
/// [ConnectionRestoredBus] (09-CONTEXT D-09).
class SessionSyncCubit extends Cubit<SessionSyncState>
    with SafeEmit<SessionSyncState> {
  SessionSyncCubit({
    required KlimmeckGraphQl api,
    required AuthTokenService auth,
    required SyncWatchdog watchdog,
    required Stream<bool> connection,
    required AppLifecycleEvents lifecycle,
    required Stream<void> userRefreshRequests,
    ConnectionRestoredBus? connectionRestored,
  }) : _api = api,
       _auth = auth,
       _watchdog = watchdog,
       _connection = connection,
       _lifecycle = lifecycle,
       _userRefreshRequests = userRefreshRequests,
       _connectionRestored = connectionRestored,
       super(const SessionSyncStarting());

  final KlimmeckGraphQl _api;
  final AuthTokenService _auth;
  final SyncWatchdog _watchdog;
  final Stream<bool> _connection;
  final AppLifecycleEvents _lifecycle;
  final Stream<void> _userRefreshRequests;
  final ConnectionRestoredBus? _connectionRestored;

  StreamSubscription<User>? _userSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<void>? _backgroundSubscription;
  StreamSubscription<void>? _foregroundSubscription;
  StreamSubscription<void>? _refreshRequestSubscription;
  Timer? _resubscribeTimer;
  int _attempt = 0;
  int _eventCount = 0;
  bool _isUserStreamTerminated = false;
  bool _hasConnected = false;
  bool _isConnected = false;
  Future<void>? _refreshInFlight;
  Future<void>? _queuedRefresh;

  void start() {
    _subscribeToUser();
    _connectionSubscription = _connection.listen(_onConnection);
    _backgroundSubscription = _lifecycle.backgrounded.listen(
      (_) => _watchdog.suspend(),
    );
    _foregroundSubscription = _lifecycle.foregrounded.listen((_) {
      _watchdog.resume();
      unawaited(refreshUser());
    });
    _refreshRequestSubscription = _userRefreshRequests.listen(
      (_) => unawaited(refreshUser(force: true)),
    );
  }

  /// Rilegge `me` e lo applica alla sessione, silenzioso e scartato se un
  /// evento live lo ha superato. Di norma una richiesta durante un volo si
  /// unisce a quello (foreground). Con [force] (recovery di uno stream
  /// terminato) serve invece una lettura piu' recente del volo in corso:
  /// le richieste forzate si fondono in un solo refetch accodato.
  Future<void> refreshUser({bool force = false}) {
    final inFlight = _refreshInFlight;
    if (inFlight == null) return _startUserRefresh();
    if (!force) return inFlight;
    return _queuedRefresh ??= inFlight.catchError((_) {}).then((_) {
      _queuedRefresh = null;
      return _startUserRefresh();
    });
  }

  Future<void> _startUserRefresh() {
    late final Future<void> flight;
    flight = _performUserRefresh().whenComplete(() {
      if (identical(_refreshInFlight, flight)) _refreshInFlight = null;
    });
    return _refreshInFlight = flight;
  }

  void _onConnection(bool isConnected) {
    isConnected
        ? _watchdog.markHealthy(SyncSource.socket)
        : _watchdog.markDegraded(SyncSource.socket);
    if (isConnected && _hasConnected && !_isConnected) {
      _connectionRestored?.notifyRestored();
    }
    if (isConnected) _hasConnected = true;
    _isConnected = isConnected;
  }

  bool get _isSessionEnding => isClosed || _watchdog.isLatched;

  void _subscribeToUser() {
    _userSubscription = _api.subscribeToUser().listen(
      _onUser,
      onError: _onUserStreamError,
      onDone: _onUserStreamDone,
    );
  }

  void _onUser(User user) {
    _eventCount++;
    _attempt = 0;
    _watchdog.markHealthy(SyncSource.userStream);
    if (_adopt(user)) emit(const SessionSyncLive());
  }

  bool _adopt(User user) {
    final isAdopted = _auth.adoptUser(user);
    if (!isAdopted) {
      debugPrint('[Sync] dropped userUpdated of another identity');
    }
    return isAdopted;
  }

  void _onUserStreamError(Object error) {
    if (isAccessDeniedError(error)) {
      _terminateUserStream(error);
      return;
    }
    _scheduleResubscribe();
  }

  void _onUserStreamDone() {
    if (_isSessionEnding || _isUserStreamTerminated) return;
    _scheduleResubscribe();
  }

  void _terminateUserStream(Object error) {
    if (_isUserStreamTerminated) return;
    _isUserStreamTerminated = true;
    _userSubscription?.cancel();
    _watchdog.markTerminated(SyncSource.userStream);
    final code = error is SubscriptionStreamException
        ? error.code
        : error.runtimeType;
    debugPrint('[Sync] userUpdated rejected: $code');
    unawaited(refreshUser(force: true));
  }

  void _scheduleResubscribe() {
    if (_resubscribeTimer != null || _isSessionEnding) return;
    _watchdog.markDegraded(SyncSource.userStream);
    emit(const SessionSyncRecovering());
    _userSubscription?.cancel();
    _resubscribeTimer = Timer(
      exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay),
      () {
        _resubscribeTimer = null;
        if (!_isSessionEnding) _subscribeToUser();
      },
    );
  }

  Future<void> _performUserRefresh() async {
    final eventsBefore = _eventCount;
    final user = await silentRetry(
      _api.getMe,
      isCancelled: () => isClosed,
      shouldRetry: (error) => !isAccessDeniedError(error),
    );
    if (user == null || isClosed) return;
    _watchdog.touch();
    if (_eventCount == eventsBefore) _adopt(user);
  }

  @override
  Future<void> close() {
    _resubscribeTimer?.cancel();
    _watchdog.release(SyncSource.userStream);
    _watchdog.release(SyncSource.socket);
    return Future.wait([
      ?_userSubscription?.cancel(),
      ?_connectionSubscription?.cancel(),
      ?_backgroundSubscription?.cancel(),
      ?_foregroundSubscription?.cancel(),
      ?_refreshRequestSubscription?.cancel(),
      super.close(),
    ]);
  }
}
