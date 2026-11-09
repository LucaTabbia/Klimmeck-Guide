import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/accessory_use_type.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../helpers/fixtures/shop_fixtures.dart';

LootItem _loot({
  EffectType? effect,
  int? power,
  List<InjuryType> injuries = const [],
}) => LootItem(
  id: 'l-1',
  name: 'Pozione',
  description: '',
  rarity: null,
  buyPrice: null,
  sellPrice: null,
  effect: effect,
  power: power,
  canHeal: injuries,
);

EquipmentItem _jewel(EquipType equipType, List<AccessoryUseType>? uses) =>
    EquipmentItem(
      id: 'eq-1',
      name: 'Gioiello',
      description: '',
      rarity: null,
      sellPrice: null,
      buyPrice: null,
      equipType: equipType,
      addedSpell: null,
      damages: null,
      accessoryUseTypes: uses,
    );

void main() {
  group('itemEffectLabel', () {
    test('effect and power read «Cura: 12»', () {
      expect(
        itemEffectLabel(_loot(effect: EffectType.heal, power: 12)),
        'Cura: 12',
      );
    });

    test('a zero power shows only the effect', () {
      expect(itemEffectLabel(_loot(effect: EffectType.heal, power: 0)), 'Cura');
    });

    test('a missing power shows only the effect', () {
      expect(itemEffectLabel(_loot(effect: EffectType.heal)), 'Cura');
    });

    test('every effect uses its label', () {
      expect(
        itemEffectLabel(_loot(effect: EffectType.munition, power: 3)),
        'Danno: 3',
      );
      expect(
        itemEffectLabel(_loot(effect: EffectType.hunger, power: 5)),
        'Sazietà: 5',
      );
      expect(
        itemEffectLabel(_loot(effect: EffectType.exploration)),
        'Esplorazione',
      );
      expect(itemEffectLabel(_loot(effect: EffectType.none)), 'Nessun effetto');
    });

    test('no effect, no line', () {
      expect(itemEffectLabel(_loot(power: 12)), isNull);
    });
  });

  group('companionSpeedLabel', () {
    test(
      'companionSpeedLabel prints «Velocità ×2» for a modifier of 2 (D-11)',
      () {
        expect(companionSpeedLabel(Pet.fromJson(petJson())), 'Velocità ×2');
      },
    );

    test(
      'companionSpeedLabel prints «Velocità ×2,5» with the Italian decimal comma (D-11)',
      () {
        expect(
          companionSpeedLabel(Pet.fromJson(petJson(speedModifier: 2.5))),
          'Velocità ×2,5',
        );
      },
    );

    test(
      'companionSpeedLabel is null for a companion that is not a mount (D-07)',
      () {
        expect(companionSpeedLabel(Pet.fromJson(catPetJson())), isNull);
      },
    );
  });

  group('accessoryUsageLine', () {
    test('a ring for attack reads «Uso: attacco» (D-12)', () {
      expect(
        accessoryUsageLine(_jewel(EquipType.ring, [AccessoryUseType.attack])),
        'Uso: attacco',
      );
    });

    test('a necklace for defense reads «Uso: difesa» (D-12)', () {
      expect(
        accessoryUsageLine(
          _jewel(EquipType.necklace, [AccessoryUseType.defense]),
        ),
        'Uso: difesa',
      );
    });

    test(
      'both uses read «Uso: attacco e difesa» in canonical order (D-12)',
      () {
        expect(
          accessoryUsageLine(
            _jewel(EquipType.ring, [
              AccessoryUseType.defense,
              AccessoryUseType.attack,
            ]),
          ),
          'Uso: attacco e difesa',
        );
      },
    );

    test('duplicates read once (D-12)', () {
      expect(
        accessoryUsageLine(
          _jewel(EquipType.ring, [
            AccessoryUseType.attack,
            AccessoryUseType.attack,
          ]),
        ),
        'Uso: attacco',
      );
    });

    test('a helm never has a use line (D-12)', () {
      expect(
        accessoryUsageLine(_jewel(EquipType.helm, [AccessoryUseType.attack])),
        isNull,
      );
    });

    test('a ring without use types has no line (D-12)', () {
      expect(accessoryUsageLine(_jewel(EquipType.ring, null)), isNull);
      expect(accessoryUsageLine(_jewel(EquipType.ring, const [])), isNull);
    });
  });

  group('healedInjuriesLine', () {
    test(
      'a heal item lists the injuries it cures in enum order, lower case',
      () {
        expect(
          healedInjuriesLine(
            _loot(
              effect: EffectType.heal,
              power: 12,
              injuries: [InjuryType.blackEye, InjuryType.blindness],
            ),
          ),
          'Cura: cecità, occhio nero',
        );
      },
    );

    test('a single injury reads without a separator', () {
      expect(
        healedInjuriesLine(
          _loot(effect: EffectType.heal, injuries: [InjuryType.deepCut]),
        ),
        'Cura: taglio profondo',
      );
    });

    test('a heal item without injuries has no line', () {
      expect(
        healedInjuriesLine(_loot(effect: EffectType.heal, power: 12)),
        isNull,
      );
    });

    test('a non-heal item never has the line, even with injuries', () {
      expect(
        healedInjuriesLine(
          _loot(effect: EffectType.hunger, injuries: [InjuryType.deepCut]),
        ),
        isNull,
      );
      expect(healedInjuriesLine(_loot(injuries: [InjuryType.deepCut])), isNull);
    });
  });
}
