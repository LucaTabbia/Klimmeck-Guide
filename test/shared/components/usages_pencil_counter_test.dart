import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/pencil_text.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';
import 'package:klimmeck_guide/shared/components/written_ink.dart';

import '../../helpers/test_app.dart';

Future<void> _pump(WidgetTester tester, int? value) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(child: UsagesPencilCounter(value: value)),
      ),
    ),
  );
}

/// Parte visibile del numero [text], come rettangolo dentro il suo riquadro.
Rect _visibleInkOf(WidgetTester tester, String text) {
  final clip = find.ancestor(
    of: find.text(text),
    matching: find.byKey(WrittenInk.clipKey),
  );
  final box = tester.getSize(clip);
  return tester.widget<ClipRect>(clip).clipper!.getClip(box);
}

void main() {
  testWidgets('shows the value through one keyed pencil text', (tester) async {
    await _pump(tester, 3);

    final text = tester.widget<PencilText>(find.byType(PencilText));
    expect(text.text, '3');
    expect(text.key, const ValueKey<int>(3));
  });

  testWidgets('no value shows nothing', (tester) async {
    await _pump(tester, null);

    expect(find.byType(PencilText), findsNothing);
  });

  testWidgets('the stroke is quick', (tester) async {
    expect(
      UsagesPencilCounter.strokeDuration,
      lessThanOrEqualTo(const Duration(milliseconds: 200)),
    );
  });

  testWidgets(
    'a new value replaces the old one at once and is written from left to '
    'right',
    (tester) async {
      await _pump(tester, 3);
      await tester.pumpAndSettle();

      await _pump(tester, 2);
      await tester.pump(UsagesPencilCounter.strokeDuration ~/ 2);

      expect(find.text('3'), findsNothing);
      final writingNew = _visibleInkOf(tester, '2');
      expect(writingNew.left, 0);
      expect(writingNew.right, greaterThan(0));

      await tester.pumpAndSettle();
      expect(tester.widget<PencilText>(find.byType(PencilText)).text, '2');
    },
  );

  testWidgets('quick changes always leave a number in sight', (tester) async {
    await _pump(tester, 1);
    await tester.pumpAndSettle();

    for (final value in [2, 3, 4, 5]) {
      await _pump(tester, value);
      await tester.pump(const Duration(milliseconds: 40));
      expect(_visibleInkOf(tester, '$value').width, greaterThan(0));
    }
  });

  testWidgets('the ink leaves room for the strokes beyond the digits', (
    tester,
  ) async {
    await _pump(tester, 128);
    await tester.pumpAndSettle();

    final clip = tester.getRect(find.byKey(WrittenInk.clipKey));
    final digits = tester.getRect(find.text('128'));
    expect(clip.right, greaterThan(digits.right));
    expect(clip.left, lessThan(digits.left));
  });

  testWidgets('the first value is written, the last one wiped', (tester) async {
    await _pump(tester, null);

    await _pump(tester, 1);
    await tester.pump(UsagesPencilCounter.strokeDuration * 0.75);
    expect(_visibleInkOf(tester, '1').left, 0);
    await tester.pumpAndSettle();

    await _pump(tester, null);
    await tester.pump(UsagesPencilCounter.strokeDuration * 0.25);
    expect(_visibleInkOf(tester, '1').left, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.byType(PencilText), findsNothing);
  });
}
