import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/prison_status_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

CharacterLoaded _character({String? imprisonedUntil, String? locationId}) =>
    CharacterLoaded(
      Character.fromJson(
        travellingCharacterJson(
          imprisonedUntil: imprisonedUntil,
          locationId: locationId ?? 'city-marker-1',
        ),
      ),
    );

void main() {
  late MockCharacterCubit characterCubit;
  late MockPrisonCubit prison;
  late StreamController<CharacterState> characterStates;

  const releaseWire = '2026-11-10T22:00:00.000Z';
  final release = DateTime.utc(2026, 11, 10, 22);

  setUp(() {
    characterCubit = MockCharacterCubit();
    prison = MockPrisonCubit();
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(characterStates.close);
    whenListen(
      prison,
      const Stream<PrisonState>.empty(),
      initialState: const PrisonState(null),
    );
  });

  Future<void> pumpListener(WidgetTester tester, CharacterState initial) async {
    whenListen(characterCubit, characterStates.stream, initialState: initial);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<PrisonCubit>.value(value: prison),
          ],
          child: const PrisonStatusListener(child: SizedBox()),
        ),
      ),
    );
  }

  Future<void> emitCharacter(WidgetTester tester, CharacterState state) async {
    when(() => characterCubit.state).thenReturn(state);
    characterStates.add(state);
    await tester.pump();
  }

  testWidgets('feeds the release of the loaded character on mount '
      '(quick 261110-cgd)', (tester) async {
    await pumpListener(tester, _character(imprisonedUntil: releaseWire));

    verify(() => prison.followStatus(release)).called(1);
  });

  testWidgets('feeds a new release from characterUpdated '
      '(quick 261110-cgd)', (tester) async {
    await pumpListener(tester, _character());
    verify(() => prison.followStatus(null)).called(1);

    await emitCharacter(tester, _character(imprisonedUntil: releaseWire));

    verify(() => prison.followStatus(release)).called(1);
  });

  testWidgets('an update that keeps the release feeds nothing more '
      '(quick 261110-cgd)', (tester) async {
    await pumpListener(tester, _character(imprisonedUntil: releaseWire));
    verify(() => prison.followStatus(release)).called(1);

    await emitCharacter(
      tester,
      _character(imprisonedUntil: releaseWire, locationId: 'city-marker-2'),
    );

    verifyNever(() => prison.followStatus(any()));
  });
}
