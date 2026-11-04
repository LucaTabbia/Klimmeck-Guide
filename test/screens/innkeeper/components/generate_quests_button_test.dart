import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/generate_quests_button.dart';

import '../../../helpers/test_app.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool isSubmitting,
    required VoidCallback onPressed,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: GenerateQuestsButton(
            isSubmitting: isSubmitting,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  testWidgets('reads «Genera missioni» and calls back on tap (D-08)', (
    tester,
  ) async {
    var taps = 0;
    await pumpButton(tester, isSubmitting: false, onPressed: () => taps++);

    expect(find.text(GenerateQuestsButton.label), findsOneWidget);
    expect(GenerateQuestsButton.label, 'Genera missioni');

    await tester.tap(find.byKey(GenerateQuestsButton.buttonKey));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('is disabled while submitting (D-09)', (tester) async {
    var taps = 0;
    await pumpButton(tester, isSubmitting: true, onPressed: () => taps++);

    final button = tester.widget<ElevatedButton>(
      find.byKey(GenerateQuestsButton.buttonKey),
    );
    expect(button.onPressed, isNull);

    await tester.tap(
      find.byKey(GenerateQuestsButton.buttonKey),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(taps, 0);
  });
}
