import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_modal.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';

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

AssetQuantity _equipment(String id, EquipType equipType) =>
    AssetQuantity.fromJson({
      'item': {
        'id': id,
        'name': id,
        'description': 'Equipaggiamento $id',
        'equipType': equipType.name,
        'rarity': 'common',
      },
      'quantity': 1,
    });

final _potion = _loot('l-heal', EffectType.heal);
final _bread = _loot('l-food', EffectType.hunger);
final _helm = _equipment('e-helm', EquipType.helm);
final _boots = _equipment('e-boots', EquipType.boots);

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
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: ShopModal(
            equipments: equipments,
            items: items,
            onSelect: (_) {},
            selectedItems: const [],
            isBuy: true,
            isAdd: null,
            onEquipmentInfo: (_) {},
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
}
