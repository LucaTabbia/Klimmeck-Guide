import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/place_step.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';
const String _ruins = 'poi-ruins-1';

final MissionDraft _draft = MissionDraft.tryFromJson(
  missionDraftJson(
    participants: [
      missionParticipantJson(),
      missionParticipantJson(
        character: _bea,
        name: 'Bea',
        pendingQuest: 'pq-world-2',
      ),
    ],
  ),
)!;

final PointOfInterest _ruinsPlace = PointOfInterest.fromJson(
  pointOfInterestJson(),
);

MissionParticipantsLoaded _loaded({String beaLocation = _ruins}) =>
    MissionParticipantsLoaded(
      characters: {
        _aldo: Character.fromJson(participantCharacterJson(locationId: _ruins)),
        _bea: Character.fromJson(
          participantCharacterJson(
            id: _bea,
            name: 'Bea',
            locationId: beaLocation,
          ),
        ),
      },
      places: {_ruins: _ruinsPlace},
    );

void main() {
  late int teleports;
  late List<String> stays;
  late int retries;

  setUp(() {
    teleports = 0;
    stays = [];
    retries = 0;
  });

  Future<void> pumpStep(
    WidgetTester tester,
    MissionParticipantsState participants, {
    bool isSubmitting = false,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: PlaceStep(
            draft: _draft,
            participants: participants,
            isSubmitting: isSubmitting,
            onTeleport: () => teleports++,
            onStay: stays.add,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
  }

  VoidCallback? onPressedOf(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed;

  testWidgets('each participant shows the name of its place (D-29)', (
    tester,
  ) async {
    await pumpStep(tester, _loaded());

    expect(find.text('Aldo · Rovine presso Talmvere'), findsOneWidget);
    expect(find.text('Bea · Rovine presso Talmvere'), findsOneWidget);
  });

  testWidgets(
    '«Teletrasporta il gruppo» prepares the teleport with the card key (D-01, D-28)',
    (tester) async {
      await pumpStep(tester, _loaded());

      await tester.tap(find.byKey(PlaceStep.teleportKey));

      expect(teleports, 1);
      expect(find.text(PlaceStep.teleportLabel), findsOneWidget);
    },
  );

  testWidgets(
    '«Resta qui» is enabled only when the group shares one place (D-01)',
    (tester) async {
      await pumpStep(tester, _loaded(beaLocation: 'poi-valantar-marker'));

      expect(onPressedOf(tester, PlaceStep.stayKey), isNull);
      expect(onPressedOf(tester, PlaceStep.teleportKey), isNotNull);
    },
  );

  testWidgets('«Resta qui» hands over the shared place (D-01, D-18)', (
    tester,
  ) async {
    await pumpStep(tester, _loaded());

    await tester.tap(find.byKey(PlaceStep.stayKey));

    expect(stays, [_ruins]);
    expect(find.text(PlaceStep.stayLabel), findsOneWidget);
  });

  testWidgets(
    'while the participants load the city teleport stays enabled and «Resta qui» waits (D-31)',
    (tester) async {
      await pumpStep(tester, const MissionParticipantsLoading());

      expect(onPressedOf(tester, PlaceStep.teleportKey), isNotNull);
      expect(onPressedOf(tester, PlaceStep.stayKey), isNull);
      expect(find.text('Aldo'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed participants read keeps the city teleport and offers «Riprova» (D-31)',
    (tester) async {
      await pumpStep(
        tester,
        const MissionParticipantsFailed(failure: InnkeeperFailure.connection),
      );

      expect(onPressedOf(tester, PlaceStep.teleportKey), isNotNull);
      expect(onPressedOf(tester, PlaceStep.stayKey), isNull);
      expect(
        find.text(MissionCompletionScreen.connectionMessage),
        findsOneWidget,
      );

      await tester.tap(find.byKey(PlaceStep.retryKey));

      expect(retries, 1);
      expect(find.text(MissionCompletionScreen.retryLabel), findsOneWidget);
    },
  );

  testWidgets('while a call is in flight the buttons are disabled', (
    tester,
  ) async {
    await pumpStep(tester, _loaded(), isSubmitting: true);

    expect(onPressedOf(tester, PlaceStep.teleportKey), isNull);
    expect(onPressedOf(tester, PlaceStep.stayKey), isNull);
  });
}
