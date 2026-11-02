import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../helpers/fixtures/shop_fixtures.dart';

LootItem _loot({EffectType? effect, int? power}) => LootItem(
  id: 'l-1',
  name: 'Pozione',
  description: '',
  rarity: null,
  buyPrice: null,
  sellPrice: null,
  effect: effect,
  power: power,
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
}
