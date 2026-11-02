import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_modal.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../../../../../helpers/fixtures/shop_fixtures.dart';

import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

AssetQuantity _loot(String id, EffectType effect) => AssetQuantity.fromJson({
  'item': {
    'id': id,
    'name': id,
    'description': 'Oggetto $id',
    'effect': effect.name,
    'power': 3,
  },
  'quantity': 1,
});

AssetQuantity _equipment(
  String id,
  EquipType equipType, {
  String rarity = 'common',
}) => AssetQuantity.fromJson({
  'item': {
    'id': id,
    'name': id,
    'description': 'Equipaggiamento $id',
    'equipType': equipType.name,
    'rarity': rarity,
  },
  'quantity': 1,
});

final _potion = _loot('l-heal', EffectType.heal);
final _bread = _loot('l-food', EffectType.hunger);
final _helm = _equipment('e-helm', EquipType.helm);
final _boots = _equipment('e-boots', EquipType.boots);
final _horse = Pet.fromJson(petJson());
final _cat = Pet.fromJson(catPetJson());

const _companions = ValueKey('companions_dropdown');

Finder _companionRow(Pet pet) => find.byKey(ValueKey('shop-pet-${pet.id}'));

Finder _filterOf<T>() => find.byType(ItemsFilter<T>);

T? _currentOf<T>(WidgetTester tester) =>
    tester.widget<ItemsFilter<T>>(_filterOf<T>()).current;

