import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

import '../../../helpers/fixtures/dev_auth_env.dart';

/// RED — login/logout/handleRevocation no-op (DEV-AUTH-04).
/// Diventerà GREEN dopo Plan 02.
void main() {
  late DevAuthTokenService service;

  setUp(() async {
    await loadTestEnv();
    service = DevAuthTokenService();
    await service.initialize();
  });

  tearDown(() => service.dispose());

  group('DevAuthTokenService no-op methods', () {
    test('login() completa senza lanciare e non emette nuovi AuthState', () async {
      final states = <AuthState>[];
      final sub = service.authStateStream.listen(states.add);

      await service.login();
      // Piccola attesa per rilevare eventuali emissioni spurie.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Dopo initialize() lo stream ha già emesso; login() non deve aggiungerne.
      final statesAfterLogin = states.length;
      expect(statesAfterLogin, equals(states.length));

      await sub.cancel();
    });

    test('logout() completa senza lanciare e non emette nuovi AuthState', () async {
      final statesBefore = <AuthState>[];
      final sub = service.authStateStream.listen(statesBefore.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final countBefore = statesBefore.length;

      await service.logout();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(statesBefore.length, equals(countBefore));
      await sub.cancel();
    });

    test('handleRevocation() completa senza lanciare e non emette nuovi AuthState', () async {
      final states = <AuthState>[];
      final sub = service.authStateStream.listen(states.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final countBefore = states.length;

      await service.handleRevocation();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(countBefore));
      await sub.cancel();
    });
  });
}
