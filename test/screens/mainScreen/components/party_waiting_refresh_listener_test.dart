import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/party_waiting_refresh_listener.dart';
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

const _arrival = '2026-10-25T09:30:00.000Z';
const _start = '2026-10-25T10:00:00.000Z';

CharacterLoaded _character({
  Map<String, dynamic>? pendingQuest,
  String locationId = 'city-marker-1',
}) => CharacterLoaded(
  Character.fromJson(
    characterWithLanesJson(locationId: locationId, pendingQuest: pendingQuest),
  ),
);

Map<String, dynamic> _travelling() => laneJson(startDate: null);

Map<String, dynamic> _waiting({int waitingTime = 60000}) => {
  ...laneJson(startDate: null, arrivedAt: _arrival),
  'waitingTime': waitingTime,
};

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
          child: PartyWaitingRefreshListener(
            cities: _cities,
            child: const SizedBox(),
          ),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, CharacterState state) async {
    states.add(state);
    await tester.pump();
  }

  testWidgets('arriving on the marker rereads the quests of the city', (
    tester,
  ) async {
    await pumpListener(
      tester,
      initial: _character(pendingQuest: _travelling()),
    );

    await emit(tester, _character(pendingQuest: _waiting()));

    verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
  });

  testWidgets('waiting off a city rereads the quests without a city', (
    tester,
  ) async {
    await pumpListener(tester, initial: _character());

    await emit(
      tester,
      _character(pendingQuest: _waiting(), locationId: 'poi-1'),
    );

    verify(() => questCubit.refreshQuests(cityId: null)).called(1);
  });

  testWidgets('a lane that keeps waiting does not reread again', (
    tester,
  ) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await emit(tester, _character(pendingQuest: _waiting(waitingTime: 1)));

    verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));
  });

  testWidgets('a party that sets off does not reread', (tester) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await emit(
      tester,
      _character(
        pendingQuest: laneJson(startDate: _start, arrivedAt: _arrival),
      ),
    );

    verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));
  });

  testWidgets('a lane still travelling does not reread', (tester) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(pendingQuest: _travelling()));

    verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));
  });
}
