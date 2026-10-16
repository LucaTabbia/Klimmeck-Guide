import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

void main() {
  late KlimmeckGuideTheme theme;
  late InputDecorationThemeData input;
  late ChipThemeData chip;
  late SwitchThemeData switches;

  void init() {
    theme = KlimmeckGuideTheme.instance;
    input = theme.materialTheme.inputDecorationTheme;
    chip = theme.materialTheme.chipTheme;
    switches = theme.materialTheme.switchTheme;
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

  group('switchTheme', () {
    const on = <WidgetState>{WidgetState.selected};
    const off = <WidgetState>{};
    const disabled = <WidgetState>{WidgetState.disabled};
    const disabledOn = <WidgetState>{
      WidgetState.disabled,
      WidgetState.selected,
    };

    testWidgets('thumb is gold on, wood off, silver disabled', (tester) async {
      init();
      final thumb = switches.thumbColor!;
      expect(thumb.resolve(on), KlimmeckGuideTheme.primaryGold);
      expect(thumb.resolve(off), KlimmeckGuideTheme.darkWood);
      expect(thumb.resolve(disabled), KlimmeckGuideTheme.paleSilver);
      expect(thumb.resolve(disabledOn), KlimmeckGuideTheme.paleSilver);
    });

    testWidgets('track is bronze on, parchment otherwise', (tester) async {
      init();
      final track = switches.trackColor!;
      expect(track.resolve(on), KlimmeckGuideTheme.darkBronze);
      expect(track.resolve(off), KlimmeckGuideTheme.parchment);
      expect(track.resolve(disabled), KlimmeckGuideTheme.parchment);
    });

    testWidgets('track outline is bronze, silver when disabled', (
      tester,
    ) async {
      init();
      final outline = switches.trackOutlineColor!;
      expect(outline.resolve(on), KlimmeckGuideTheme.darkBronze);
      expect(outline.resolve(off), KlimmeckGuideTheme.darkBronze);
      expect(outline.resolve(disabled), KlimmeckGuideTheme.paleSilver);
    });
  });

  group('destructive button styles', () {
    const idle = <WidgetState>{};
    const disabled = <WidgetState>{WidgetState.disabled};

    testWidgets('filled style is bloodRed on parchment', (tester) async {
      init();
      final style = KlimmeckGuideTheme.destructiveButtonStyle;
      expect(style.backgroundColor!.resolve(idle), KlimmeckGuideTheme.bloodRed);
      expect(
        style.foregroundColor!.resolve(idle),
        KlimmeckGuideTheme.parchment,
      );
      expect(
        style.backgroundColor!.resolve(disabled),
        KlimmeckGuideTheme.bloodRed.withValues(alpha: 0.5),
      );
      expect(
        style.foregroundColor!.resolve(disabled),
        KlimmeckGuideTheme.parchment,
      );
    });

    testWidgets('outlined style is bloodRed, silver when disabled', (
      tester,
    ) async {
      init();
      final style = KlimmeckGuideTheme.destructiveOutlinedButtonStyle;
      expect(style.foregroundColor!.resolve(idle), KlimmeckGuideTheme.bloodRed);
      expect(style.side!.resolve(idle)!.color, KlimmeckGuideTheme.bloodRed);
      expect(
        style.side!.resolve(disabled)!.color,
        KlimmeckGuideTheme.paleSilver,
      );
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
