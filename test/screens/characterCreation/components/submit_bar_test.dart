import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/submit_bar.dart';

import '../../../helpers/test_app.dart';

void main() {
  Widget build({
    bool canSubmit = true,
    bool isSubmitting = false,
    CharacterCreationFailure? failure,
    VoidCallback? onSubmit,
  }) => buildTestApp(
    home: Scaffold(
      body: SubmitBar(
        canSubmit: canSubmit,
        isSubmitting: isSubmitting,
        failure: failure,
        onSubmit: onSubmit ?? () {},
      ),
    ),
  );

  testWidgets('Crea is disabled when the sheet is not valid', (tester) async {
    await tester.pumpWidget(build(canSubmit: false));

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('tapping Crea submits when valid', (tester) async {
    var submitted = 0;
    await tester.pumpWidget(build(onSubmit: () => submitted++));

    await tester.tap(find.text('Crea'));

    expect(submitted, 1);
  });

  testWidgets('while submitting the button shows its own progress only', (
    tester,
  ) async {
    await tester.pumpWidget(build(isSubmitting: true));

    final button = find.byType(ElevatedButton);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    expect(
      find.descendant(
        of: button,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel('Creazione del personaggio in corso'),
      findsOneWidget,
    );
    expect(find.text('Crea'), findsNothing);
  });

  testWidgets('shows the submit failure notice', (tester) async {
    await tester.pumpWidget(build(failure: CharacterCreationFailure.nameTaken));

    expect(find.text('Nome già in uso'), findsOneWidget);
  });
}
