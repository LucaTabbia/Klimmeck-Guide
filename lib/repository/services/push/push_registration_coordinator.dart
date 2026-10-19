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
/// silenzio i fallimenti transitori; a fine sessione cancella utente attivo e vassoio.
class PushRegistrationCoordinator implements PushSessionCleanup {
  PushRegistrationCoordinator({
    required Stream<AuthState> authStates,
    required PushMessagingPort messaging,
    required PushDeviceRepository repository,
    required DeviceIdentityStore deviceIdentity,
    required ActiveUserStore activeUser,
    required LocalNotificationsPort localNotifications,
  }) : _authStates = authStates,
       _messaging = messaging,
       _repository = repository,
       _deviceIdentity = deviceIdentity,
       _activeUser = activeUser,
       _localNotifications = localNotifications;

  static const int maxRegistrationAttempts = 5;
  static const Duration maxRetryDelay = Duration(seconds: 30);

  final Stream<AuthState> _authStates;
  final PushMessagingPort _messaging;
  final PushDeviceRepository _repository;
  final DeviceIdentityStore _deviceIdentity;
  final ActiveUserStore _activeUser;
  final LocalNotificationsPort _localNotifications;

  String? _sessionUserId;
  bool _suspended = false;

  /// Vero appena questo processo ha visto un token FCM non nullo: senza, il backend non può
  /// avere una riga di questa esecuzione (push disabilitato, run senza JSON) e la rimozione
  /// si salta, così il logout non attende la rete.
  bool _hasSeenToken = false;

  /// Ogni nuova registrazione, sospensione o fine sessione invalida i retry precedenti.
  int _generation = 0;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;

  void start() {
    if (_authSubscription != null) return;
    _authSubscription = _authStates.listen(_onAuthState);
    _tokenSubscription = _messaging.tokenRefreshes.listen(_onTokenRefresh);
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

  void _register({String? token}) {
    final generation = ++_generation;
    unawaited(
      silentRetry<void>(
        () => _registerOnce(token),
        isCancelled: () =>
            generation != _generation || _suspended || _sessionUserId == null,
        shouldRetry: _isTransient,
        onGiveUp: (error) =>
            debugPrint('Push registration stopped (${_describe(error)})'),
        maxAttempts: maxRegistrationAttempts,
        maxDelay: maxRetryDelay,
      ),
    );
  }

  /// Senza token (ancora) disponibile non si registra: arriverà con `tokenRefreshes`.
  Future<void> _registerOnce(String? refreshedToken) async {
    final deviceId = await _deviceIdentity.readOrCreate();
    final token = refreshedToken ?? await _messaging.token();
    if (token == null) return;
    _hasSeenToken = true;
    await _repository.register(deviceId: deviceId, token: token);
  }

  /// D-08: sospende la registrazione prima di rimuovere il device, così nessun refresh o
  /// retry può ri-registrarlo tra questa chiamata e il logout del backend (Pitfall 5).
  @override
  Future<void> unregister() async {
    if (_sessionUserId == null || !_hasSeenToken) return;
    _suspended = true;
    _generation++;
    await _guarded('unregister', () async {
      final deviceId = await _deviceIdentity.readOrCreate();
      await _repository.unregister(deviceId);
    });
  }

  Future<void> _endSession() async {
    final hadSession = _sessionUserId != null;
    _sessionUserId = null;
    _suspended = false;
    _generation++;
    await _guarded('active user clear', _activeUser.clear);
    if (hadSession) await _guarded('tray clear', _localNotifications.cancelAll);
  }

  Future<void> dispose() async {
    _sessionUserId = null;
    _generation++;
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
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
