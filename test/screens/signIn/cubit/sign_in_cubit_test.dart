import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/legal_documents.dart';
import 'package:klimmeck_guide/config/twitch_channel.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/recording_link_opener.dart';
import '../../../helpers/mocks.dart';

const String _acceptedLegalVersion = 'v-test';

void main() {
  late MockAuthTokenService service;
  late RecordingLinkOpener links;

  setUp(() {
    service = MockAuthTokenService();
    links = RecordingLinkOpener();
  });

  SignInCubit buildCubit() => SignInCubit(service, links);

  Future<void> anyLogin() =>
      service.login(acceptedLegalVersion: any(named: 'acceptedLegalVersion'));

  Future<void> signIn(SignInCubit cubit) =>
      cubit.signInWithTwitch(acceptedLegalVersion: _acceptedLegalVersion);

  test('initial state is SignInIdle', () {
    expect(buildCubit().state, const SignInIdle());
  });

  blocTest<SignInCubit, SignInState>(
    'a viewer who does not follow the channel is told so',
    build: buildCubit,
    setUp: () => when(anyLogin).thenThrow(const LoginNotFollowingException()),
    act: signIn,
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.notFollowingChannel),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'openChannel opens the streamer channel and leaves the state alone',
    build: buildCubit,
    seed: () => const SignInFailed(SignInFailure.notFollowingChannel),
    act: (cubit) => cubit.openChannel(),
    expect: () => <SignInState>[],
    verify: (_) => expect(links.opened, [TwitchChannel.uri]),
  );

  blocTest<SignInCubit, SignInState>(
    'openTerms opens the public terms page (D-08)',
    build: buildCubit,
    act: (cubit) => cubit.openTerms(),
    expect: () => <SignInState>[],
    verify: (_) => expect(links.opened, [LegalDocuments.termsUri]),
  );

  blocTest<SignInCubit, SignInState>(
    'openPrivacy opens the public privacy page (D-08)',
    build: buildCubit,
    act: (cubit) => cubit.openPrivacy(),
    expect: () => <SignInState>[],
    verify: (_) => expect(links.opened, [LegalDocuments.privacyUri]),
  );

  blocTest<SignInCubit, SignInState>(
    'successful login goes back to idle',
    build: buildCubit,
    setUp: () => when(anyLogin).thenAnswer((_) async {}),
    act: signIn,
    expect: () => [const SignInInProgress(), const SignInIdle()],
  );

  blocTest<SignInCubit, SignInState>(
    'signInWithTwitch forwards the accepted version (D-19)',
    build: buildCubit,
    setUp: () => when(anyLogin).thenAnswer((_) async {}),
    act: signIn,
    verify: (_) =>
        verify(() => service.login(acceptedLegalVersion: 'v-test')).called(1),
  );

  blocTest<SignInCubit, SignInState>(
    'cancelled login is silent',
    build: buildCubit,
    setUp: () => when(anyLogin).thenThrow(const LoginCancelledException()),
    act: signIn,
    expect: () => [const SignInInProgress(), const SignInIdle()],
  );

  blocTest<SignInCubit, SignInState>(
    'unavailable login maps to twitchNotConfigured',
    build: buildCubit,
    setUp: () => when(anyLogin).thenThrow(const LoginUnavailableException()),
    act: signIn,
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.twitchNotConfigured),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'a terms refusal ends as termsNotAccepted (D-19)',
    build: buildCubit,
    setUp: () =>
        when(anyLogin).thenThrow(const LoginTermsNotAcceptedException()),
    act: signIn,
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.termsNotAccepted),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'failed login maps to connection failure',
    build: buildCubit,
    setUp: () => when(anyLogin).thenThrow(const LoginFailedException('x')),
    act: signIn,
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.connection),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'generic exception maps to connection failure',
    build: buildCubit,
    setUp: () => when(anyLogin).thenThrow(Exception('boom')),
    act: signIn,
    expect: () => [
      const SignInInProgress(),
      const SignInFailed(SignInFailure.connection),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'second tap while in progress is ignored',
    build: buildCubit,
    setUp: () => when(anyLogin).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }),
    act: (cubit) async {
      final first = signIn(cubit);
      await signIn(cubit);
      await first;
    },
    expect: () => [const SignInInProgress(), const SignInIdle()],
    verify: (_) => verify(anyLogin).called(1),
  );

  test('closing the cubit while login is in flight does not throw', () async {
    final completer = Completer<void>();
    when(anyLogin).thenAnswer((_) => completer.future);
    final cubit = buildCubit();
    final pending = signIn(cubit);
    await cubit.close();
    completer.complete();
    await expectLater(pending, completes);
  });
}
