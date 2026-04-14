import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fixtures/dev_auth_env.dart';

/// RED — init + getAccessToken (DEV-AUTH-02).
/// Diventerà GREEN dopo Plan 02.
void main() {
  late DevAuthTokenService service;

  setUp(() async {
    await loadTestEnv();
    service = DevAuthTokenService();
  });

  tearDown(() => service.dispose());

  group('DevAuthTokenService init', () {
    test('initialize() emette AuthBootstrapping poi AuthAuthenticated', () async {
      final expectation = expectLater(
        service.authStateStream,
        emitsInOrder([
          isA<AuthBootstrapping>(),
          isA<AuthAuthenticated>(),
        ]),
      );

      await service.initialize();
      await expectation;
    });

    test('AuthAuthenticated ha user.id == testUserId dopo initialize()', () async {
      await service.initialize();

      final authenticated = await service.authStateStream
          .firstWhere((s) => s is AuthAuthenticated) as AuthAuthenticated;

      expect(authenticated.user.id, equals(testUserId));
      expect(authenticated.user.twitchId, equals(testTwitchId));
      expect(authenticated.accessToken, equals(testAccessToken));
    });

    test('getAccessToken() ritorna testAccessToken dopo initialize()', () async {
      await service.initialize();
      final token = await service.getAccessToken();
      expect(token, equals(testAccessToken));
    });
  });
}
