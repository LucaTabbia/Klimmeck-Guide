import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

void main() {
  late KlimmeckGuideTheme theme;
  late InputDecorationThemeData input;
  late ChipThemeData chip;

  void init() {
    theme = KlimmeckGuideTheme.instance;
    input = theme.materialTheme.inputDecorationTheme;
    chip = theme.materialTheme.chipTheme;
  }

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('inputDecorationTheme', () {
    testWidgets('is a filled parchment sheet', (tester) async {
      init();
      expect(input.filled, isTrue);
      expect(input.fillColor, KlimmeckGuideTheme.parchment);
    });

    testWidgets('renders errors with the project errorText style', (
      tester,
    ) async {
      init();
      expect(input.errorStyle, theme.errorText);
    });

    testWidgets('colors the borders by state', (tester) async {
      init();
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
    testWidgets('uses gold when selected and parchment otherwise', (
      tester,
    ) async {
      init();
      expect(chip.selectedColor, KlimmeckGuideTheme.primaryGold);
      expect(chip.backgroundColor, KlimmeckGuideTheme.parchment);
      expect(chip.checkmarkColor, KlimmeckGuideTheme.deepNight);
    });

    testWidgets('has a bronze border and the body label style', (tester) async {
      init();
      expect(chip.side?.color, KlimmeckGuideTheme.darkBronze);
      expect(chip.labelStyle, theme.bodyMedium);
    });
  });

  testWidgets('exposes the spacing scale', (tester) async {
    init();
    expect(KlimmeckGuideTheme.spacingXs, 4);
    expect(KlimmeckGuideTheme.spacingSm, 8);
    expect(KlimmeckGuideTheme.spacingMd, 16);
    expect(KlimmeckGuideTheme.spacingLg, 24);
    expect(KlimmeckGuideTheme.spacingXl, 32);
  });

  testWidgets('keeps the app bar unchanged', (tester) async {
    init();
    final appBar = theme.materialTheme.appBarTheme;
    expect(appBar.backgroundColor, KlimmeckGuideTheme.darkBronze);
    expect(appBar.foregroundColor, KlimmeckGuideTheme.primaryGold);
  });
}
