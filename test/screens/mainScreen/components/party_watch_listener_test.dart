import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/party_watch_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

const _arrival = '2026-10-25T09:30:00.000Z';
const _start = '2026-10-25T10:00:00.000Z';

CharacterLoaded _character({Map<String, dynamic>? pendingQuest}) =>
    CharacterLoaded(
      Character.fromJson(characterWithLanesJson(pendingQuest: pendingQuest)),
    );

Map<String, dynamic> _travelling() => laneJson(startDate: null);

Map<String, dynamic> _waiting({String questId = 'q-1', int waitingTime = 1}) =>
    {
      ...laneJson(startDate: null, arrivedAt: _arrival, questId: questId),
      'waitingTime': waitingTime,
    };

Map<String, dynamic> _started() =>
    laneJson(startDate: _start, arrivedAt: _arrival);

void main() {
  late MockCharacterCubit characterCubit;
  late MockQuestCubit questCubit;
  late StreamController<CharacterState> states;

  setUp(() {
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
    states = StreamController<CharacterState>.broadcast();
    addTearDown(states.close);
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
          child: const PartyWatchListener(child: SizedBox()),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, CharacterState state) async {
    states.add(state);
    await tester.pump();
  }

  testWidgets('arriving on the marker watches the awaited quest', (
    tester,
  ) async {
    await pumpListener(
      tester,
      initial: _character(pendingQuest: _travelling()),
    );

    await emit(tester, _character(pendingQuest: _waiting()));

    verify(() => questCubit.watchQuest('q-1')).called(1);
    verifyNever(() => questCubit.unwatchQuest());
  });

  testWidgets('a lane already waiting on mount is watched', (tester) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    verify(() => questCubit.watchQuest('q-1')).called(1);
  });

  testWidgets('a lane that keeps waiting is not watched again', (tester) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await emit(tester, _character(pendingQuest: _waiting(waitingTime: 2)));

    verify(() => questCubit.watchQuest('q-1')).called(1);
    verifyNever(() => questCubit.unwatchQuest());
  });

  testWidgets('a party that sets off stops the watch', (tester) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await emit(tester, _character(pendingQuest: _started()));

    verify(() => questCubit.unwatchQuest()).called(1);
  });

  testWidgets('an emptied lane stops the watch', (tester) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await emit(tester, _character());

    verify(() => questCubit.unwatchQuest()).called(1);
  });

  testWidgets('a lane waiting for another quest watches that one', (
    tester,
  ) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await emit(tester, _character(pendingQuest: _waiting(questId: 'q-2')));

    verify(() => questCubit.watchQuest('q-2')).called(1);
  });

  testWidgets('a lane still travelling watches nothing', (tester) async {
    await pumpListener(tester, initial: _character());

    await emit(tester, _character(pendingQuest: _travelling()));

    verifyNever(() => questCubit.watchQuest(any()));
    verifyNever(() => questCubit.unwatchQuest());
  });

  testWidgets('leaving the screen stops the watch', (tester) async {
    await pumpListener(tester, initial: _character(pendingQuest: _waiting()));

    await tester.pumpWidget(const SizedBox());

    verify(() => questCubit.unwatchQuest()).called(1);
  });

  testWidgets('never rereads the quest list', (tester) async {
    await pumpListener(
      tester,
      initial: _character(pendingQuest: _travelling()),
    );

    await emit(tester, _character(pendingQuest: _waiting()));
    await emit(tester, _character(pendingQuest: _started()));

    verifyNever(() => questCubit.refreshQuests(cityId: any(named: 'cityId')));
  });
}
