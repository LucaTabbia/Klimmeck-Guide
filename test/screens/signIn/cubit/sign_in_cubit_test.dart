import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthTokenService service;

  setUp(() {
    service = MockAuthTokenService();
  });

  test('initial state is SignInIdle', () {
    expect(SignInCubit(service).state, const SignInIdle());
  });

  blocTest<SignInCubit, SignInState>(
    'successful login goes back to idle',
    build: () => SignInCubit(service),
    setUp: () => when(() => service.login()).thenAnswer((_) async {}),
    act: (cubit) => cubit.signInWithTwitch(),
    expect: () => [const SignInInProgress(), const SignInIdle()],
  );

  blocTest<SignInCubit, SignInState>(
    'cancelled login is silent',
    build: () => SignInCubit(service),
    setUp: () =>
        when(() => service.login()).thenThrow(const LoginCancelledException()),
    act: (cubit) => cubit.signInWithTwitch(),
    expect: () => [const SignInInProgress(), const SignInIdle()],
  );

  blocTest<SignInCubit, SignInState>(
    'unavailable login maps to twitchNotConfigured',
    build: () => SignInCubit(service),
    setUp: () => when(
      () => service.login(),
    ).thenThrow(const LoginUnavailableException()),
    act: (cubit) => cubit.signInWithTwitch(),
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.twitchNotConfigured),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'failed login maps to connection failure',
    build: () => SignInCubit(service),
    setUp: () =>
        when(() => service.login()).thenThrow(const LoginFailedException('x')),
    act: (cubit) => cubit.signInWithTwitch(),
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.connection),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'generic exception maps to connection failure',
    build: () => SignInCubit(service),
    setUp: () => when(() => service.login()).thenThrow(Exception('boom')),
    act: (cubit) => cubit.signInWithTwitch(),
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.connection),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'second tap while in progress is ignored',
    build: () => SignInCubit(service),
    setUp: () => when(() => service.login()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }),
    act: (cubit) async {
      final first = cubit.signInWithTwitch();
      await cubit.signInWithTwitch();
      await first;
    },
    expect: () => [const SignInInProgress(), const SignInIdle()],
    verify: (_) => verify(() => service.login()).called(1),
  );

  test('closing the cubit while login is in flight does not throw', () async {
    final completer = Completer<void>();
    when(() => service.login()).thenAnswer((_) => completer.future);
    final cubit = SignInCubit(service);
    final pending = cubit.signInWithTwitch();
    await cubit.close();
    completer.complete();
    await expectLater(pending, completes);
  });
}
