import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// I pezzi scritti in rosso sangue dentro il testo trovato da [text].
List<String> redLabelsOf(WidgetTester tester, Finder text) =>
    inkedLabelsOf(tester, text, KlimmeckGuideTheme.bloodRed);

/// I pezzi scritti in verde cura dentro il testo trovato da [text].
List<String> greenLabelsOf(WidgetTester tester, Finder text) =>
    inkedLabelsOf(tester, text, KlimmeckGuideTheme.healGreen);

/// I pezzi scritti con l'inchiostro [ink] dentro il testo trovato da [text].
List<String> inkedLabelsOf(WidgetTester tester, Finder text, Color ink) {
  final labels = <String>[];
  tester.widget<Text>(text).textSpan?.visitChildren((span) {
    if (span is TextSpan && span.text != null && span.style?.color == ink) {
      labels.add(span.text!);
    }
    return true;
  });
  return labels;
}
