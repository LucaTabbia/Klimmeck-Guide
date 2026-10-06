import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fixtures/dev_auth_env.dart';
import '../../../helpers/mocks.dart';

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
    test(
      'initialize() emette AuthBootstrapping poi AuthAuthenticated',
      () async {
        final expectation = expectLater(
          service.authStateStream,
          emitsInOrder([isA<AuthBootstrapping>(), isA<AuthAuthenticated>()]),
        );

        await service.initialize();
        await expectation;
      },
    );

    test(
      'AuthAuthenticated ha user.id == testUserId dopo initialize()',
      () async {
        await service.initialize();

        final authenticated =
            await service.authStateStream.firstWhere(
                  (s) => s is AuthAuthenticated,
                )
                as AuthAuthenticated;

        expect(authenticated.user.id, equals(testUserId));
        expect(authenticated.user.twitchId, equals(testTwitchId));
        expect(authenticated.accessToken, equals(testAccessToken));
      },
    );

    test(
      'getAccessToken() ritorna testAccessToken dopo initialize()',
      () async {
        await service.initialize();
        final token = await service.getAccessToken();
        expect(token, equals(testAccessToken));
      },
    );
  });

  group('DevAuthTokenService me alignment (D-25)', () {
    late MockBackendMeSource meSource;

    const backendUser = User(
      id: 'backend-dev-id',
      twitchId: testTwitchId,
      twitchPoints: 0,
      currentCharacter: null,
      role: RoleType.innkeeper,
    );

    DevAuthTokenService buildAligned({
      Duration meTimeout = const Duration(seconds: 3),
    }) => DevAuthTokenService(meSource: meSource, meTimeout: meTimeout);

    Future<AuthAuthenticated> authenticatedAfterInit(
      DevAuthTokenService aligned,
    ) async {
      await aligned.initialize();
      return await aligned.authStateStream.firstWhere(
            (s) => s is AuthAuthenticated,
          )
          as AuthAuthenticated;
    }

    setUp(() => meSource = MockBackendMeSource());

    test('uses the backend user when me succeeds', () async {
      when(() => meSource.fetchMe(any())).thenAnswer((_) async => backendUser);
      final aligned = buildAligned();
      addTearDown(aligned.dispose);

      final authenticated = await authenticatedAfterInit(aligned);

      expect(authenticated.user.id, equals('backend-dev-id'));
      expect(authenticated.user.role, equals(RoleType.innkeeper));
      verify(() => meSource.fetchMe(testAccessToken)).called(1);
    });

    test('falls back to the .env user when me throws', () async {
      when(
        () => meSource.fetchMe(any()),
      ).thenThrow(const TransientAuthFailure('offline'));
      final aligned = buildAligned();
      addTearDown(aligned.dispose);

      final authenticated = await authenticatedAfterInit(aligned);

      expect(authenticated.user.id, equals(testUserId));
    });

    test('falls back to the .env user when me times out', () async {
      when(
        () => meSource.fetchMe(any()),
      ).thenAnswer((_) => Completer<User>().future);
      final aligned = buildAligned(meTimeout: const Duration(milliseconds: 50));
      addTearDown(aligned.dispose);

      final authenticated = await authenticatedAfterInit(aligned);

      expect(authenticated.user.id, equals(testUserId));
    });

    test('uses the .env user without a me source', () async {
      final bare = DevAuthTokenService();
      addTearDown(bare.dispose);

      final authenticated = await authenticatedAfterInit(bare);

      expect(authenticated.user.id, equals(testUserId));
    });

    test('skips me when the dev access token is empty', () async {
      await loadTestEnv(accessToken: '');
      final aligned = buildAligned();
      addTearDown(aligned.dispose);

      final authenticated = await authenticatedAfterInit(aligned);

      expect(authenticated.user.id, equals(testUserId));
      verifyNever(() => meSource.fetchMe(any()));
    });

    test('login() after logout aligns with me again', () async {
      when(() => meSource.fetchMe(any())).thenAnswer((_) async => backendUser);
      final aligned = buildAligned();
      addTearDown(aligned.dispose);
      await aligned.initialize();
      await aligned.logout();

      await aligned.login();

      verify(() => meSource.fetchMe(testAccessToken)).called(2);
    });
  });
}
