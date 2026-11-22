import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// I pezzi scritti in rosso sangue dentro il testo trovato da [text].
List<String> redLabelsOf(WidgetTester tester, Finder text) {
  final labels = <String>[];
  tester.widget<Text>(text).textSpan?.visitChildren((span) {
    if (span is TextSpan &&
        span.text != null &&
        span.style?.color == KlimmeckGuideTheme.bloodRed) {
      labels.add(span.text!);
    }
    return true;
  });
  return labels;
}
