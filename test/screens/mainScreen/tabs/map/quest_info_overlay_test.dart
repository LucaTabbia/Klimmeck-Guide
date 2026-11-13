import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/tear/tearable_paper.dart';

import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/test_app.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    String? stateLabel,
    Quest? quest,
    List<InjuryType>? characterInjuries,
  }) async {
    useLandscapePhone(tester);
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 100),
    )..value = 1;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Stack(
            children: [
              QuestInfoOverlay(
                animationController: controller,
                selectedQuest: quest ?? buildQuest(id: 'e-1', type: 'enemy'),
                stateLabel: stateLabel,
                characterInjuries: characterInjuries,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the state line when a label is given', (tester) async {
    await pumpOverlay(tester, stateLabel: 'In viaggio');

    final text = tester.widget<Text>(find.byKey(QuestInfoSheet.stateLabelKey));
    expect(text.data, 'In viaggio');
  });

  testWidgets("forwards the character's injuries to the sheet (D-19)", (
    tester,
  ) async {
    await pumpOverlay(
      tester,
      quest: buildQuest(
        id: 'h-1',
        type: 'heal',
        prizes: {'cure': questCureJson()},
      ),
      characterInjuries: const [InjuryType.contusion],
    );

    expect(find.text('Cura le tue ferite: contusione'), findsOneWidget);
  });

  testWidgets('hides the state line without a label', (tester) async {
    await pumpOverlay(tester);

    expect(find.byKey(QuestInfoSheet.stateLabelKey), findsNothing);
  });

  testWidgets('is read-only: no tearable paper and swiping does nothing', (
    tester,
  ) async {
    await pumpOverlay(tester, stateLabel: 'In viaggio');

    expect(find.byType(TearablePaper), findsNothing);
    await tester.drag(find.byType(QuestInfoSheet), const Offset(-600, 0));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(QuestInfoSheet), findsOneWidget);
    expect(find.byKey(QuestInfoSheet.stateLabelKey), findsOneWidget);
  });

  testWidgets('the map sheet prints the served block with no viewer (D-07)', (
    tester,
  ) async {
    await pumpOverlay(
      tester,
      quest: buildQuest(
        id: 'b-1',
        type: 'boss',
        slots: [
          {'title': 'paladin', 'count': 2},
        ],
        prizes: {
          'pet': {'id': 'pet-owl', 'name': 'Gufo reale'},
        },
      ),
    );

    final line = tester.widget<Text>(find.byKey(QuestInfoSheet.petPrizeKey));
    expect(line.data, 'Compagno in premio: Gufo reale');
  });
}
