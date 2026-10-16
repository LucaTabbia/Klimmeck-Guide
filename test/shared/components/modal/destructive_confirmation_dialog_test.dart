import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/test_app.dart';

void main() {
  bool? result;

  Future<void> openDialog(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDestructiveConfirmation(
              context,
              title: 'T',
              body: 'B',
              confirmLabel: 'Conferma',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows title, body and Annulla left of the confirm label', (
    tester,
  ) async {
    await openDialog(tester);

    expect(find.text('T'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    final cancel = tester.getTopLeft(find.text('Annulla'));
    final confirm = tester.getTopLeft(find.text('Conferma'));
    expect(cancel.dx, lessThan(confirm.dx));
  });

  testWidgets('tapping the barrier keeps the dialog open', (tester) async {
    await openDialog(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('T'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('Annulla closes and completes with false', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(find.text('T'), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('the confirm label closes and completes with true', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(find.text('T'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('the confirm button uses the destructive theme style', (
    tester,
  ) async {
    await openDialog(tester);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.style, KlimmeckGuideTheme.destructiveButtonStyle);
  });
}
