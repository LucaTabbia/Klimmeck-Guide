import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fixtures/dev_auth_env.dart';

void main() {
  late DevAuthTokenService service;
  late int teardownCalls;

  DevAuthTokenService buildService({bool teardownThrows = false}) {
    return DevAuthTokenService(
      onSessionTeardown: () async {
        teardownCalls++;
        if (teardownThrows) throw StateError('teardown failed');
      },
    );
  }

  setUp(() async {
    teardownCalls = 0;
    await loadTestEnv();
    service = buildService();
  });

  tearDown(() => service.dispose());

  group('DevAuthTokenService start state', () {
    test('starts authenticated by default', () async {
      final expectation = expectLater(
        service.authStateStream,
        emitsInOrder([isA<AuthBootstrapping>(), isA<AuthAuthenticated>()]),
      );

      await service.initialize();
      await expectation;
      expect(await service.getAccessToken(), equals(testAccessToken));
    });

    test('starts signed out when DEV_AUTH_START_SIGNED_OUT is true', () async {
      await loadTestEnv(startSignedOut: 'true');
      final expectation = expectLater(
        service.authStateStream,
        emitsInOrder([
          isA<AuthBootstrapping>(),
          const AuthUnauthenticated(reason: UnauthenticatedReason.signedOut),
        ]),
      );

      await service.initialize();
      await expectation;
      expect(await service.getAccessToken(), isNull);
    });

    test('treats DEV_AUTH_START_SIGNED_OUT case-insensitively', () async {
      await loadTestEnv(startSignedOut: 'TRUE');
      await service.initialize();

      expect(service.authStateStream, emits(isA<AuthUnauthenticated>()));
    });

    test('ignores DEV_AUTH_START_SIGNED_OUT values other than true', () async {
      await loadTestEnv(startSignedOut: 'no');
      await service.initialize();

      expect(service.authStateStream, emits(isA<AuthAuthenticated>()));
    });

    test('works without constructor arguments', () async {
      final bare = DevAuthTokenService();
      addTearDown(bare.dispose);

      await bare.initialize();
      await bare.logout();

      expect(await bare.getAccessToken(), isNull);
    });
  });

  group('DevAuthTokenService transitions', () {
    setUp(() async => service.initialize());

    test('logout() runs teardown once and emits signedOut', () async {
      final expectation = expectLater(
        service.authStateStream,
        emitsInOrder([
          isA<AuthAuthenticated>(),
          const AuthUnauthenticated(reason: UnauthenticatedReason.signedOut),
        ]),
      );

      await service.logout();
      await expectation;
      expect(teardownCalls, equals(1));
      expect(await service.getAccessToken(), isNull);
    });

    test('logout() still emits signedOut when teardown throws', () async {
      service.dispose();
      service = buildService(teardownThrows: true);
      await service.initialize();

      await service.logout();

      expect(
        service.authStateStream,
        emits(
          const AuthUnauthenticated(reason: UnauthenticatedReason.signedOut),
        ),
      );
    });

    test(
      'login() after logout emits Authenticated without Bootstrapping',
      () async {
        await service.logout();
        final expectation = expectLater(
          service.authStateStream,
          emitsInOrder([isA<AuthUnauthenticated>(), isA<AuthAuthenticated>()]),
        );

        await service.login();
        await expectation;
        expect(await service.getAccessToken(), equals(testAccessToken));
      },
    );

    test('handleRevocation() runs teardown and emits sessionExpired', () async {
      await service.handleRevocation();

      expect(teardownCalls, equals(1));
      expect(
        service.authStateStream,
        emits(
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.sessionExpired,
          ),
        ),
      );
      expect(await service.getAccessToken(), isNull);
    });
  });
}
