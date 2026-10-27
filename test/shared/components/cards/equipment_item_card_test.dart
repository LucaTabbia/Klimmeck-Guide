import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cards/equipment_item_card.dart';

import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

final _helm = EquipmentItem.fromJson(const {
  'id': 'item-1',
  'name': 'Elmo di ferro',
  'equipType': 'helm',
  'rarity': 'common',
  'damages': {'base': [], 'energy': []},
});

Future<void> _pump(
  WidgetTester tester, {
  bool? isSelected,
  int? quantity,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(
          child: EquipmentItemCard(
            equipmentItem: _helm,
            size: 120,
            isSelected: isSelected,
            quantity: quantity,
          ),
        ),
      ),
    ),
  );
}

BookmarkRibbon _ribbon(WidgetTester tester) =>
    tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
      CloudinaryAssets.helmetType,
    ]),
  );

  group('bookmark', () {
    testWidgets('an item that cannot be equipped has no bookmark', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Elmo di ferro'), findsOneWidget);
      expect(find.byType(BookmarkRibbon), findsNothing);
    });

    testWidgets('an equipped item is marked', (tester) async {
      await _pump(tester, isSelected: true);

      expect(find.byType(CardBookmark), findsOneWidget);
      expect(_ribbon(tester).isMarked, isTrue);
    });

    testWidgets('an unequipped item is not marked', (tester) async {
      await _pump(tester, isSelected: false);

      expect(_ribbon(tester).isMarked, isFalse);
    });
  });
}
