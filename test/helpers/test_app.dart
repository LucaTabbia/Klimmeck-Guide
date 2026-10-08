import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// App minimale con il tema reale per i widget test.
///
/// Disattiva il download dei font Google a runtime: nei test non c'è rete e i font
/// non sono bundled, quindi il testo usa il fallback senza tentare richieste HTTP.
Widget buildTestApp({required Widget home}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return MaterialApp(
    theme: KlimmeckGuideTheme.instance.materialTheme,
    home: home,
  );
}
