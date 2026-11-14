import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';

import '../../../helpers/test_app.dart';

void main() {
  late List<int> changes;

  setUp(() => changes = []);

  Future<void> pumpStepper(WidgetTester tester, QuantityStepper stepper) =>
      tester.pumpWidget(buildTestApp(home: Scaffold(body: stepper)));

  VoidCallback? onPressedOf(WidgetTester tester, String tooltip) => tester
      .widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      )
      .onPressed;

  testWidgets('min defaults to 0 (Phase 10 D-12)', (tester) async {
    await pumpStepper(
      tester,
      QuantityStepper(
        label: 'Pozione',
        value: 1,
        max: 3,
        onChanged: changes.add,
      ),
    );

    await tester.tap(find.byTooltip('Diminuisci'));
    await tester.pump();

    expect(changes, [0]);
  });

  testWidgets('at min the minus is disabled (D-15)', (tester) async {
    await pumpStepper(
      tester,
      QuantityStepper(
        label: '',
        value: 1,
        min: 1,
        max: 99,
        onChanged: changes.add,
      ),
    );

    expect(onPressedOf(tester, 'Diminuisci'), isNull);
    expect(onPressedOf(tester, 'Aumenta'), isNotNull);
  });

  testWidgets('at max the plus is disabled', (tester) async {
    await pumpStepper(
      tester,
      QuantityStepper(
        label: '',
        value: 99,
        min: 1,
        max: 99,
        onChanged: changes.add,
      ),
    );

    expect(onPressedOf(tester, 'Aumenta'), isNull);
    expect(onPressedOf(tester, 'Diminuisci'), isNotNull);
  });
}
