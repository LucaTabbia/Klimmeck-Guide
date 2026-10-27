import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_sheet_details.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

Map<String, dynamic> slot(String? title, int count) => {
  'title': title,
  'count': count,
};

Map<String, dynamic> reg(String id, String? title) => {
  'character': id,
  'title': title,
};

void main() {
  group('questSheetFamilyOf', () {
    test('maps every quest type to its family (aid is combat, D-17)', () {
      for (final type in [
        QuestType.hunt,
        QuestType.enemy,
        QuestType.boss,
        QuestType.dungeon,
        QuestType.aid,
      ]) {
        expect(questSheetFamilyOf(type), QuestSheetFamily.combat);
      }
      for (final type in [QuestType.story, QuestType.worldMission]) {
        expect(questSheetFamilyOf(type), QuestSheetFamily.narrative);
      }
      for (final type in [
        QuestType.heal,
        QuestType.job,
        QuestType.study,
        QuestType.crime,
        QuestType.guard,
        null,
      ]) {
        expect(questSheetFamilyOf(type), QuestSheetFamily.service);
      }
    });
  });

  group('required title', () {
    test('story shows the exact title and flags a mismatch', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'story', minTitle: 'paladin', requiredPoints: 3000),
        viewer: buildViewer(title: TitleType.mage),
      );
      expect(details.requiredTitleText, 'Titolo richiesto: Paladino');
      expect(details.isTitleIneligible, isTrue);
    });

    test('other types show the minimum title', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'boss', minTitle: 'hero'),
        viewer: buildViewer(title: TitleType.legend),
      );
      expect(details.requiredTitleText, 'Titolo minimo: Eroe');
      expect(details.isTitleIneligible, isFalse);
    });

    test('no minTitle means no line', () {
      final details = QuestSheetDetails.of(buildQuest(minTitle: null));
      expect(details.requiredTitleText, isNull);
    });

    test('without a viewer nobody is ineligible', () {
      final details = QuestSheetDetails.of(buildQuest(minTitle: 'legend'));
      expect(details.isTitleIneligible, isFalse);
    });
  });

  group('slot lines', () {
    test('count registered per rank and mark the viewer rank', () {
      final details = QuestSheetDetails.of(
        buildQuest(
          type: 'worldMission',
          requiredPoints: 3000,
          slots: [slot('hero', 5), slot('paladin', 4)],
          registered: [
            reg('a', 'hero'),
            reg('b', 'paladin'),
            reg('c', 'paladin'),
          ],
        ),
        viewer: buildViewer(title: TitleType.paladin),
      );
      expect(details.slotLines.map((l) => l.text), [
        'Eroe: 1 / 5',
        'Paladino: 2 / 4',
      ]);
      expect(details.slotLines.map((l) => l.isViewerRank), [false, true]);
    });

    test('overflow of exact slots fills the any-rank line (D-32)', () {
      final details = QuestSheetDetails.of(
        buildQuest(
          type: 'boss',
          slots: [slot('hero', 1), slot(null, 2)],
          registered: [reg('a', 'paladin'), reg('b', 'mage')],
        ),
      );
      expect(details.slotLines.map((l) => l.text), [
        'Eroe: 0 / 1',
        'Qualsiasi rango: 2 / 2',
      ]);
    });

    test('legacy slots become a single any-rank line', () {
      final details = QuestSheetDetails.of(
        Quest.fromJson(legacyQuestJson(registered: ['c-1'])),
      );
      expect(details.slotLines.map((l) => l.text), ['Qualsiasi rango: 1 / 1']);
    });

    test('hunt has no slot lines', () {
      final details = QuestSheetDetails.of(buildQuest(type: 'hunt'));
      expect(details.slotLines, isEmpty);
    });
  });

  group('cost line', () {
    test('story shows it with the live balance', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'story', requiredPoints: 3000),
        viewer: buildViewer(twitchPoints: 1200),
      );
      expect(details.costLine?.text, 'Punti canale: 1200 / 3000');
      expect(details.costLine?.isInsufficient, isTrue);
    });

    test('enemy never shows it', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'enemy', requiredPoints: 3000),
      );
      expect(details.costLine, isNull);
    });
  });

  group('blocked reason', () {
    test('null without a viewer', () {
      expect(QuestSheetDetails.of(buildQuest()).blockedReason, isNull);
    });

    test('busy lane is explained', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'hunt'),
        viewer: buildViewer(
          quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
        ),
      );
      expect(
        details.blockedReason,
        'Hai già una missione di questo tipo in corso',
      );
    });

    test('null when available', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'hunt'),
        viewer: buildViewer(),
      );
      expect(details.blockedReason, isNull);
    });
  });

  group('loot and lore', () {
    test('recommended loot lines skip nameless items', () {
      final details = QuestSheetDetails.of(
        buildQuest(
          type: 'heal',
          recommendedLoot: [
            {
              'quantity': 2,
              'item': {'id': 'l-1', 'name': 'Pozione', 'description': 'd'},
            },
            {
              'quantity': 1,
              'item': {'id': 'l-2', 'name': null, 'description': 'd'},
            },
          ],
        ),
      );
      expect(details.recommendedLootLines, ['2x Pozione']);
    });

    test('missing loot gives no lines', () {
      expect(QuestSheetDetails.of(buildQuest()).recommendedLootLines, isEmpty);
    });

    test('lore paragraphs are the non-empty descriptions', () {
      final details = QuestSheetDetails.of(
        buildQuest(
          type: 'story',
          lore: [
            {'id': 'l-1', 'name': 'Il patto', 'description': 'Molto tempo fa…'},
            {'id': 'l-2', 'name': 'Vuoto', 'description': ''},
          ],
        ),
      );
      expect(details.loreParagraphs, ['Molto tempo fa…']);
    });

    test('missing lore gives no paragraphs', () {
      expect(QuestSheetDetails.of(buildQuest()).loreParagraphs, isEmpty);
    });
  });
}
