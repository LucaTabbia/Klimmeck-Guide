import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/equipment_box.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

final _bow = EquipmentItem.fromJson(const {
  'id': 'e-bow',
  'name': 'Arco corto',
  'equipType': 'weapon',
  'equipSubType': 'bow',
});

Future<void> _pump(
  WidgetTester tester, {
  EquipmentItem? item,
  EquipmentItem? blockedBy,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: EquipmentBox(
          size: 80,
          item: item,
          blockedBy: blockedBy,
          selectedBox: null,
          slotType: SlotType.rightHand,
          onTap: (_) {},
        ),
      ),
    ),
  );
}

double? _opacityOverIcon(WidgetTester tester) {
  final opacity = find.ancestor(
    of: find.byType(CachedSvg),
    matching: find.byType(Opacity),
  );
  if (opacity.evaluate().isEmpty) return null;
  return tester.widget<Opacity>(opacity.first).opacity;
}

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.weaponType]));

  testWidgets('a worn piece shows its icon at full opacity', (tester) async {
    await _pump(tester, item: _bow);

    expect(find.byType(CachedSvg), findsOneWidget);
    expect(_opacityOverIcon(tester), isNull);
  });

  testWidgets('a hand blocked by a two-handed weapon shows it faded', (
    tester,
  ) async {
    await _pump(tester, blockedBy: _bow);

    expect(find.byType(CachedSvg), findsOneWidget);
    expect(_opacityOverIcon(tester), lessThan(1));
  });

  testWidgets('an empty hand shows no icon', (tester) async {
    await _pump(tester);

    expect(find.byType(CachedSvg), findsNothing);
  });
}
