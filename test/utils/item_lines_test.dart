import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/accessory_use_type.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/loot_recovery.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest/quest_cure.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../helpers/fixtures/shop_fixtures.dart';

QuestCure _cure({
  double share = 0.5,
  List<InjuryType> canHeal = const [
    InjuryType.contusion,
    InjuryType.deepCut,
    InjuryType.frostbite,
  ],
}) => QuestCure(lifePointsShare: share, canHeal: canHeal);

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

  group('curableInjuriesLine', () {
    test(
      "lists only the character's injuries the cure heals, in the character's order (D-03)",
      () {
        expect(
          curableInjuriesLine(_cure(), const [
            InjuryType.deepCut,
            InjuryType.blindness,
            InjuryType.contusion,
          ]),
          'Cura le tue ferite: taglio profondo, contusione',
        );
      },
    );

    test('a repeated injury is listed once (D-03)', () {
      expect(
        curableInjuriesLine(_cure(), const [
          InjuryType.contusion,
          InjuryType.contusion,
        ]),
        'Cura le tue ferite: contusione',
      );
    });

    test(
      "no line when none of the character's injuries is in the list (D-03)",
      () {
        expect(
          curableInjuriesLine(_cure(), const [InjuryType.blindness]),
          isNull,
        );
      },
    );

    test(
      "no line without a cure or without the character's injuries (D-03)",
      () {
        expect(curableInjuriesLine(null, const [InjuryType.contusion]), isNull);
        expect(curableInjuriesLine(_cure(), null), isNull);
        expect(curableInjuriesLine(_cure(), const []), isNull);
      },
    );

    test('never lists an injury the character does not have (D-03)', () {
      final line = curableInjuriesLine(_cure(), const [InjuryType.contusion]);
      expect(line, isNot(contains('taglio profondo')));
      expect(line, isNot(contains('congelamento')));
    });
  });

  group('lifeShareLine', () {
    test('turns the share into a percentage (D-04)', () {
      expect(lifeShareLine(_cure(share: 0.5)), 'Vita: almeno il 50%');
      expect(lifeShareLine(_cure(share: 0.79)), 'Vita: almeno il 79%');
      expect(lifeShareLine(_cure(share: 0.9)), 'Vita: almeno il 90%');
    });

    test('elides the article where Italian requires it (D-21)', () {
      expect(lifeShareLine(_cure(share: 0.8)), "Vita: almeno l'80%");
      expect(lifeShareLine(_cure(share: 0.85)), "Vita: almeno l'85%");
      expect(lifeShareLine(_cure(share: 0.89)), "Vita: almeno l'89%");
      expect(lifeShareLine(_cure(share: 0.08)), "Vita: almeno l'8%");
      expect(lifeShareLine(_cure(share: 0.11)), "Vita: almeno l'11%");
      expect(lifeShareLine(_cure(share: 0.5)), 'Vita: almeno il 50%');
    });

    test('elides the article before one per cent too (D-21)', () {
      expect(lifeShareLine(_cure(share: 0.01)), "Vita: almeno l'1%");
    });

    test('a full share reads al massimo (D-04)', () {
      expect(lifeShareLine(_cure(share: 1)), 'Vita: al massimo');
    });

    test('a zero share hides the row (D-04)', () {
      expect(lifeShareLine(_cure(share: 0)), isNull);
    });

    test('no row without a cure (D-04)', () {
      expect(lifeShareLine(null), isNull);
    });
  });

  group('healedLine', () {
    test(
      'lists the healed injuries in lowercase, in the given order (D-06, D-19)',
      () {
        expect(
          healedLine(const [InjuryType.deepCut, InjuryType.contusion]),
          'Guarite: taglio profondo, contusione',
        );
      },
    );

    test('no line when nothing was healed (D-06)', () {
      expect(healedLine(const []), isNull);
    });
  });

  group('recoveryLine', () {
    test(
      'humanises the recovery time with the shared game duration (D-13, D-17)',
      () {
        expect(
          recoveryLine(const LootRecovery(time: 1800000, turns: 3)),
          'Ricarica: 30 min',
        );
        expect(
          recoveryLine(const LootRecovery(time: 5400000, turns: 3)),
          'Ricarica: 1 h 30 min',
        );
        expect(
          recoveryLine(const LootRecovery(time: 86400000, turns: 3)),
          'Ricarica: 1 g',
        );
      },
    );

    test('never shows the turns (D-13)', () {
      expect(
        recoveryLine(const LootRecovery(time: 1800000, turns: 7)),
        isNot(contains('7')),
      );
    });

    test('no line without a recovery (D-13)', () {
      expect(recoveryLine(null), isNull);
    });
  });

  group('potionReadyInLine', () {
    test(
      'reads the remaining time with the shared game duration (D-12, D-17)',
      () {
        expect(
          potionReadyInLine(const Duration(minutes: 72)),
          'pronta fra 1 h 12 min',
        );
      },
    );

    test('rounds up to the minute like every game duration (D-12, D-17)', () {
      expect(
        potionReadyInLine(const Duration(seconds: 20)),
        'pronta fra 1 min',
      );
      expect(
        potionReadyInLine(const Duration(minutes: 71, seconds: 1)),
        'pronta fra 1 h 12 min',
      );
    });
  });
}
