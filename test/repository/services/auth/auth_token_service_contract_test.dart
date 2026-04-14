// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

/// RED — contratto AuthTokenService (DEV-AUTH-01).
/// Questi test falliscono perché le classi sotto test non esistono ancora.
/// Diventeranno GREEN dopo Plan 02.
void main() {
  group('AuthTokenService contract', () {
    test('DevAuthTokenService è assegnabile ad AuthTokenService', () {
      // Sarà GREEN quando DevAuthTokenService implementa AuthTokenService.
      final AuthTokenService service = DevAuthTokenService();
      expect(service, isA<AuthTokenService>());
    });

    test('AuthState ha sottotipo AuthBootstrapping', () {
      const AuthState state = AuthBootstrapping();
      expect(state, isA<AuthBootstrapping>());
    });

    test('AuthState ha sottotipo AuthUnauthenticated', () {
      const AuthState state = AuthUnauthenticated();
      expect(state, isA<AuthUnauthenticated>());
    });

    test('AuthAuthenticated espone user (User) e accessToken (String)', () {
      final user = User(
        id: 'u1',
        twitchId: 't1',
        twitchPoints: 0,
        currentCharacter: null,
        role: null,
      );
      const token = 'tok';
      final AuthState state = AuthAuthenticated(user: user, accessToken: token);
      expect((state as AuthAuthenticated).user, isA<User>());
      expect((state as AuthAuthenticated).accessToken, isA<String>());
    });

    test('AuthTokenService ha i 5 metodi del contratto', () {
      final AuthTokenService service = DevAuthTokenService();
      // Verifica esistenza metodi tramite tipo statico.
      expect(service.authStateStream, isA<Stream<AuthState>>());
      // I metodi Future vengono solo referenziati; chiamarli è responsabilità di Plan 02.
      expect(service.getAccessToken, isA<Function>());
      expect(service.login, isA<Function>());
      expect(service.logout, isA<Function>());
      expect(service.handleRevocation, isA<Function>());
    });
  });
}
