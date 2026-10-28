import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/quest/quest_paper_asset.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_markers_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';

import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';
import 'world_map_travel_test.dart' hide main;

/// Phase 9 D-07/D-23: la mappa dice alla coda dei risultati quando un foglio
/// quest o un trascinamento della pedina la occupano.
void main() {
  setUpWorldMapHarness();

  final enemy = buildQuest(id: 'e-1', type: 'enemy');

  Future<void> pumpMapWithLane(WidgetTester tester) async {
    seedSvgCache([
      questPaperAssetId(enemy, isTorn: false),
      CloudinaryAssets.emptySheet,
    ]);
    await pumpWorldMap(
      tester,
      character: characterLoaded(
        pendingQuest: laneJson(
          questId: 'e-1',
          arrivedAt: '2026-10-25T09:30:00.000Z',
        ),
      ),
      quests: [enemy],
    );
  }

  Future<void> closeQuestSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();
    expect(find.byType(QuestInfoSheet), findsNothing);
  }

  Future<TestGesture> startPawnDrag(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Draggable)),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    return gesture;
  }

  group('quest sheet', () {
    testWidgets('the paper of a lane marks the map busy until it closes', (
      tester,
    ) async {
      await pumpMapWithLane(tester);

      await tester.tap(find.byKey(QuestPaperLayer.paperKey));
      await tester.pumpAndSettle();
      expect(find.byType(QuestInfoSheet), findsOneWidget);
      expect(mapAvailability.state.isQuestSheetOpen, isTrue);

      await closeQuestSheet(tester);
      expect(mapAvailability.state.isQuestSheetOpen, isFalse);
    });

    testWidgets('a quest marker marks the map busy until it closes', (
      tester,
    ) async {
      await pumpMapWithLane(tester);

      tester
          .widget<QuestMarkersLayer>(find.byType(QuestMarkersLayer))
          .onQuestSelected(enemy);
      await tester.pumpAndSettle();
      expect(find.byType(QuestInfoSheet), findsOneWidget);
      expect(mapAvailability.state.isQuestSheetOpen, isTrue);

      await closeQuestSheet(tester);
      expect(mapAvailability.state.isQuestSheetOpen, isFalse);
    });
  });

  group('pawn drag', () {
    testWidgets('dragging the pawn marks the map busy until release', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());

      final gesture = await startPawnDrag(tester);
      expect(mapAvailability.state.isPawnDragging, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(mapAvailability.state.isPawnDragging, isFalse);
    });

    testWidgets('a release that opens the travel sheet ends the drag', (
      tester,
    ) async {
      previewKeepsTheSheetOpen();
      await pumpWorldMap(tester, character: characterLoaded());

      await dragPawnBy(tester, const Offset(300, 0));

      expect(find.byType(TravelConfirmationSheet), findsOneWidget);
      expect(mapAvailability.state.isPawnDragging, isFalse);
    });
  });

  group('pawn drag source removed (09-REVIEW IN-02)', () {
    testWidgets('a travel that replaces the dragged pawn ends the drag', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());
      final gesture = await startPawnDrag(tester);
      expect(mapAvailability.state.isPawnDragging, isTrue);

      characterStates.add(characterLoaded(activeTravel: activeTravelJson()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(Draggable), findsNothing);
      expect(mapAvailability.state.isPawnDragging, isFalse);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(mapAvailability.state.isPawnDragging, isFalse);
    });

    testWidgets('an awaited aid keeps the pawn and ends the drag on release', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());
      final gesture = await startPawnDrag(tester);

      characterStates.add(
        CharacterLoaded(
          Character.fromJson(
            travellingCharacterJson(
              locationId: 'city-marker-1',
              awaitingAid: awaitingAidJson(),
            ),
          ),
        ),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(mapAvailability.state.isPawnDragging, isFalse);
    });
  });

  group('unmount (T-9-14)', () {
    testWidgets('a removed map leaves no quest sheet flag behind', (
      tester,
    ) async {
      await pumpMapWithLane(tester);
      await tester.tap(find.byKey(QuestPaperLayer.paperKey));
      await tester.pumpAndSettle();
      expect(mapAvailability.state.isQuestSheetOpen, isTrue);

      await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

      expect(mapAvailability.state.isQuestSheetOpen, isFalse);
      expect(mapAvailability.state.isPawnDragging, isFalse);
    });

    testWidgets('a map removed mid-drag leaves no drag flag behind', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());
      final gesture = await startPawnDrag(tester);
      expect(mapAvailability.state.isPawnDragging, isTrue);

      await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

      expect(mapAvailability.state.isPawnDragging, isFalse);
      await gesture.up();
    });
  });
}
