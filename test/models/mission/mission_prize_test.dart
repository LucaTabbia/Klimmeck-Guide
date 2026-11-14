import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';

import '../../helpers/fixtures/mission_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';
import '../../helpers/fixtures/shop_fixtures.dart';
import '../../helpers/fixtures/spell_fixtures.dart';

Map<String, dynamic> _equipment(String id, {String rarity = 'common'}) =>
    equipmentAssetJson(id: id, rarity: rarity)['item'] as Map<String, dynamic>;

Map<String, dynamic> _loot(String id) =>
    lootAssetJson(id: id)['item'] as Map<String, dynamic>;

void main() {
  group('MissionPrize', () {
    test('reads coins, xp, items, pet, spell and cure as served (D-22)', () {
      final prize = MissionPrize.tryFromJson(
        missionPrizeJson(
          coins: const {'gold': 3, 'silver': 20, 'copper': 5},
          xp: 240,
          items: [
            {'item': potionItemId, 'quantity': 2},
            {'item': 'e-sword', 'quantity': 1},
          ],
          pet: 'pet-owl',
          spell: fireballSpellId,
          cure: const {
            'lifePointsShare': 0.5,
            'canHeal': ['blackEye'],
          },
        ),
      )!;

      expect(prize.characterId, 'char-aldo');
      expect(prize.coins, const Coins(gold: 3, silver: 20, copper: 5));
      expect(prize.xp, 240);
      expect(prize.items, const [
        MissionPrizeItem(itemId: potionItemId, quantity: 2),
        MissionPrizeItem(itemId: 'e-sword', quantity: 1),
      ]);
      expect(prize.items.first.toJson(), {'item': potionItemId, 'quantity': 2});
      expect(prize.petId, 'pet-owl');
      expect(prize.spellId, fireballSpellId);
      expect(prize.cure!.lifePointsShare, 0.5);
      expect(prize.cure!.canHeal, [InjuryType.blackEye]);
    });

    test('absent pet, spell and cure read null', () {
      final prize = MissionPrize.tryFromJson(missionPrizeJson())!;

      expect(prize.petId, isNull);
      expect(prize.spellId, isNull);
      expect(prize.cure, isNull);
      expect(prize.items, isEmpty);
    });

    test('a malformed prize item is dropped, the prize stays (Pitfall 8)', () {
      final prize = MissionPrize.tryFromJson(
        missionPrizeJson(
          items: [
            {'item': null, 'quantity': 2},
            {'item': potionItemId, 'quantity': 1},
          ],
        ),
      )!;

      expect(prize.items, const [
        MissionPrizeItem(itemId: potionItemId, quantity: 1),
      ]);
    });
  });

  group('MissionPrizeOptions', () {
    test(
      'reads the served catalogue as listed, never filtered (D-07, rule 4)',
      () {
        final options = MissionPrizeOptions.tryFromJson(
          missionPrizeOptionsJson(
            equipment: [
              _equipment('e-crown', rarity: 'legendary'),
              _equipment('e-sword'),
            ],
            loot: [_loot('l-herb'), _loot('l-potion')],
            pets: [
              petJson(id: 'pet-owl', name: 'Gufo'),
              catPetJson(),
            ],
            spells: [
              spellJson(id: 'spell-b'),
              spellJson(id: 'spell-a'),
            ],
          ),
        )!;

        expect(options.characterId, 'char-aldo');
        expect(options.title, TitleType.paladin);
        expect(options.maxRarity, RarityType.rare);
        expect(options.equipment.map((item) => item.id), [
          'e-crown',
          'e-sword',
        ]);
        expect(options.equipment.first.rarity, RarityType.legendary);
        expect(options.loot.map((item) => item.id), ['l-herb', 'l-potion']);
        expect(options.pets.map((pet) => pet.id), ['pet-owl', 'pet-cat']);
        expect(options.spells.map((spell) => spell.id), ['spell-b', 'spell-a']);
        expect(options.catalogueItems.map((item) => item.id), [
          'e-crown',
          'e-sword',
          'l-herb',
          'l-potion',
        ]);
      },
    );

    test('catalogueItems appends block items not already listed (D-22)', () {
      final options = MissionPrizeOptions.tryFromJson(
        missionPrizeOptionsJson(
          equipment: [_equipment('e-sword')],
          block: {
            'prizeItem': {'item': _equipment('e-sword'), 'quantity': 1},
            'randomLoot': [
              {'item': _loot('l-relic'), 'quantity': 2},
            ],
            'pet': petJson(id: 'pet-owl', name: 'Gufo'),
            'spell': spellJson(id: fireballSpellId),
          },
        ),
      )!;

      expect(options.blockItems.map((item) => item.id), ['e-sword', 'l-relic']);
      expect(options.blockPet!.id, 'pet-owl');
      expect(options.blockSpell!.id, fireballSpellId);
      expect(options.catalogueItems.map((item) => item.id), [
        'e-sword',
        'l-relic',
      ]);
    });

    test('itemById / petById / spellById find catalogue and block entries', () {
      final options = MissionPrizeOptions.tryFromJson(
        missionPrizeOptionsJson(
          equipment: [_equipment('e-sword')],
          pets: [catPetJson()],
          spells: [spellJson(id: 'spell-a')],
          block: {
            'randomLoot': [
              {'item': _loot('l-relic'), 'quantity': 1},
            ],
            'pet': petJson(id: 'pet-owl', name: 'Gufo'),
            'spell': spellJson(id: fireballSpellId),
          },
        ),
      )!;

      expect(options.itemById('e-sword')!.id, 'e-sword');
      expect(options.itemById('l-relic')!.id, 'l-relic');
      expect(options.itemById('l-ghost'), isNull);
      expect(options.petById('pet-cat')!.id, 'pet-cat');
      expect(options.petById('pet-owl')!.id, 'pet-owl');
      expect(options.petById('pet-ghost'), isNull);
      expect(options.spellById('spell-a')!.id, 'spell-a');
      expect(options.spellById(fireballSpellId)!.id, fireballSpellId);
      expect(options.spellById('spell-ghost'), isNull);
    });

    test(
      'a malformed catalogue entry is dropped, the options stay (Pitfall 8)',
      () {
        final options = MissionPrizeOptions.tryFromJson(
          missionPrizeOptionsJson(
            maxRarity: 'mythic',
            equipment: [
              _equipment('e-bad', rarity: 'mythic'),
              _equipment('e-sword'),
            ],
            loot: [
              {..._loot('l-bad'), 'effect': 'teleport'},
              _loot('l-potion'),
            ],
            pets: [
              {'name': 'Senza id'},
              catPetJson(),
            ],
            spells: [
              {'name': 'Senza id'},
              spellJson(id: 'spell-a'),
            ],
            block: {
              'randomLoot': [
                {'item': 'not-a-map', 'quantity': 1},
              ],
            },
          ),
        )!;

        expect(options.maxRarity, isNull);
        expect(options.equipment.map((item) => item.id), ['e-sword']);
        expect(options.loot.map((item) => item.id), ['l-potion']);
        expect(options.pets.map((pet) => pet.id), ['pet-cat']);
        expect(options.spells.map((spell) => spell.id), ['spell-a']);
        expect(options.blockItems, isEmpty);
      },
    );

    test('options without character are null', () {
      expect(
        MissionPrizeOptions.tryFromJson({
          ...missionPrizeOptionsJson(),
          'character': null,
        }),
        isNull,
      );
    });
  });
}
