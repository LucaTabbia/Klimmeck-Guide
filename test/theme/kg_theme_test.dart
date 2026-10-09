import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final theme = KlimmeckGuideTheme.instance;

  group('inputDecorationTheme', () {
    final input = theme.materialTheme.inputDecorationTheme;

    test('is a filled parchment sheet', () {
      expect(input.filled, isTrue);
      expect(input.fillColor, KlimmeckGuideTheme.parchment);
    });

    test('renders errors with the project errorText style', () {
      expect(input.errorStyle, theme.errorText);
    });

    test('colors the borders by state', () {
      expect(
        (input.enabledBorder! as OutlineInputBorder).borderSide.color,
        KlimmeckGuideTheme.darkBronze,
      );
      final focused = (input.focusedBorder! as OutlineInputBorder).borderSide;
      expect(focused.color, KlimmeckGuideTheme.darkWood);
      expect(focused.width, 2);
      expect(
        (input.errorBorder! as OutlineInputBorder).borderSide.color,
        KlimmeckGuideTheme.bloodRed,
      );
      expect(
        (input.disabledBorder! as OutlineInputBorder).borderSide.color,
        KlimmeckGuideTheme.paleSilver,
      );
    });
  });

  group('chipTheme', () {
    final chip = theme.materialTheme.chipTheme;

    test('uses gold when selected and parchment otherwise', () {
      expect(chip.selectedColor, KlimmeckGuideTheme.primaryGold);
      expect(chip.backgroundColor, KlimmeckGuideTheme.parchment);
      expect(chip.checkmarkColor, KlimmeckGuideTheme.deepNight);
    });

    test('has a bronze border and the body label style', () {
      expect(chip.side?.color, KlimmeckGuideTheme.darkBronze);
      expect(chip.labelStyle, theme.bodyMedium);
    });
  });

  test('exposes the spacing scale', () {
    expect(KlimmeckGuideTheme.spacingXs, 4);
    expect(KlimmeckGuideTheme.spacingSm, 8);
    expect(KlimmeckGuideTheme.spacingMd, 16);
    expect(KlimmeckGuideTheme.spacingLg, 24);
    expect(KlimmeckGuideTheme.spacingXl, 32);
  });

  test('keeps the app bar unchanged', () {
    final appBar = theme.materialTheme.appBarTheme;
    expect(appBar.backgroundColor, KlimmeckGuideTheme.darkBronze);
    expect(appBar.foregroundColor, KlimmeckGuideTheme.primaryGold);
  });
}
