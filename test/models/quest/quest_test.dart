import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/adventurer_slot.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_requirements.dart';
import 'package:klimmeck_guide/models/quest/registered_adventurer.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  group('Quest.fromJson', () {
    test('parses the Phase 8 shapes', () {
      final quest = Quest.fromJson(
        questJson(
          slots: [
            {'title': 'hero', 'count': 1},
            {'title': null, 'count': 2},
          ],
          registered: [
            {'character': 'c-1', 'title': 'paladin'},
          ],
        ),
      );
      expect(quest.requirements!.requiredAdventurers, const [
        AdventurerSlot(title: TitleType.hero, count: 1),
        AdventurerSlot(title: null, count: 2),
      ]);
      expect(quest.registeredAdventurers, const [
        RegisteredAdventurer(characterId: 'c-1', title: TitleType.paladin),
      ]);
    });

    test('parses the Phase 7 legacy shapes', () {
      final quest = Quest.fromJson(legacyQuestJson());
      expect(quest.requirements!.requiredAdventurers, const [
        AdventurerSlot(title: null, count: 1),
      ]);
      expect(quest.registeredAdventurers, const [
        RegisteredAdventurer(characterId: 'c-1', title: null),
      ]);
    });

    test('toJson emits slots and registrations as objects', () {
      final json = buildQuest(
        slots: [
          {'title': 'hero', 'count': 1},
        ],
        registered: [
          {'character': 'c-1', 'title': 'mage'},
        ],
      ).toJson();
      expect(json['registeredAdventurers'], [
        {'character': 'c-1', 'title': 'mage'},
      ]);
      expect((json['requirements'] as Map)['requiredAdventurers'], [
        {'title': 'hero', 'count': 1},
      ]);
    });
  });

  group('QuestRequirements.hasRankSlots', () {
    test('is true for the Phase 8 list, also when empty', () {
      expect(
        QuestRequirements.fromJson({
          'requiredAdventurers': [
            {'title': null, 'count': 1},
          ],
        }).hasRankSlots,
        isTrue,
      );
      expect(
        QuestRequirements.fromJson({'requiredAdventurers': []}).hasRankSlots,
        isTrue,
      );
    });

    test('is false for the legacy Int and for a missing key', () {
      expect(
        QuestRequirements.fromJson({'requiredAdventurers': 0}).hasRankSlots,
        isFalse,
      );
      expect(
        QuestRequirements.fromJson({'requiredAdventurers': 3}).hasRankSlots,
        isFalse,
      );
      expect(QuestRequirements.fromJson({}).hasRankSlots, isFalse);
    });

    test('a legacy Int 0 gives no slots and no rank marker', () {
      final requirements = Quest.fromJson(
        legacyQuestJson(requiredAdventurers: 0),
      ).requirements!;
      expect(requirements.requiredAdventurers, isEmpty);
      expect(requirements.hasRankSlots, isFalse);
    });
  });

  group('Quest.fromJson with the catalog items on the wire', () {
    Map<String, dynamic> lootOnWire({String? description}) => {
      'id': 'l-1',
      'name': 'Frecce da Caccia',
      'itemType': 'LootItem',
      'rarity': 'common',
      if (description != null) 'description': description,
    };

    test('a loot item without description still parses (simpleFields)', () {
      final quest = Quest.fromJson(
        questJson(
          type: 'hunt',
          recommendedLoot: [
            {'quantity': 10, 'item': lootOnWire()},
          ],
        ),
      );
      final loot = quest.requirements!.recommendedLoot!.single;
      expect(loot.quantity, 10);
      expect(loot.item!.name, 'Frecce da Caccia');
      expect(loot.item!.description, '');
    });

    test('prizeItem arrives as an AssetQuantity { quantity item }', () {
      final json = questJson(type: 'study');
      json['prizes'] = {
        'xpPrize': 10,
        'prizeItem': {
          'quantity': 1,
          'item': lootOnWire(description: 'Una pergamena'),
        },
        'randomLoot': [
          {'quantity': 2, 'item': lootOnWire()},
        ],
      };
      final quest = Quest.fromJson(json);
      expect(quest.prizes!.prizeItem!.name, 'Frecce da Caccia');
      expect(quest.prizes!.prizeItem!.description, 'Una pergamena');
      expect(quest.prizes!.randomLoot!.single.quantity, 2);
    });

    test('a bare prizeItem (legacy shape) still parses', () {
      final json = questJson(type: 'study');
      json['prizes'] = {'prizeItem': lootOnWire(description: 'x')};
      expect(Quest.fromJson(json).prizes!.prizeItem!.name, 'Frecce da Caccia');
    });
  });

  group('Quest.tryFromJson', () {
    test('returns null for an unknown type', () {
      expect(Quest.tryFromJson(questJson(type: 'treasure')), isNull);
    });

    test('returns null for an unknown minTitle', () {
      expect(Quest.tryFromJson(questJson(minTitle: 'wizard')), isNull);
    });

    test('returns null for an unknown slot title', () {
      expect(
        Quest.tryFromJson(
          questJson(
            slots: [
              {'title': 'wizard', 'count': 1},
            ],
          ),
        ),
        isNull,
      );
    });

    test('returns null for a non-map', () {
      expect(Quest.tryFromJson('x'), isNull);
    });

    test('returns the quest when valid', () {
      expect(Quest.tryFromJson(questJson())?.id, 'q-1');
    });
  });
}
