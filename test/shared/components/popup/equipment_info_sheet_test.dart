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

EquipmentItem _jewel(String equipType, String name, List<String>? uses) =>
    EquipmentItem.fromJson({
      'id': 'item-$equipType',
      'name': name,
      'equipType': equipType,
      'rarity': 'rare',
      'damages': {'base': [], 'energy': []},
      if (uses != null) 'accessoryUseTypes': uses,
    });

EquipmentItem _ring(List<String>? uses) =>
    _jewel('ring', 'Anello di rubino', uses);

EquipmentItem _necklace(List<String>? uses) =>
    _jewel('necklace', "Collana d'ambra", uses);

Future<void> _pump(
  WidgetTester tester, {
  EquipmentItem? item,
  bool? isEquipped,
  VoidCallback? onEquip,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EquipmentInfoSheet(
            equipmentItem: item ?? _helm,
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
      CloudinaryAssets.ringType,
      CloudinaryAssets.necklaceType,
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

  group('«Uso» line', () {
    Text usageText(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(EquipmentInfoSheet.usageKey));

    testWidgets('a ring for attack shows «Uso: attacco» (D-12)', (
      tester,
    ) async {
      await _pump(tester, item: _ring(['attack']));

      expect(usageText(tester).data, 'Uso: attacco');
      expect(
        tester.getTopLeft(find.byKey(EquipmentInfoSheet.usageKey)).dy,
        greaterThan(tester.getTopLeft(find.text('Anello di rubino')).dy),
      );
    });

    testWidgets('a necklace for both shows «Uso: attacco e difesa» (D-12)', (
      tester,
    ) async {
      await _pump(tester, item: _necklace(['attack', 'defense']));

      expect(usageText(tester).data, 'Uso: attacco e difesa');
    });

    testWidgets('a helm shows no use line (D-12)', (tester) async {
      await _pump(tester);

      expect(find.byKey(EquipmentInfoSheet.usageKey), findsNothing);
    });

    testWidgets('a ring without use types shows no use line (D-12)', (
      tester,
    ) async {
      await _pump(tester, item: _ring(null));

      expect(find.byKey(EquipmentInfoSheet.usageKey), findsNothing);
    });

    testWidgets('the use line does not overflow in landscape (D-12)', (
      tester,
    ) async {
      await _pump(tester, item: _necklace(['attack', 'defense']));

      expect(find.byKey(EquipmentInfoSheet.usageKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
