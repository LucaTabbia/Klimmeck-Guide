import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';

AssetQuantity _equipment(String id, String equipType) => AssetQuantity(
  item: AssetItem.fromJson({
    'id': id,
    'name': 'Equip $id',
    'description': '',
    'equipType': equipType,
  }),
  quantity: 1,
);

AssetQuantity _loot(String id, String? effect) => AssetQuantity(
  item: AssetItem.fromJson({
    'id': id,
    'name': 'Loot $id',
    'description': '',
    'effect': effect,
    'power': 12,
  }),
  quantity: 1,
);

const _untypedEquipment = AssetQuantity(
  item: EquipmentItem(
    id: 'e-null',
    name: 'Senza tipo',
    description: '',
    rarity: null,
    sellPrice: null,
    buyPrice: null,
    equipType: null,
    addedSpell: null,
    damages: null,
  ),
  quantity: 1,
);

const _emptySlot = AssetQuantity(item: null, quantity: 1);

void main() {
  group('presentFilterValues', () {
    test('keeps the enum order and drops duplicates and nulls', () {
      expect(
        presentFilterValues(UseType.values, [
          UseType.charm,
          null,
          UseType.attack,
          UseType.charm,
        ]),
        [UseType.attack, UseType.charm],
      );
    });

    test('nothing found yields an empty list', () {
      expect(presentFilterValues(UseType.values, <UseType?>[]), isEmpty);
      expect(presentFilterValues(UseType.values, [null, null]), isEmpty);
    });
  });

  group('retainedFilterSelections', () {
    test('the present types of the selection survive', () {
      expect(
        retainedFilterSelections(
          {UseType.attack, UseType.control},
          [UseType.attack, UseType.defense],
        ),
        {UseType.attack},
      );
    });

    test('an empty selection stays empty: every row shows', () {
      expect(retainedFilterSelections(<UseType>{}, [UseType.attack]), isEmpty);
    });
  });

  group('matchesFilterSelection', () {
    test('an empty selection lets every value through, even untyped ones', () {
      expect(matchesFilterSelection(<UseType>{}, UseType.attack), isTrue);
      expect(matchesFilterSelection(<UseType>{}, null), isTrue);
    });

    test('a selection lets through only its types', () {
      const selected = {UseType.attack, UseType.defense};

      expect(matchesFilterSelection(selected, UseType.defense), isTrue);
      expect(matchesFilterSelection(selected, UseType.control), isFalse);
      expect(matchesFilterSelection(selected, null), isFalse);
    });
  });

  group('toggledFilterSelection', () {
    test('a type not selected joins the selection', () {
      expect(toggledFilterSelection({UseType.attack}, UseType.defense), {
        UseType.attack,
        UseType.defense,
      });
    });

    test('a selected type leaves the selection', () {
      expect(toggledFilterSelection({UseType.attack}, UseType.attack), isEmpty);
    });
  });

  test('presentEquipTypes reads only the typed equipments', () {
    expect(
      presentEquipTypes([
        _equipment('e-1', 'boots'),
        _equipment('e-2', 'helm'),
        _untypedEquipment,
        _loot('l-1', 'heal'),
        _emptySlot,
      ]),
      [EquipType.helm, EquipType.boots],
    );
  });

  test('presentEffectTypes reads only the typed loot', () {
    expect(
      presentEffectTypes([
        _loot('l-1', 'exploration'),
        _loot('l-2', 'heal'),
        _loot('l-3', null),
        _equipment('e-1', 'helm'),
        _emptySlot,
      ]),
      [EffectType.heal, EffectType.exploration],
    );
  });
}
