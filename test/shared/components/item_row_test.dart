import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

LootItem _loot({EffectType? effect, int? power}) => LootItem(
  id: 'l-1',
  name: 'Pozione',
  description: 'Cura le ferite',
  rarity: null,
  buyPrice: null,
  sellPrice: null,
  effect: effect,
  power: power,
);

final _helm = AssetItem.fromJson({
  'id': 'e-1',
  'name': 'Elmo',
  'description': 'Un elmo robusto',
  'equipType': 'helm',
  'rarity': 'common',
});

Future<void> _pump(WidgetTester tester, AssetItem assetItem) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: ItemRow(assetItem: assetItem, size: 80, showCoins: false),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.munitionEffect,
      CloudinaryAssets.helmetType,
    ]),
  );

  group('effect line', () {
    testWidgets('a loot item shows «Cura: 12» under the description', (
      tester,
    ) async {
      await _pump(tester, _loot(effect: EffectType.heal, power: 12));

      expect(find.text('Cura le ferite'), findsOneWidget);
      expect(find.text('Cura: 12'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-effect-l-1')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Cura: 12')).dy,
        greaterThan(tester.getTopLeft(find.text('Cura le ferite')).dy),
      );
    });

    testWidgets('a zero power shows only the effect', (tester) async {
      await _pump(tester, _loot(effect: EffectType.heal, power: 0));

      expect(find.text('Cura'), findsOneWidget);
    });

    testWidgets('a loot item without effect shows no line', (tester) async {
      await _pump(tester, _loot(power: 12));

      expect(find.text('Cura le ferite'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-effect-l-1')), findsNothing);
    });

    testWidgets('an equipment item shows no line', (tester) async {
      await _pump(tester, _helm);

      expect(find.text('Un elmo robusto'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-effect-e-1')), findsNothing);
    });
  });
}
