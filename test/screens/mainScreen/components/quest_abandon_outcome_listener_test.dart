import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_abandon_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

void main() {
  late MockQuestAbandonCubit abandon;
  late MockInAppNotificationsCubit notices;
  late MockCharacterCubit characterCubit;
  late StreamController<QuestAbandonState> states;

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    abandon = MockQuestAbandonCubit();
    notices = MockInAppNotificationsCubit();
    characterCubit = MockCharacterCubit();
    when(() => characterCubit.refreshCharacter()).thenAnswer((_) async {});
    states = StreamController<QuestAbandonState>.broadcast();
    addTearDown(states.close);
    whenListen(abandon, states.stream, initialState: const QuestAbandonIdle());
  });

  Future<void> pumpListener(WidgetTester tester) => tester.pumpWidget(
    buildTestApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<QuestAbandonCubit>.value(value: abandon),
          BlocProvider<InAppNotificationsCubit>.value(value: notices),
          BlocProvider<CharacterCubit>.value(value: characterCubit),
        ],
        child: const QuestAbandonOutcomeListener(child: SizedBox()),
      ),
    ),
  );

  Future<void> emit(WidgetTester tester, QuestAbandonState state) async {
    states.add(state);
    await tester.pump();
  }

  testWidgets('a rejection publishes the domain notice and resets', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAbandonFailed('q-1', QuestAbandonFailure.notWaiting),
    );

    verify(
      () => notices.publishNotice(
        questAbandonNoticeFor(QuestAbandonFailure.notWaiting)!,
        dedupKey: 'quest-abandon|notWaiting|q-1',
      ),
    ).called(1);
    verify(() => abandon.reset()).called(1);
  });

  for (final failure in [
    QuestAbandonFailure.notWaiting,
    QuestAbandonFailure.notFound,
  ]) {
    testWidgets(
      '${failure.name} rereads the character to drop the stale lane',
      (tester) async {
        await pumpListener(tester);

        await emit(tester, QuestAbandonFailed('q-1', failure));

        verify(() => characterCubit.refreshCharacter()).called(1);
      },
    );
  }

  testWidgets('a connection failure does not reread the character', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAbandonFailed('q-1', QuestAbandonFailure.connection),
    );

    verifyNever(() => characterCubit.refreshCharacter());
  });

  testWidgets('unauthenticated publishes nothing but still resets', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAbandonFailed('q-1', QuestAbandonFailure.unauthenticated),
    );

    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
    verify(() => abandon.reset()).called(1);
  });

  testWidgets('success only resets', (tester) async {
    await pumpListener(tester);

    await emit(tester, const QuestAbandoned('q-1'));

    verify(() => abandon.reset()).called(1);
    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
  });

  testWidgets('an abandon in flight does nothing', (tester) async {
    await pumpListener(tester);

    await emit(tester, const QuestAbandoning('q-1'));

    verifyNever(() => abandon.reset());
  });
}
