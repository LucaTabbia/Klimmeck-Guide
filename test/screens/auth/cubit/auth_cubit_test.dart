import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAuthTokenService service;
  late StreamController<AuthState> controller;

  AuthAuthenticated authenticated() =>
      AuthAuthenticated(user: buildTestUser(), accessToken: 'token');

  setUp(() {
    service = MockAuthTokenService();
    controller = StreamController<AuthState>.broadcast();
    when(() => service.authStateStream).thenAnswer((_) => controller.stream);
    when(() => service.initialize()).thenAnswer((_) async {});
    when(() => service.logout()).thenAnswer((_) async {});
    when(() => service.adoptUser(any())).thenReturn(true);
  });

  setUpAll(() => registerFallbackValue(buildTestUser()));

  tearDown(() => controller.close());

  test('initial state is AuthBootstrapping', () {
    expect(AuthCubit(service).state, const AuthBootstrapping());
  });

  test('start subscribes to the stream before calling initialize', () async {
    final cubit = AuthCubit(service);
    await cubit.start();
    verifyInOrder([() => service.authStateStream, () => service.initialize()]);
    await cubit.close();
  });

  test('adoptUser delegates to the service and reports its verdict', () {
    final user = buildTestUserWithCharacter();
    expect(AuthCubit(service).adoptUser(user), isTrue);
    verify(() => service.adoptUser(user)).called(1);
  });

  test('adoptUser reports a handover refused by the service', () {
    when(() => service.adoptUser(any())).thenReturn(false);
    expect(AuthCubit(service).adoptUser(buildTestUserWithCharacter()), isFalse);
  });

  test('start twice calls initialize once', () async {
    final cubit = AuthCubit(service);
    await cubit.start();
    await cubit.start();
    verify(() => service.initialize()).called(1);
    await cubit.close();
  });

  blocTest<AuthCubit, AuthState>(
    'a failing initialize lands on sign-in instead of an unhandled error',
    build: () => AuthCubit(service),
    setUp: () => when(
      () => service.initialize(),
    ).thenAnswer((_) async => throw StateError('storage unavailable')),
    act: (cubit) => cubit.start(),
    expect: () => [const AuthUnauthenticated()],
    errors: () => [isA<StateError>()],
  );

  blocTest<AuthCubit, AuthState>(
    'a failing initialize keeps a state the service already resolved',
    build: () => AuthCubit(service),
    setUp: () => when(() => service.initialize()).thenAnswer((_) async {
      controller.add(authenticated());
      await Future<void>.delayed(Duration.zero);
      throw StateError('late failure');
    }),
    act: (cubit) => cubit.start(),
    expect: () => [authenticated()],
    errors: () => [isA<StateError>()],
  );

  blocTest<AuthCubit, AuthState>(
    'mirrors authenticated state from the service stream',
    build: () => AuthCubit(service),
    act: (cubit) async {
      await cubit.start();
      controller.add(authenticated());
    },
    expect: () => [authenticated()],
  );

  blocTest<AuthCubit, AuthState>(
    'mirrors live twitchPoints and role changes in order',
    build: () => AuthCubit(service),
    act: (cubit) async {
      await cubit.start();
      controller.add(
        AuthAuthenticated(
          user: buildTestUser().copyWith(twitchPoints: 5),
          accessToken: 'token',
        ),
      );
      controller.add(
        AuthAuthenticated(
          user: buildTestUser().copyWith(
            twitchPoints: 50,
            role: RoleType.innkeeper,
          ),
          accessToken: 'token',
        ),
      );
    },
    expect: () => [
      isA<AuthAuthenticated>()
          .having((s) => s.user.twitchPoints, 'twitchPoints', 5)
          .having((s) => s.user.role, 'role', RoleType.adventurer),
      isA<AuthAuthenticated>()
          .having((s) => s.user.twitchPoints, 'twitchPoints', 50)
          .having((s) => s.user.role, 'role', RoleType.innkeeper),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'keeps the session expired reason intact',
    build: () => AuthCubit(service),
    act: (cubit) async {
      await cubit.start();
      controller.add(
        const AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
      );
    },
    expect: () => [
      const AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'showSignIn while bootstrapping emits unauthenticated',
    build: () => AuthCubit(service),
    act: (cubit) => cubit.showSignIn(),
    expect: () => [const AuthUnauthenticated()],
  );

  blocTest<AuthCubit, AuthState>(
    'showSignIn when authenticated emits nothing',
    build: () => AuthCubit(service),
    seed: authenticated,
    act: (cubit) => cubit.showSignIn(),
    expect: () => <AuthState>[],
  );

  blocTest<AuthCubit, AuthState>(
    'late authentication after showSignIn is mirrored',
    build: () => AuthCubit(service),
    act: (cubit) async {
      await cubit.start();
      cubit.showSignIn();
      controller.add(authenticated());
    },
    expect: () => [const AuthUnauthenticated(), authenticated()],
  );

  blocTest<AuthCubit, AuthState>(
    'logout delegates to the service without emitting by itself',
    build: () => AuthCubit(service),
    act: (cubit) => cubit.logout(),
    expect: () => <AuthState>[],
    verify: (_) => verify(() => service.logout()).called(1),
  );

  group('logout', () {
    late MockPushSessionCleanup cleanup;

    setUp(() {
      cleanup = MockPushSessionCleanup();
      when(() => cleanup.unregister()).thenAnswer((_) async {});
    });

    test('caps the push unregister wait at two seconds', () {
      expect(AuthCubit.pushUnregisterTimeout, const Duration(seconds: 2));
    });

    test('unregisters the push device before the service logout', () async {
      await AuthCubit(service, pushCleanup: cleanup).logout();
      verifyInOrder([() => cleanup.unregister(), () => service.logout()]);
    });

    test('a hanging unregister delays the service logout by two seconds', () {
      fakeAsync((async) {
        when(
          () => cleanup.unregister(),
        ).thenAnswer((_) => Completer<void>().future);
        var completed = false;
        AuthCubit(
          service,
          pushCleanup: cleanup,
        ).logout().then((_) => completed = true);

        async.elapse(const Duration(milliseconds: 1999));
        verifyNever(() => service.logout());

        async.elapse(const Duration(milliseconds: 1));
        verify(() => service.logout()).called(1);
        async.flushMicrotasks();
        expect(completed, isTrue);
      });
    });

    test('a failing unregister never blocks the service logout', () async {
      when(
        () => cleanup.unregister(),
      ).thenAnswer((_) async => throw StateError('offline'));
      await expectLater(
        AuthCubit(service, pushCleanup: cleanup).logout(),
        completes,
      );
      verify(() => service.logout()).called(1);
    });

    test('without push cleanup logs out through the service only', () async {
      await AuthCubit(service).logout();
      verify(() => service.logout()).called(1);
    });
  });

  test('close cancels the subscription', () async {
    final cubit = AuthCubit(service);
    await cubit.start();
    await cubit.close();
    controller.add(authenticated());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isClosed, isTrue);
  });
}
