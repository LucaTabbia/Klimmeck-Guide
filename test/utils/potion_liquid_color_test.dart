import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/utils/potion_liquid_color.dart';

void main() {
  group('potionLiquidColorOf', () {
    test('gives every rarity a colour of its own', () {
      final colors = RarityType.values.map(potionLiquidColorOf).toSet();
      expect(colors, hasLength(RarityType.values.length));
    });

    test('reads an unknown rarity as common', () {
      expect(potionLiquidColorOf(null), potionLiquidColorOf(RarityType.common));
    });
  });
}
