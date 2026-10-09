import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';

import 'auth_state_channel.dart';
import 'backend_auth_api.dart';
import 'auth_token_service.dart';

/// Implementazione di [AuthTokenService] per il bypass di sviluppo
/// (`DEV_AUTH_ENABLED=true`), attivo finché non esistono le chiavi Twitch.
///
/// Legge identità e token dal file `.env` tramite `flutter_dotenv` e simula
/// le transizioni di sessione senza browser né secure storage:
/// - cold start: `AuthAuthenticated` direttamente (D-24), oppure
///   `AuthUnauthenticated` con `DEV_AUTH_START_SIGNED_OUT=true` (D-29);
/// - `logout()` / `handleRevocation()`: teardown iniettato, poi
///   `AuthUnauthenticated` (`signedOut` / `sessionExpired`);
/// - `login()`: torna `AuthAuthenticated` con l'identità dev.
///
/// L'utente è allineato al backend via `me` (best-effort, con timeout) e
/// ricade sui valori `.env` se il backend non risponde (D-25): il backend
/// crea l'utente dev da `DEV_AUTH_TWITCH_ID` e ne possiede l'id, quindi
/// `DEV_AUTH_USER_ID` resta solo fallback offline.
///
/// Nessuna guardia `kReleaseMode` (D-30): il backend è il confine di
/// sicurezza. Lo stub viene rimosso in Phase 12.
///
/// Variabili `.env`:
/// - `DEV_AUTH_ACCESS_TOKEN` — token di accesso dev
/// - `DEV_AUTH_USER_ID` — id utente (fallback offline)
/// - `DEV_AUTH_TWITCH_ID` — id canale Twitch
/// - `DEV_AUTH_ROLE` — uno tra `guard`, `adventurer`, `innkeeper`
/// - `DEV_AUTH_START_SIGNED_OUT` — `true` per partire disconnessi
class DevAuthTokenService extends AuthTokenService {
  DevAuthTokenService({
    BackendMeSource? meSource,
    Future<void> Function()? onSessionTeardown,
    Duration meTimeout = const Duration(seconds: 3),
  }) : _meSource = meSource,
       _onSessionTeardown = onSessionTeardown,
       _meTimeout = meTimeout;

  final BackendMeSource? _meSource;
  final Future<void> Function()? _onSessionTeardown;
  final Duration _meTimeout;
  final AuthStateChannel _channel = AuthStateChannel();
  bool _isSignedIn = false;

  @override
  Stream<AuthState> get authStateStream => _channel.stream;

  /// Bootstrap hook: emette `AuthBootstrapping` poi lo stato iniziale.
  ///
  /// Da chiamare esattamente una volta da `AuthCubit.start()` (cold start).
  @override
  Future<void> initialize() async {
    debugPrint(
      '[DevAuth] WARNING: dev auth bypass is ACTIVE (DEV_AUTH_ENABLED=true). '
      'Never ship this configuration.',
    );
    _channel.emit(const AuthBootstrapping());

    if (_startSignedOut) {
      _channel.emit(const AuthUnauthenticated());
      return;
    }
    await _signIn();
  }

  /// Ritorna il token dev, o `null` se la sessione simulata è chiusa.
  @override
  Future<String?> getAccessToken() async =>
      _isSignedIn ? dotenv.env['DEV_AUTH_ACCESS_TOKEN'] : null;

  /// Riapre la sessione simulata, senza browser (D-24).
  @override
  Future<void> login() => _signIn();

  /// Esegue il teardown e chiude la sessione simulata.
  @override
  Future<void> logout() => _endSession(UnauthenticatedReason.signedOut);

  /// Simula la revoca della sessione (mostra il notice D-10 in dev).
  @override
  Future<void> handleRevocation() =>
      _endSession(UnauthenticatedReason.sessionExpired);

  @override
  bool adoptUser(User user) {
    final current = _channel.current;
    if (current is! AuthAuthenticated || current.user.id != user.id) {
      return false;
    }
    _channel.emit(
      AuthAuthenticated(user: user, accessToken: current.accessToken),
    );
    return true;
  }

  /// Chiude il canale di stato e libera le risorse.
  ///
  /// Dopo `dispose()` lo stream non emette ulteriori eventi.
  @override
  void dispose() {
    _channel.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String get _envAccessToken => dotenv.env['DEV_AUTH_ACCESS_TOKEN'] ?? '';

  bool get _startSignedOut =>
      dotenv.env['DEV_AUTH_START_SIGNED_OUT']?.trim().toLowerCase() == 'true';

  Future<void> _signIn() async {
    _isSignedIn = true;
    _channel.emit(
      AuthAuthenticated(
        user: await _resolveUser(),
        accessToken: _envAccessToken,
      ),
    );
  }

  Future<void> _endSession(UnauthenticatedReason reason) async {
    try {
      await _onSessionTeardown?.call();
    } catch (error) {
      debugPrint('[DevAuth] session teardown failed: ${error.runtimeType}');
    }
    _isSignedIn = false;
    _channel.emit(AuthUnauthenticated(reason: reason));
  }

  Future<User> _resolveUser() async {
    final envUser = _userFromEnv();
    final meSource = _meSource;
    final token = _envAccessToken;
    if (meSource == null || token.isEmpty) return envUser;
    try {
      return await meSource.fetchMe(token).timeout(_meTimeout);
    } catch (error) {
      debugPrint(
        '[DevAuth] me alignment failed (${error.runtimeType}), '
        'using .env identity',
      );
      return envUser;
    }
  }

  User _userFromEnv() {
    return User(
      id: dotenv.env['DEV_AUTH_USER_ID'] ?? '',
      twitchId: dotenv.env['DEV_AUTH_TWITCH_ID'] ?? '',
      twitchPoints: 0,
      currentCharacter: null,
      role: _parseRole(dotenv.env['DEV_AUTH_ROLE']),
    );
  }

  /// Converte la stringa `DEV_AUTH_ROLE` in [RoleType].
  ///
  /// Normalizza a lowercase e usa `byName`. Se il valore è sconosciuto o
  /// `null`, fa fallback a [RoleType.adventurer] con warning in debug
  /// (T-01-02-03: gestisce `ArgumentError` di `byName` senza crashare).
  RoleType _parseRole(String? raw) {
    if (raw == null) return RoleType.adventurer;
    final normalized = raw.trim().toLowerCase();
    try {
      return RoleType.values.byName(normalized);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[DevAuth] unknown role "$raw", falling back to adventurer');
      }
      return RoleType.adventurer;
    }
  }
}
