import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/repository/push_device_failure.dart';
import 'package:klimmeck_guide/repository/push_device_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';
import 'package:klimmeck_guide/repository/services/push/push_messaging_port.dart';
import 'package:klimmeck_guide/repository/services/push/push_session_cleanup.dart';
import 'package:klimmeck_guide/repository/storage/active_user_store.dart';
import 'package:klimmeck_guide/repository/storage/device_identity_store.dart';
import 'package:klimmeck_guide/utils/silent_retry.dart';

/// Ciclo di vita della registrazione push (D-07/D-08/D-09), vivo per tutto il processo.
/// Registra una volta per utente per processo e a ogni refresh del token; ritenta in
/// silenzio i fallimenti transitori e, dopo una rinuncia, al ritorno in foreground; a fine
/// sessione cancella utente attivo e vassoio.
class PushRegistrationCoordinator implements PushSessionCleanup {
  PushRegistrationCoordinator({
    required Stream<AuthState> authStates,
    required PushMessagingPort messaging,
    required PushDeviceRepository repository,
    required DeviceIdentityStore deviceIdentity,
    required ActiveUserStore activeUser,
    required LocalNotificationsPort localNotifications,
    Stream<void> foregrounds = const Stream<void>.empty(),
  }) : _authStates = authStates,
       _foregrounds = foregrounds,
       _messaging = messaging,
       _repository = repository,
       _deviceIdentity = deviceIdentity,
       _activeUser = activeUser,
       _localNotifications = localNotifications;

  static const int maxRegistrationAttempts = 5;
  static const Duration maxRetryDelay = Duration(seconds: 30);

  /// Attesa massima della registrazione in volo prima della rimozione: lascia alla
  /// mutation di rimozione il resto del budget di logout di `AuthCubit` (2 s).
  static const Duration registrationDrainTimeout = Duration(seconds: 1);

  final Stream<AuthState> _authStates;
  final PushMessagingPort _messaging;
  final PushDeviceRepository _repository;
  final DeviceIdentityStore _deviceIdentity;
  final ActiveUserStore _activeUser;
  final LocalNotificationsPort _localNotifications;
  final Stream<void> _foregrounds;

  String? _sessionUserId;
  bool _suspended = false;

  /// Vero appena questo processo ha visto un token FCM non nullo: senza, il backend non può
  /// avere una riga di questa esecuzione (push disabilitato, run senza JSON) e la rimozione
  /// si salta, così il logout non attende la rete.
  bool _hasSeenToken = false;

  /// Ogni nuova registrazione, sospensione o fine sessione invalida i retry precedenti.
  int _generation = 0;

  /// Vero quando il retry ha rinunciato (WR-02): il prossimo ritorno in foreground
  /// riprova in silenzio, così una rete instabile al login non lascia senza push.
  bool _retryOnForeground = false;

  /// Tentativo di registrazione sul filo: la rimozione lo attende (WR-01), altrimenti
  /// una `register` lenta potrebbe ricreare la riga dopo l'`unregister`.
  Future<void>? _attemptInFlight;

  /// Gli stati auth si gestiscono uno alla volta (WR-03): un `Unauthenticated` arrivato
  /// durante la scrittura dell'utente attivo lo cancella sempre dopo di essa.
  Future<void> _authQueue = Future<void>.value();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<void>? _foregroundSubscription;

  void start() {
    if (_authSubscription != null) return;
    _authSubscription = _authStates.listen(_enqueueAuthState);
    _tokenSubscription = _messaging.tokenRefreshes.listen(_onTokenRefresh);
    _foregroundSubscription = _foregrounds.listen(_onForeground);
  }

  void _enqueueAuthState(AuthState state) {
    _authQueue = _authQueue.then((_) => _onAuthState(state));
  }

  Future<void> _onAuthState(AuthState state) async {
    switch (state) {
      case AuthAuthenticated(:final user):
        if (user.id == _sessionUserId) return;
        _sessionUserId = user.id;
        _suspended = false;
        await _guarded('active user write', () => _activeUser.write(user.id));
        _register();
      case AuthUnauthenticated():
        await _endSession();
      case AuthBootstrapping():
        return;
    }
  }

  void _onTokenRefresh(String token) {
    if (_sessionUserId == null || _suspended) return;
    _register(token: token);
  }

  void _onForeground(void _) {
    if (!_retryOnForeground || _sessionUserId == null || _suspended) return;
    _register();
  }

  void _register({String? token}) {
    final generation = ++_generation;
    _retryOnForeground = false;
    unawaited(
      silentRetry<void>(
        () => _trackAttempt(_registerOnce(token, generation)),
        isCancelled: () => _isCancelled(generation),
        shouldRetry: _isTransient,
        onGiveUp: _onRegistrationGivenUp,
        maxAttempts: maxRegistrationAttempts,
        maxDelay: maxRetryDelay,
      ),
    );
  }

  void _onRegistrationGivenUp(Object error) {
    _retryOnForeground = true;
    debugPrint('Push registration stopped (${_describe(error)})');
  }

  bool _isCancelled(int generation) =>
      generation != _generation || _suspended || _sessionUserId == null;

  Future<void> _trackAttempt(Future<void> attempt) {
    _attemptInFlight = attempt;
    return attempt.whenComplete(() {
      if (identical(_attemptInFlight, attempt)) _attemptInFlight = null;
    });
  }

  /// Senza token (ancora) disponibile non si registra: arriverà con `tokenRefreshes`.
  /// Un token arrivato dopo una sospensione non parte più verso il backend.
  Future<void> _registerOnce(String? refreshedToken, int generation) async {
    final deviceId = await _deviceIdentity.readOrCreate();
    final token = refreshedToken ?? await _messaging.token();
    if (token == null) return;
    _hasSeenToken = true;
    if (_isCancelled(generation)) return;
    await _repository.register(deviceId: deviceId, token: token);
  }

  /// D-08: sospende la registrazione e attende quella in volo prima di rimuovere il
  /// device, così nessun refresh, retry o richiesta lenta può ri-registrarlo tra questa
  /// chiamata e il logout del backend (Pitfall 5).
  @override
  Future<void> unregister() async {
    if (_sessionUserId == null) return;
    _suspended = true;
    _generation++;
    await _drainAttemptInFlight();
    if (!_hasSeenToken) return;
    await _guarded('unregister', () async {
      final deviceId = await _deviceIdentity.readOrCreate();
      await _repository.unregister(deviceId);
    });
  }

  Future<void> _drainAttemptInFlight() async {
    final attempt = _attemptInFlight;
    if (attempt == null) return;
    await _guarded(
      'registration drain',
      () => attempt.timeout(registrationDrainTimeout),
    );
  }

  Future<void> _endSession() async {
    final hadSession = _sessionUserId != null;
    _sessionUserId = null;
    _suspended = false;
    _retryOnForeground = false;
    _generation++;
    await _guarded('active user clear', _activeUser.clear);
    if (hadSession) await _guarded('tray clear', _localNotifications.cancelAll);
  }

  Future<void> dispose() async {
    _sessionUserId = null;
    _generation++;
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }

  static bool _isTransient(Object error) =>
      error is! PushDeviceException || error.failure.isRetryable;

  static String _describe(Object error) => error is PushDeviceException
      ? error.failure.name
      : '${error.runtimeType}';

  static Future<void> _guarded(
    String step,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      debugPrint('Push $step failed (${_describe(error)})');
    }
  }
}
