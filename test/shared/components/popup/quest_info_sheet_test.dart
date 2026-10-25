import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_viewer.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const _enemy = {
  'id': 'e-1',
  'name': 'Arbusto maligno',
  'imagePath': 'assets/images/arbustoMaligno.png',
};

Future<void> _pump(
  WidgetTester tester,
  Quest? quest, {
  QuestViewer? viewer,
  String? stateLabel,
  VoidCallback? onAbandon,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuestInfoSheet(
            quest: quest,
            viewer: viewer,
            stateLabel: stateLabel,
            onAbandon: onAbandon,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Color? _colorOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style?.color;

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.emptySheet]));

  group('families', () {
    const expected = {
      'hunt': 'combat',
      'enemy': 'combat',
      'boss': 'combat',
      'dungeon': 'combat',
      'story': 'narrative',
      'worldMission': 'narrative',
      'heal': 'service',
      'aid': 'service',
      'job': 'service',
      'study': 'service',
      'crime': 'service',
      'guard': 'service',
    };
    final keys = {
      'combat': QuestInfoSheet.combatFamilyKey,
      'narrative': QuestInfoSheet.narrativeFamilyKey,
      'service': QuestInfoSheet.serviceFamilyKey,
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key} renders the ${entry.value} family', (
        tester,
      ) async {
        await _pump(tester, buildQuest(type: entry.key, requiredPoints: 3000));

        expect(tester.takeException(), isNull);
        expect(find.byKey(keys[entry.value]!), findsOneWidget);
        for (final other in keys.entries.where((k) => k.key != entry.value)) {
          expect(find.byKey(other.value), findsNothing);
        }
      });
    }
  });

  group('combat', () {
    testWidgets('shows the enemy image, name and required time', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'enemy', enemy: _enemy));

      expect(find.text('Arbusto maligno'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('Tempo richiesto: '), findsOneWidget);
    });

    testWidgets('renders without enemy and without image', (tester) async {
      await _pump(tester, buildQuest(type: 'enemy'));

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('narrative', () {
    final lore = [
      {'id': 'l-1', 'name': 'Il patto', 'description': 'Molto tempo fa…'},
    ];

    testWidgets('shows lore and a blood red insufficient balance', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(type: 'story', requiredPoints: 3000, lore: lore),
        viewer: buildViewer(twitchPoints: 1200),
      );

      expect(find.text('Molto tempo fa…'), findsOneWidget);
      final cost = find.text('Punti canale: 1200 / 3000');
      expect(cost, findsOneWidget);
      expect(_colorOf(tester, cost), KlimmeckGuideTheme.bloodRed);
    });

    testWidgets('a sufficient balance is not blood red', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'story', requiredPoints: 3000, lore: lore),
        viewer: buildViewer(twitchPoints: 5000),
      );

      final cost = find.text('Punti canale: 5000 / 3000');
      expect(cost, findsOneWidget);
      expect(_colorOf(tester, cost), isNot(KlimmeckGuideTheme.bloodRed));
    });

    testWidgets('renders without lore', (tester) async {
      await _pump(tester, buildQuest(type: 'story', requiredPoints: 3000));

      expect(tester.takeException(), isNull);
      expect(find.byKey(QuestInfoSheet.narrativeFamilyKey), findsOneWidget);
    });

    testWidgets('shows slots per rank for a world mission', (tester) async {
      await _pump(
        tester,
        buildQuest(
          type: 'worldMission',
          requiredPoints: 3000,
          slots: [
            {'title': 'hero', 'count': 5},
            {'title': 'paladin', 'count': 4},
          ],
        ),
      );

      expect(find.text('Eroe: 0 / 5'), findsOneWidget);
      expect(find.text('Paladino: 0 / 4'), findsOneWidget);
    });
  });

  group('cost and title', () {
    testWidgets('an enemy never shows the cost line', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'enemy', requiredPoints: 3000),
        viewer: buildViewer(),
      );

      expect(find.textContaining('Punti canale'), findsNothing);
    });

    testWidgets('an ineligible required title is blood red', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'story', minTitle: 'paladin', requiredPoints: 3000),
        viewer: buildViewer(title: TitleType.mage),
      );

      final title = find.text('Titolo richiesto: Paladino');
      expect(title, findsOneWidget);
      expect(_colorOf(tester, title), KlimmeckGuideTheme.bloodRed);
    });
  });

  group('service', () {
    testWidgets('shows the recommended loot', (tester) async {
      await _pump(
        tester,
        buildQuest(
          type: 'heal',
          recommendedLoot: [
            {
              'quantity': 2,
              'item': {'id': 'l-1', 'name': 'Pozione', 'description': 'd'},
            },
          ],
        ),
      );

      expect(find.text('Consigliati'), findsOneWidget);
      expect(find.text('2x Pozione'), findsOneWidget);
    });

    testWidgets('renders without recommended loot', (tester) async {
      await _pump(tester, buildQuest(type: 'heal'));

      expect(tester.takeException(), isNull);
      expect(find.text('Consigliati'), findsNothing);
    });
  });

  group('blocked reason and state label', () {
    testWidgets('a busy lane is explained', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'hunt'),
        viewer: buildViewer(
          quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
        ),
      );

      final reason = find.byKey(QuestInfoSheet.blockedReasonKey);
      expect(reason, findsOneWidget);
      expect(
        tester.widget<Text>(reason).data,
        'Hai già una missione di questo tipo in corso',
      );
    });

    testWidgets('shows the state label only when given', (tester) async {
      await _pump(tester, buildQuest(type: 'hunt'), stateLabel: 'In viaggio');
      expect(
        tester.widget<Text>(find.byKey(QuestInfoSheet.stateLabelKey)).data,
        'In viaggio',
      );

      await _pump(tester, buildQuest(type: 'hunt'));
      expect(find.byKey(QuestInfoSheet.stateLabelKey), findsNothing);
    });

    testWidgets('offers no abandon action without a callback', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'boss'),
        stateLabel: 'In attesa del gruppo 1/3',
      );

      expect(find.byKey(QuestInfoSheet.abandonKey), findsNothing);
    });

    testWidgets('the abandon action calls back once', (tester) async {
      var abandons = 0;
      await _pump(
        tester,
        buildQuest(type: 'boss'),
        stateLabel: 'In attesa del gruppo 1/3',
        onAbandon: () => abandons++,
      );

      final action = find.byKey(QuestInfoSheet.abandonKey);
      expect(
        find.descendant(of: action, matching: find.text('Abbandona il gruppo')),
        findsOneWidget,
      );
      await tester.ensureVisible(action);
      await tester.tap(action);

      expect(abandons, 1);
    });
  });

  testWidgets('has no horizontal drag gesture of its own', (tester) async {
    await _pump(tester, buildQuest(type: 'enemy', enemy: _enemy));

    final detectors = tester.widgetList<GestureDetector>(
      find.descendant(
        of: find.byType(QuestInfoSheet),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(detectors.where((d) => d.onHorizontalDragUpdate != null), isEmpty);
  });

  testWidgets('a null quest renders only the parchment', (tester) async {
    await _pump(tester, null);

    expect(tester.takeException(), isNull);
    expect(find.byKey(QuestInfoSheet.combatFamilyKey), findsNothing);
  });
}
