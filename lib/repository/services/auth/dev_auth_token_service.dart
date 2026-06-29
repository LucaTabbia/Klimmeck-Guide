import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';

import 'auth_token_service.dart';

/// Implementazione stub di [AuthTokenService] per lo sviluppo locale.
///
/// Legge l'identità e il token di accesso dal file `.env` tramite
/// `flutter_dotenv`. Non usa secure storage (D-04 di 01-CONTEXT.md).
///
/// Questa classe viene sostituita da `OAuthTokenService` in Phase 11
/// senza toccare i consumer (GraphQL auth link, dio interceptor, Cubit).
///
/// Variabili `.env` richieste:
/// - `DEV_AUTH_ACCESS_TOKEN` — token di accesso stub
/// - `DEV_AUTH_USER_ID` — id utente backend
/// - `DEV_AUTH_TWITCH_ID` — id canale Twitch
/// - `DEV_AUTH_ROLE` — uno tra `guard`, `adventurer`, `innkeeper`
class DevAuthTokenService extends AuthTokenService {
  DevAuthTokenService() : _controller = StreamController<AuthState>.broadcast();

  final StreamController<AuthState> _controller;
  AuthState? _lastState;

  @override
  Stream<AuthState> get authStateStream => Stream<AuthState>.multi((listener) {
        final cached = _lastState;
        if (cached != null) {
          listener.add(cached);
        }
        final subscription = _controller.stream.listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = subscription.cancel;
      });

  void _emit(AuthState state) {
    _lastState = state;
    _controller.add(state);
  }

  /// Bootstrap hook: emette `AuthBootstrapping` → `AuthAuthenticated` con
  /// il test user costruito dai valori `.env`.
  ///
  /// Da chiamare esattamente una volta da `main.dart` prima di `runApp`.
  @override
  Future<void> initialize() async {
    _emit(const AuthBootstrapping());

    final accessToken = dotenv.env['DEV_AUTH_ACCESS_TOKEN'] ?? '';
    final userId = dotenv.env['DEV_AUTH_USER_ID'] ?? '';
    final twitchId = dotenv.env['DEV_AUTH_TWITCH_ID'] ?? '';
    final role = _parseRole(dotenv.env['DEV_AUTH_ROLE']);

    final user = User(
      id: userId,
      twitchId: twitchId,
      twitchPoints: 0,
      currentCharacter: null,
      role: role,
    );

    _emit(AuthAuthenticated(user: user, accessToken: accessToken));
  }

  /// Ritorna il token di accesso corrente letto da dotenv.
  ///
  /// Può ritornare `null` se `DEV_AUTH_ACCESS_TOKEN` non è presente nel `.env`.
  @override
  Future<String?> getAccessToken() async => dotenv.env['DEV_AUTH_ACCESS_TOKEN'];

  /// No-op in Phase 1. Phase 11 aprirà il browser OAuth PKCE Twitch.
  @override
  Future<void> login() async {
    if (kDebugMode) {
      debugPrint('[DevAuth] login() — no-op in dev stub');
    }
  }

  /// No-op in Phase 1. Phase 11 revocherà il token su Twitch.
  @override
  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('[DevAuth] logout() — no-op in dev stub');
    }
  }

  /// No-op in Phase 1. Phase 11 invaliderà la sessione locale.
  @override
  Future<void> handleRevocation() async {
    if (kDebugMode) {
      debugPrint('[DevAuth] handleRevocation() — no-op in dev stub');
    }
  }

  /// Chiude lo [StreamController] e libera le risorse.
  ///
  /// Dopo `dispose()` lo stream non emette ulteriori eventi.
  @override
  void dispose() {
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

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
