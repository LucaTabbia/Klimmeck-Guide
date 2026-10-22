import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_acceptance_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

final _cities = [
  City.fromJson({
    'id': 'city-1',
    'markerLocation': {
      'id': 'city-marker-1',
      'location': [1.0, 2.0],
    },
  }),
];

void main() {
  late MockQuestAcceptanceCubit acceptance;
  late MockInAppNotificationsCubit notices;
  late MockQuestCubit questCubit;
  late MockCharacterCubit characterCubit;
  late StreamController<QuestAcceptanceState> states;

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    acceptance = MockQuestAcceptanceCubit();
    notices = MockInAppNotificationsCubit();
    questCubit = MockQuestCubit();
    characterCubit = MockCharacterCubit();
    states = StreamController<QuestAcceptanceState>.broadcast();
    addTearDown(states.close);
    when(
      () => questCubit.refreshQuests(cityId: any(named: 'cityId')),
    ).thenAnswer((_) async {});
    whenListen(
      acceptance,
      states.stream,
      initialState: const QuestAcceptanceIdle(),
    );
    whenListen(
      questCubit,
      const Stream<QuestState>.empty(),
      initialState: QuestLoaded([
        buildQuest(id: 'h-1', type: 'hunt'),
        buildQuest(id: 's-1', type: 'story'),
      ]),
    );
  });

  Future<void> pumpListener(
    WidgetTester tester, {
    String locationId = 'city-marker-1',
  }) async {
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        Character.fromJson(characterWithLanesJson(locationId: locationId)),
      ),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<QuestAcceptanceCubit>.value(value: acceptance),
            BlocProvider<InAppNotificationsCubit>.value(value: notices),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<CharacterCubit>.value(value: characterCubit),
          ],
          child: QuestAcceptanceOutcomeListener(
            cities: _cities,
            child: const SizedBox(),
          ),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, QuestAcceptanceState state) async {
    states.add(state);
    await tester.pump();
  }

  KGNotification notice(String description) =>
      KGNotification(title: 'Missione non accettata', description: description);

  testWidgets('rejection after leaving the Board still publishes the banner', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAcceptanceFailed('h-1', QuestAcceptanceFailure.full),
    );

    verify(
      () => notices.publishNotice(
        notice('Non ci sono più posti per il tuo rango'),
        dedupKey: 'quest-acceptance|full|h-1',
      ),
    ).called(1);
    verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
    verify(() => acceptance.reset()).called(1);
  });

  testWidgets('the slot-busy copy follows the quest type and never refreshes', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAcceptanceFailed('s-1', QuestAcceptanceFailure.slotBusy),
    );

    verify(
      () => notices.publishNotice(
        notice('Hai già una storia in corso'),
        dedupKey: 'quest-acceptance|slotBusy|s-1',
      ),
    ).called(1);
    verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));
  });

  for (final failure in [
    QuestAcceptanceFailure.alreadyTaken,
    QuestAcceptanceFailure.notFound,
    // Il BE può aver accettato la quest dopo la scadenza client (WR-01).
    QuestAcceptanceFailure.timedOut,
  ]) {
    testWidgets('${failure.name} refreshes the stale list', (tester) async {
      await pumpListener(tester);

      await emit(tester, QuestAcceptanceFailed('h-1', failure));

      verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
    });
  }

  testWidgets('insufficient points do not refresh the list', (tester) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAcceptanceFailed(
        'h-1',
        QuestAcceptanceFailure.insufficientPoints,
      ),
    );

    verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));
  });

  testWidgets('unauthenticated publishes nothing but still resets', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(
      tester,
      const QuestAcceptanceFailed(
        'h-1',
        QuestAcceptanceFailure.unauthenticated,
      ),
    );

    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
    verify(() => acceptance.reset()).called(1);
  });

  testWidgets('success only resets', (tester) async {
    await pumpListener(tester);

    await emit(tester, const QuestAccepted('h-1'));

    verify(() => acceptance.reset()).called(1);
    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
  });

  testWidgets('an acceptance in flight does nothing', (tester) async {
    await pumpListener(tester);

    await emit(tester, const QuestAccepting('h-1'));

    verifyNever(() => acceptance.reset());
    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
  });

  testWidgets('off a city marker the refresh has no city', (tester) async {
    await pumpListener(tester, locationId: 'poi-1');

    await emit(
      tester,
      const QuestAcceptanceFailed('h-1', QuestAcceptanceFailure.full),
    );

    verify(() => questCubit.refreshQuests(cityId: null)).called(1);
  });
}
