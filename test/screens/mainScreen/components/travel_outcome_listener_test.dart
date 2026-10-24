import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/travel_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

void main() {
  late MockTravelCubit travel;
  late MockCharacterCubit characterCubit;
  late MockInAppNotificationsCubit notices;
  late StreamController<TravelState> travelStates;
  late StreamController<CharacterState> characterStates;

  final valdoria = City.fromJson(travelCityJson());
  final started = TravelStarted(
    destination: valdoria,
    preview: TravelPreview.fromJson(travelPreviewJson()),
  );
  final resting = CharacterLoaded(
    Character.fromJson(travellingCharacterJson()),
  );
  final travelling = CharacterLoaded(
    Character.fromJson(
      travellingCharacterJson(activeTravel: activeTravelJson()),
    ),
  );

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    travel = MockTravelCubit();
    characterCubit = MockCharacterCubit();
    notices = MockInAppNotificationsCubit();
    travelStates = StreamController<TravelState>.broadcast();
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(travelStates.close);
    addTearDown(characterStates.close);
    whenListen(travel, travelStates.stream, initialState: const TravelIdle());
  });

  Future<void> pumpListener(
    WidgetTester tester, {
    required CharacterState character,
  }) async {
    whenListen(characterCubit, characterStates.stream, initialState: character);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TravelCubit>.value(value: travel),
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<InAppNotificationsCubit>.value(value: notices),
          ],
          child: const TravelOutcomeListener(child: SizedBox()),
        ),
      ),
    );
  }

  Future<void> emitTravel(WidgetTester tester, TravelState state) async {
    when(() => travel.state).thenReturn(state);
    travelStates.add(state);
    await tester.pump();
  }

  Future<void> emitCharacter(WidgetTester tester, CharacterState state) async {
    when(() => characterCubit.state).thenReturn(state);
    characterStates.add(state);
    await tester.pump();
  }

  void verifyNoNotice() => verifyNever(
    () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
  );

  testWidgets('a rejection publishes the catalogue banner once and resets', (
    tester,
  ) async {
    await pumpListener(tester, character: resting);

    await emitTravel(
      tester,
      TravelFailed(
        destination: valdoria,
        failure: TravelFailure.noPath,
        stage: TravelStage.preview,
      ),
    );

    verify(
      () => notices.publishNotice(
        const KGNotification(
          title: 'Viaggio non partito',
          description: 'Nessuna strada porta a questa meta',
        ),
        dedupKey: 'travel|noPath|city-2',
      ),
    ).called(1);
    verify(() => travel.reset()).called(1);
  });

  testWidgets('an unauthenticated rejection shows nothing but resets', (
    tester,
  ) async {
    await pumpListener(tester, character: resting);

    await emitTravel(
      tester,
      TravelFailed(
        destination: valdoria,
        failure: TravelFailure.unauthenticated,
        stage: TravelStage.start,
      ),
    );

    verifyNoNotice();
    verify(() => travel.reset()).called(1);
  });

  testWidgets('a started travel settles when activeTravel arrives', (
    tester,
  ) async {
    await pumpListener(tester, character: resting);

    await emitTravel(tester, started);
    verifyNever(() => travel.reset());

    await emitCharacter(tester, travelling);

    verify(() => travel.reset()).called(1);
    verifyNoNotice();
  });

  testWidgets('a start answered after activeTravel settles at once', (
    tester,
  ) async {
    await pumpListener(tester, character: travelling);

    await emitTravel(tester, started);

    verify(() => travel.reset()).called(1);
  });

  testWidgets('a travel showing up while idle does not reset the flow', (
    tester,
  ) async {
    await pumpListener(tester, character: resting);

    await emitCharacter(tester, travelling);

    verifyNever(() => travel.reset());
  });
}
