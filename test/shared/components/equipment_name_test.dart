import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/equipment_name.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

EquipmentItem _helm({required String? rarity}) => EquipmentItem.fromJson({
  'id': 'item-1',
  'name': 'Elmo di ferro',
  'equipType': 'helm',
  'rarity': rarity,
  'damages': {'base': [], 'energy': []},
});

Future<Color?> _nameColor(WidgetTester tester, EquipmentItem item) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(body: EquipmentName(equipmentItem: item, height: 40)),
    ),
  );
  return tester.widget<Text>(find.text('Elmo di ferro')).style?.color;
}

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.helmetType]));

  testWidgets('the name is drawn in the colour of its rarity', (tester) async {
    expect(
      await _nameColor(tester, _helm(rarity: 'uncommon')),
      RarityType.uncommon.color,
    );
  });

  testWidgets('a null rarity falls back to the default ink (D-16)', (
    tester,
  ) async {
    expect(
      await _nameColor(tester, _helm(rarity: null)),
      KlimmeckGuideTheme.deepNight,
    );
  });
}
