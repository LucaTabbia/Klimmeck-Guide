import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../helpers/test_app.dart';

Future<void> _pump(
  WidgetTester tester,
  HpDeltaBar bar, {
  double width = 300,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: bar),
        ),
      ),
    ),
  );
}

FractionallySizedBox _fill(WidgetTester tester) =>
    tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byKey(HpDeltaBar.barKey),
        matching: find.byType(FractionallySizedBox),
      ),
    );

Color? _fillColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(FractionallySizedBox),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color;
}

Color? _valueColor(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(HpDeltaBar.valueKey)).style?.color;

void main() {
  testWidgets('a loss shows the value and the fraction in blood red', (
    tester,
  ) async {
    await _pump(tester, const HpDeltaBar(hp: 640, max: 1200, isLoss: true));

    expect(find.text('640 / 1200'), findsOneWidget);
    expect(_fill(tester).widthFactor, closeTo(640 / 1200, 1e-9));
    expect(_fillColor(tester), KlimmeckGuideTheme.bloodRed);
    expect(_valueColor(tester), KlimmeckGuideTheme.bloodRed);
  });

  testWidgets('a gain uses the heal ink', (tester) async {
    await _pump(tester, const HpDeltaBar(hp: 1200, max: 1200, isGain: true));

    expect(_fillColor(tester), KlimmeckGuideTheme.healGreen);
    expect(_valueColor(tester), KlimmeckGuideTheme.healGreen);
  });

  testWidgets('neither loss nor gain uses the neutral ink', (tester) async {
    await _pump(tester, const HpDeltaBar(hp: 300, max: 1200));

    expect(_fillColor(tester), KlimmeckGuideTheme.darkWood);
    expect(_valueColor(tester), KlimmeckGuideTheme.darkWood);
  });

  testWidgets('rounds the displayed value', (tester) async {
    await _pump(tester, const HpDeltaBar(hp: 639.6, max: 1200));

    expect(find.text('640 / 1200'), findsOneWidget);
  });

  testWidgets('a zero maximum renders an empty bar', (tester) async {
    await _pump(tester, const HpDeltaBar(hp: 10, max: 0));

    expect(tester.takeException(), isNull);
    expect(_fill(tester).widthFactor, 0);
  });

  testWidgets('clamps the fraction to the track', (tester) async {
    await _pump(tester, const HpDeltaBar(hp: 1500, max: 1200));
    expect(_fill(tester).widthFactor, 1);

    await _pump(tester, const HpDeltaBar(hp: -5, max: 1200));
    expect(_fill(tester).widthFactor, 0);
  });

  testWidgets('in a narrow strip the numbers stay on one line and shrink', (
    tester,
  ) async {
    await _pump(tester, const HpDeltaBar(hp: 31515, max: 40000));
    final oneLine = tester.getSize(find.byKey(HpDeltaBar.valueKey)).height;

    await _pump(tester, const HpDeltaBar(hp: 31515, max: 40000), width: 80);

    final value = tester.getRect(find.byKey(HpDeltaBar.valueKey));
    expect(value.height, lessThanOrEqualTo(oneLine));
    expect(value.width, lessThanOrEqualTo(80));
  });
}
