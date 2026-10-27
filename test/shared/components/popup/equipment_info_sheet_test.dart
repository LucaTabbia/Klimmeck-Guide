import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/popup/equipment_info_sheet.dart';

import '../../../helpers/landscape.dart';
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
  bool? isEquipped,
  VoidCallback? onEquip,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EquipmentInfoSheet(
            equipmentItem: _helm,
            isEquipped: isEquipped,
            onEquip: onEquip,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _screenHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

BookmarkRibbon _ribbon(WidgetTester tester) =>
    tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));

AnimatedPositioned _positioned(WidgetTester tester) =>
    tester.widget<AnimatedPositioned>(
      find.descendant(
        of: find.byType(BookmarkRibbon),
        matching: find.byType(AnimatedPositioned),
      ),
    );

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.bookmarkRed,
      CloudinaryAssets.helmetType,
    ]),
  );

  group('equip toggle', () {
    testWidgets('an unequipped item shows the ribbon with today geometry', (
      tester,
    ) async {
      await _pump(tester, isEquipped: false, onEquip: () {});
      final h = _screenHeight(tester);

      final ribbon = _ribbon(tester);
      expect(find.byType(BookmarkRibbon), findsOneWidget);
      expect(ribbon.left, 20);
      expect(ribbon.length, h / 2.5);
      expect(ribbon.peek, h / 4);
      expect(ribbon.width, isNull);
      expect(ribbon.curve, Curves.linear);
      expect(_positioned(tester).top, -(h / 2.5) + h / 4);
      final svg = tester.widget<CachedSvg>(
        find.descendant(
          of: find.byType(BookmarkRibbon),
          matching: find.byType(CachedSvg),
        ),
      );
      expect(svg.height, h / 2.5);
    });

    testWidgets('tapping the ribbon equips the item', (tester) async {
      var taps = 0;
      await _pump(tester, isEquipped: false, onEquip: () => taps++);

      await tester.tap(find.byType(RotatedBox));

      expect(taps, 1);
    });

    testWidgets('an equipped item shows the ribbon fully', (tester) async {
      await _pump(tester, isEquipped: true, onEquip: () {});

      expect(_positioned(tester).top, 0);
    });

    testWidgets('without an equip state there is no ribbon', (tester) async {
      await _pump(tester);

      expect(find.byType(BookmarkRibbon), findsNothing);
    });
  });
}
