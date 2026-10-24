import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';

import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

/// Un loot letto dal documento `quests` con i soli simpleFields: niente power.
LootItem _loot({int? power}) => LootItem(
  id: 'l-1',
  name: 'Pozione',
  description: '',
  rarity: null,
  buyPrice: null,
  sellPrice: null,
  power: power,
  effect: null,
);

Future<void> _pump(WidgetTester tester, LootItem lootItem) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(child: LootItemCard(lootItem: lootItem, size: 120)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.emptyCardSheet]));

  group('power line', () {
    testWidgets('a loot item without power never prints null', (tester) async {
      await _pump(tester, _loot(power: null));

      expect(find.text('Pozione'), findsOneWidget);
      expect(find.text('null'), findsNothing);
    });

    testWidgets('a zero power is not shown', (tester) async {
      await _pump(tester, _loot(power: 0));

      expect(find.text('0'), findsNothing);
    });

    testWidgets('a positive power is shown', (tester) async {
      await _pump(tester, _loot(power: 7));

      expect(find.text('7'), findsOneWidget);
    });
  });
}
