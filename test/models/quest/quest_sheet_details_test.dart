import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_sheet_details.dart';
import 'package:klimmeck_guide/models/quest/quest_travel_line.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';

import '../../helpers/fixtures/quest_fixtures.dart';
import '../../helpers/fixtures/travel_fixtures.dart';

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
        QuestType.magic,
        QuestType.crime,
        QuestType.guard,
        null,
      ]) {
        expect(questSheetFamilyOf(type), QuestSheetFamily.service);
      }
    });

    test(
      'crime and guard stay in the service family, dungeon in combat, without alignment (D-11)',
      () {
        expect(questSheetFamilyOf(QuestType.crime), QuestSheetFamily.service);
        expect(questSheetFamilyOf(QuestType.guard), QuestSheetFamily.service);
        expect(questSheetFamilyOf(QuestType.dungeon), QuestSheetFamily.combat);

        final crime = QuestSheetDetails.of(buildQuest(type: 'crime'));
        expect(crime.enemyLines, isEmpty);
        expect(crime.slotLines, isEmpty);
      },
    );
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

  group('enemies and companion prize', () {
    List<Map<String, dynamic>> goblinPack() => [
      questEnemyJson(id: 'goblin', name: 'Goblin', quantity: 3, xp: 7),
      questEnemyJson(id: 'goblin-chief', name: 'Capo goblin', xp: 21),
    ];

    test('enemyLines lists the quest enemies as «Nx nome» in BE order '
        '(D-02)', () {
      final details = QuestSheetDetails.of(buildQuest(enemies: goblinPack()));

      expect(details.enemyLines, ['3x Goblin', '1x Capo goblin']);
    });

    test('enemyLines is empty for a quest without enemies (D-02)', () {
      expect(QuestSheetDetails.of(buildQuest()).enemyLines, isEmpty);
    });

    test('strongestEnemy is the enemy with the highest xp (D-02)', () {
      final details = QuestSheetDetails.of(buildQuest(enemies: goblinPack()));

      expect(details.strongestEnemy?.name, 'Capo goblin');
    });

    test("the portrait follows the strongest enemy's own known (D-08)", () {
      final unknownTroll = QuestSheetDetails.of(
        buildQuest(
          enemies: [
            questEnemyJson(id: 'wolf', xp: 10),
            questEnemyJson(id: 'troll', name: 'Troll', xp: 90, known: false),
          ],
        ),
      );
      expect(unknownTroll.isStrongestEnemyKnown, isFalse);

      final knownTroll = QuestSheetDetails.of(
        buildQuest(
          enemies: [
            questEnemyJson(id: 'wolf', xp: 10, known: false),
            questEnemyJson(id: 'troll', name: 'Troll', xp: 90),
          ],
        ),
      );
      expect(knownTroll.isStrongestEnemyKnown, isTrue);
    });

    test('a quest without enemies counts as known (D-08)', () {
      expect(QuestSheetDetails.of(buildQuest()).isStrongestEnemyKnown, isTrue);
    });

    test('petPrizeLine reads «Compagno in premio: <nome>» (D-06)', () {
      final details = QuestSheetDetails.of(
        buildQuest(
          prizes: {
            'pet': {'id': 'pet-owl', 'name': 'Gufo reale'},
          },
        ),
      );

      expect(details.petPrizeLine, 'Compagno in premio: Gufo reale');
    });

    test('petPrizeLine is null without a pet or a pet name (D-06)', () {
      expect(QuestSheetDetails.of(buildQuest()).petPrizeLine, isNull);
      final nameless = QuestSheetDetails.of(
        buildQuest(
          prizes: {
            'pet': {'id': 'pet-owl'},
          },
        ),
      );
      expect(nameless.petPrizeLine, isNull);
    });
  });

  group('travel line', () {
    final preview = TravelPreview.fromJson(
      travelPreviewJson(
        food: [travelFoodItemJson()],
        hpLost: 0,
        arrivesAlive: true,
      ),
    );

    test('travelLine comes from the preview on a combat sheet (D-04)', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'hunt'),
        travelPreview: preview,
      );
      expect(details.travelLine, QuestTravelLine.of(preview));
      expect(details.travelLine, isNotNull);
    });

    test('travelLine comes from the preview on a service sheet (D-04)', () {
      final details = QuestSheetDetails.of(
        buildQuest(type: 'crime'),
        travelPreview: preview,
      );
      expect(details.travelLine, QuestTravelLine.of(preview));
      expect(details.travelLine, isNotNull);
    });

    test(
      'travelLine is null on a narrative sheet even with a preview (D-04)',
      () {
        for (final type in ['story', 'worldMission']) {
          final details = QuestSheetDetails.of(
            buildQuest(type: type),
            travelPreview: preview,
          );
          expect(details.travelLine, isNull, reason: type);
        }
      },
    );

    test('travelLine is null without a preview (D-04)', () {
      expect(QuestSheetDetails.of(buildQuest(type: 'hunt')).travelLine, isNull);
    });
  });
}
