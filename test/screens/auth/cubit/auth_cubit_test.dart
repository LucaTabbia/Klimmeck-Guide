import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

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

  test('start twice calls initialize once', () async {
    final cubit = AuthCubit(service);
    await cubit.start();
    await cubit.start();
    verify(() => service.initialize()).called(1);
    await cubit.close();
  });

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

  test('close cancels the subscription', () async {
    final cubit = AuthCubit(service);
    await cubit.start();
    await cubit.close();
    controller.add(authenticated());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isClosed, isTrue);
  });
}
