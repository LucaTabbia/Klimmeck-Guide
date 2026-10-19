import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';

import '../../../helpers/auth_fixtures.dart';

void main() {
  late StreamController<AuthState> authStates;

  final questIntent = NotificationIntent(
    category: NotificationCategory.questEnd,
    id: 'q-1',
    sentAt: DateTime.utc(2026, 10, 18, 12),
  );

  AuthAuthenticated withCharacter() => AuthAuthenticated(
    user: buildTestUserWithCharacter(),
    accessToken: testAccessToken,
  );

  AuthAuthenticated withoutCharacter() =>
      AuthAuthenticated(user: buildTestUser(), accessToken: testAccessToken);

  setUp(() => authStates = StreamController<AuthState>.broadcast());

  tearDown(() => authStates.close());

  test('initial state has no pending intent', () {
    final cubit = NotificationIntentCubit(authStates.stream);
    addTearDown(cubit.close);

    expect(cubit.state, const NotificationIntentState());
    expect(cubit.state.pending, isNull);
  });

  blocTest<NotificationIntentCubit, NotificationIntentState>(
    'offer keeps the intent pending',
    build: () => NotificationIntentCubit(authStates.stream),
    act: (cubit) => cubit.offer(questIntent),
    expect: () => [NotificationIntentState(pending: questIntent)],
  );

  blocTest<NotificationIntentCubit, NotificationIntentState>(
    'consume returns the intent once and clears it',
    build: () => NotificationIntentCubit(authStates.stream),
    act: (cubit) {
      cubit.offer(questIntent);
      expect(cubit.consume(), questIntent);
      expect(cubit.consume(), isNull);
    },
    expect: () => [
      NotificationIntentState(pending: questIntent),
      const NotificationIntentState(),
    ],
  );

  blocTest<NotificationIntentCubit, NotificationIntentState>(
    'a killed-state tap survives splash and sign-in',
    build: () => NotificationIntentCubit(authStates.stream),
    act: (cubit) async {
      authStates.add(const AuthBootstrapping());
      await Future<void>.value();
      cubit.offer(questIntent);
      authStates.add(const AuthUnauthenticated());
      await Future<void>.value();
      authStates.add(withCharacter());
      await Future<void>.value();
    },
    expect: () => [NotificationIntentState(pending: questIntent)],
    verify: (cubit) => expect(cubit.state.pending, questIntent),
  );

  blocTest<NotificationIntentCubit, NotificationIntentState>(
    'the end of an authenticated session clears the pending intent',
    build: () => NotificationIntentCubit(authStates.stream),
    act: (cubit) async {
      authStates.add(withCharacter());
      await Future<void>.value();
      cubit.offer(questIntent);
      authStates.add(
        const AuthUnauthenticated(reason: UnauthenticatedReason.syncLost),
      );
      await Future<void>.value();
    },
    expect: () => [
      NotificationIntentState(pending: questIntent),
      const NotificationIntentState(),
    ],
  );

  blocTest<NotificationIntentCubit, NotificationIntentState>(
    'landing on the creation page drops the pending intent',
    build: () => NotificationIntentCubit(authStates.stream),
    act: (cubit) async {
      cubit.offer(questIntent);
      authStates.add(withoutCharacter());
      await Future<void>.value();
    },
    expect: () => [
      NotificationIntentState(pending: questIntent),
      const NotificationIntentState(),
    ],
  );

  blocTest<NotificationIntentCubit, NotificationIntentState>(
    'an offer while on the creation page is ignored',
    build: () => NotificationIntentCubit(authStates.stream),
    act: (cubit) async {
      authStates.add(withoutCharacter());
      await Future<void>.value();
      cubit.offer(questIntent);
    },
    expect: () => const <NotificationIntentState>[],
  );

  test('after close auth events are no longer observed', () async {
    final cubit = NotificationIntentCubit(authStates.stream);
    await cubit.close();

    expect(authStates.hasListener, isFalse);
  });
}
