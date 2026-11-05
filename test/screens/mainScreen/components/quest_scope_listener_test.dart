import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_scope_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

const _arrival = '2026-11-05T09:30:00.000Z';

final _cities = [
  City.fromJson({
    'id': 'city-1',
    'markerLocation': {
      'id': 'city-marker-1',
      'location': [1.0, 2.0],
    },
  }),
  City.fromJson({
    'id': 'city-2',
    'markerLocation': {
      'id': 'city-marker-2',
      'location': [3.0, 4.0],
    },
  }),
];

CharacterLoaded _character({
  String locationId = 'city-marker-1',
  String title = 'rookie',
  Map<String, dynamic>? pendingQuest,
  Map<String, dynamic>? activeStoryQuest,
  List<String> completedQuestIds = const [],
}) => CharacterLoaded(
  Character.fromJson(
    characterWithLanesJson(
      locationId: locationId,
      title: title,
      pendingQuest: pendingQuest,
      activeStoryQuest: activeStoryQuest,
      completedQuestIds: completedQuestIds,
    ),
  ),
);

void main() {
  late MockCharacterCubit characterCubit;
  late MockQuestCubit questCubit;
  late StreamController<CharacterState> states;

  setUp(() {
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
    states = StreamController<CharacterState>.broadcast();
    addTearDown(states.close);
    when(
      () => questCubit.refreshQuests(cityId: any(named: 'cityId')),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpListener(
    WidgetTester tester, {
    required CharacterState initial,
  }) async {
    whenListen(characterCubit, states.stream, initialState: initial);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<QuestCubit>.value(value: questCubit),
          ],
          child: QuestScopeListener(cities: _cities, child: const SizedBox()),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, CharacterState state) async {
    states.add(state);
    await tester.pump();
  }

  void verifyNoReread() =>
      verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));

  testWidgets('mounting does not reread the quests', (tester) async {
    await pumpListener(tester, initial: _character());

    verifyNoReread();
  });

  testWidgets('arriving in another city rereads the quests of that city', (
    tester,
  ) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(locationId: 'city-marker-2'));

    verify(() => questCubit.refreshQuests(cityId: 'city-2')).called(1);
  });

  testWidgets('leaving the city rereads the quests without a city', (
    tester,
  ) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(locationId: 'road-1'));

    verify(() => questCubit.refreshQuests(cityId: null)).called(1);
  });

  testWidgets('a new title rereads the quests', (tester) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(title: 'adventurer'));

    verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
  });

  testWidgets('a lane that fills or empties rereads the quests', (
    tester,
  ) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(pendingQuest: laneJson(questId: 'q-1')));
    await emit(tester, _character());

    verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(2);
  });

  testWidgets('a story lane that moves to another quest rereads the quests', (
    tester,
  ) async {
    await pumpListener(
      tester,
      initial: _character(activeStoryQuest: laneJson(questId: 's-1')),
    );

    await emit(tester, _character(activeStoryQuest: laneJson(questId: 's-2')));

    verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
  });

  testWidgets('a lane that keeps its quest does not reread', (tester) async {
    await pumpListener(
      tester,
      initial: _character(pendingQuest: laneJson(startDate: null)),
    );

    await emit(
      tester,
      _character(pendingQuest: laneJson(startDate: null, arrivedAt: _arrival)),
    );

    verifyNoReread();
  });

  testWidgets('an unrelated change does not reread', (tester) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(completedQuestIds: const ['q-9']));

    verifyNoReread();
  });

  testWidgets('a character that is not loaded does not reread', (tester) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, const CharacterUnavailable());

    verifyNoReread();
  });
}