Finder _chip<T>(String imagePath) => find.descendant(
  of: _filterOf<T>(),
  matching: find.byWidgetPredicate(
    (widget) => widget is CachedSvg && widget.url == imagePath,
  ),
);

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.arrowDown,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.hungerEffect,
      CloudinaryAssets.helmetType,
      CloudinaryAssets.bootsType,
    ]),
  );

  Future<void> pumpShop(
    WidgetTester tester, {
    List<AssetQuantity> equipments = const [],
    List<AssetQuantity> items = const [],
    List<Pet> pets = const [],
    bool isBuy = true,
    bool? isAdd,
    String? equippedPetId,
    void Function(TradeSelection)? onSelect,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: ShopModal(
            equipments: equipments,
            items: items,
            pets: pets,
            selection: const TradeSelection(),
            onSelect: onSelect ?? (TradeSelection _) {},
            isBuy: isBuy,
            isAdd: isAdd,
            onEquipmentInfo: (_) {},
            equippedPetId: equippedPetId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('a vanished effect falls back to «Tutti» for good (WR-02)', (
    tester,
  ) async {
    await pumpShop(tester, items: [_potion, _bread]);
    await tapAndSettle(tester, find.text('Oggetti'));
    await tapAndSettle(tester, _chip<EffectType>(EffectType.hunger.imagePath));
    expect(_currentOf<EffectType>(tester), EffectType.hunger);

    await pumpShop(tester, items: [_potion]);

    expect(_currentOf<EffectType>(tester), isNull);

    await pumpShop(tester, items: [_potion, _bread]);

    expect(_currentOf<EffectType>(tester), isNull);
    expect(find.text('Oggetto l-heal'), findsOneWidget);
    expect(find.text('Oggetto l-food'), findsOneWidget);
  });

  testWidgets('a vanished equip type falls back to «Tutti» for good (WR-02)', (
    tester,
  ) async {
    await pumpShop(tester, equipments: [_helm, _boots]);
    await tapAndSettle(tester, find.text('Armatura'));
    await tapAndSettle(tester, _chip<EquipType>(EquipType.boots.imagePath));
    expect(_currentOf<EquipType>(tester), EquipType.boots);

    await pumpShop(tester, equipments: [_helm]);

    expect(_currentOf<EquipType>(tester), isNull);

    await pumpShop(tester, equipments: [_helm, _boots]);

    expect(_currentOf<EquipType>(tester), isNull);
    expect(find.text('Equipaggiamento e-helm'), findsOneWidget);
    expect(find.text('Equipaggiamento e-boots'), findsOneWidget);
  });

  testWidgets('the chip rows start at the left edge of the rows', (
    tester,
  ) async {
    await pumpShop(tester, equipments: [_helm], items: [_potion]);

    final rowsLeft = tester.getTopLeft(find.byType(ItemRow).first).dx;
    expect(tester.getTopLeft(_filterOf<EquipType>()).dx, rowsLeft);
    expect(tester.getTopLeft(_filterOf<EffectType>()).dx, rowsLeft);
  });

  testWidgets(
    'the buy sheet lists the pool companions under «Compagni» (D-07)',
    (tester) async {
      await pumpShop(tester, pets: [_horse, _cat]);

      expect(find.byKey(_companions), findsOneWidget);
      expect(find.text('Compagni'), findsOneWidget);
      await tapAndSettle(tester, find.text('Compagni'));

      final rows = tester.widgetList<CompanionRow>(find.byType(CompanionRow));
      expect(rows.map((row) => row.pet), [_horse, _cat]);
      expect(rows.every((row) => row.isBuy), isTrue);
    },
  );

  testWidgets('«Compagni» is hidden when there are no companions (D-15)', (
    tester,
  ) async {
    await pumpShop(tester, items: [_potion]);

    expect(find.byKey(_companions), findsNothing);
  });

  testWidgets('the sell sheet marks the equipped companion (D-07)', (
    tester,
  ) async {
    await pumpShop(
      tester,
      pets: [_horse, _cat],
      isBuy: false,
      equippedPetId: 'pet-travel-horse',
    );
    await tapAndSettle(tester, find.text('Compagni'));

    expect(find.text(companionEquippedMark), findsOneWidget);
    expect(
      tester.widget<CompanionRow>(_companionRow(_horse)).isEquipped,
      isTrue,
    );
    expect(tester.widget<CompanionRow>(_companionRow(_horse)).isBuy, isFalse);
  });

  testWidgets(
    'the pencil adds a companion once, the rubber removes it (D-07)',
    (tester) async {
      final selections = <TradeSelection>[];
      await pumpShop(
        tester,
        pets: [_horse],
        isAdd: true,
        onSelect: selections.add,
      );
      await tapAndSettle(tester, find.text('Compagni'));
      await tapAndSettle(tester, _companionRow(_horse));
      await tapAndSettle(tester, _companionRow(_horse));

      expect(selections.last.pets, [_horse]);
      expect(
        tester.widget<CompanionRow>(_companionRow(_horse)).isSelected,
        isTrue,
      );

      await pumpShop(
        tester,
        pets: [_horse],
        isAdd: false,
        onSelect: selections.add,
      );
      await tapAndSettle(tester, _companionRow(_horse));

      expect(selections.last.pets, isEmpty);

      final count = selections.length;
      await pumpShop(tester, pets: [_horse], onSelect: selections.add);
      await tapAndSettle(tester, _companionRow(_horse));

      expect(selections, hasLength(count));
    },
  );

  testWidgets(
    'three open dropdowns share the height without overflow (Pitfall 5)',
    (tester) async {
      await pumpShop(
        tester,
        equipments: [_helm],
        items: [_potion],
        pets: [_horse],
      );
      await tapAndSettle(tester, find.text('Armatura'));
      await tapAndSettle(tester, find.text('Oggetti'));
      await tapAndSettle(tester, find.text('Compagni'));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the sell sheet lists an owned legendary item (D-09)', (
    tester,
  ) async {
    await pumpShop(
      tester,
      equipments: [_equipment('e-crown', EquipType.helm, rarity: 'legendary')],
      isBuy: false,
    );
    await tapAndSettle(tester, find.text('Armatura'));

    expect(find.text('Equipaggiamento e-crown'), findsOneWidget);
  });
}
