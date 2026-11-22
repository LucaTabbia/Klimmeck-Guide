import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

void main() {
  test(
    'the text outline is a full ring around the letters, not four corners',
    () {
      final outline = KlimmeckGuideTheme.bordersForText;
      const width = KlimmeckGuideTheme.textOutlineWidth;

      expect(outline, hasLength(16));
      for (final shadow in outline) {
        expect(shadow.color, KlimmeckGuideTheme.deepNight);
        expect(shadow.blurRadius, 0);
        expect(shadow.offset.distance, moreOrLessEquals(width, epsilon: 0.01));
      }
      final angles = [
        for (final shadow in outline)
          (shadow.offset.direction * 8 / math.pi).round() % 16,
      ];
      expect(angles.toSet(), {for (var step = 0; step < 16; step++) step});
    },
  );

  test('the outline is thick enough to read over the map', () {
    expect(KlimmeckGuideTheme.textOutlineWidth, greaterThanOrEqualTo(1.5));
  });
}
