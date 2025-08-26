import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KlimmeckGuideTheme {
  static final KlimmeckGuideTheme instance = KlimmeckGuideTheme._();

  KlimmeckGuideTheme._() {
    _initTextTheme();
    _initShadow();
  }

  static const double radius = 15.0;
  static const double inputTextHeight = 42;
  static const double inputTextWidth = 250;
  static const List<Shadow> bordersForText = [
    Shadow(offset: Offset(-1, -1), color: deepNight),
    Shadow(offset: Offset(1, -1), color: deepNight),
    Shadow(offset: Offset(-1, 1), color: deepNight),
    Shadow(offset: Offset(1, 1), color: deepNight),
  ];

  // Colors
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color darkBronze = Color(0xFF8B6C00);
  static const Color royalCrimson = Color(0xFF8B0000);
  static const Color arcanePurple = Color(0xFF4B0082);
  static const Color parchment = Color(0xFFF5F1E3);
  static const Color deepNight = Color(0xFF1E1B18);
  static const Color mysticBlue = Color(0xFF4682B4);
  static const Color darkWood = Color(0xFF3E2C1C);
  static const Color paleSilver = Color(0xFFD4D4DC);
  static const Color bloodRed = Color(0xFF9B1C1C);

  // Color Scheme
  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryGold,
    onPrimary: deepNight,
    secondary: royalCrimson,
    onSecondary: parchment,
    error: bloodRed,
    onError: parchment,
    surface: paleSilver,
    onSurface: deepNight,
  );

  // TextStyles
  late final TextStyle headlineLarge;
  late final TextStyle titleMedium;
  late final TextStyle bodyLarge;
  late final TextStyle bodyMedium;
  late final TextStyle specialText;
  late final TextStyle lightText;
  late final TextStyle errorText;

  late final TextTheme textTheme;
  late final BoxShadow shadow;

  void _initTextTheme({Color? textColor}) {
    final base = textColor ?? deepNight;

    headlineLarge = GoogleFonts.cinzelDecorative(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: base,
    );

    titleMedium = GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.w600, color: base);

    bodyLarge = GoogleFonts.cormorantGaramond(
      fontSize: 22,
      fontWeight: FontWeight.w200,
      color: base,
    );

    bodyMedium = GoogleFonts.sourceSans3(fontSize: 16, fontWeight: FontWeight.w500, color: base);

    specialText = GoogleFonts.uncialAntiqua(fontSize: 30, fontWeight: FontWeight.w300, color: base);

    lightText = GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.w300, color: parchment);

    errorText = GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.w500, color: bloodRed);

    textTheme = TextTheme(
      headlineLarge: headlineLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelLarge: specialText,
      labelSmall: errorText,
    );
  }

  void _initShadow() {
    shadow = const BoxShadow(
      color: deepNight,
      spreadRadius: 25,
      blurRadius: 70,
      offset: Offset(0, 3),
    );
  }

  ThemeData get materialTheme => ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: parchment,
    appBarTheme: const AppBarTheme(backgroundColor: darkBronze, foregroundColor: primaryGold),
  );

  static BoxDecoration getBackgroundDecoration() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryGold, darkBronze, darkBronze],
    ),
  );

  static BoxDecoration getDarkDungeonBackground() => const BoxDecoration(
    gradient: LinearGradient(
      colors: [deepNight, darkWood],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration getParchmentBackground() => const BoxDecoration(color: parchment);

  static bool isDarkMode(BuildContext context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  Color getBackgroundColor(BuildContext context) => isDarkMode(context) ? deepNight : parchment;
}
