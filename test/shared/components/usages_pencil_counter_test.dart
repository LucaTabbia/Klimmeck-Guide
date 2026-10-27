import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/animated_pencil_text.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';

import '../../helpers/test_app.dart';

Future<void> _pump(WidgetTester tester, int value) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(child: UsagesPencilCounter(value: value)),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the value through one keyed pencil text', (tester) async {
    await _pump(tester, 3);

    final text = tester.widget<AnimatedPencilText>(
      find.byType(AnimatedPencilText),
    );
    expect(text.text, '3');
    expect(text.key, const ValueKey<int>(3));
  });

  testWidgets('a new value replaces the old pencil text', (tester) async {
    await _pump(tester, 3);
    await tester.pumpAndSettle();

    await _pump(tester, 2);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<int>(3)), findsNothing);
    final text = tester.widget<AnimatedPencilText>(
      find.byType(AnimatedPencilText),
    );
    expect(text.key, const ValueKey<int>(2));
    expect(text.text, '2');
  });
}
