import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/modal/delete_character_confirmation_dialog.dart';

import '../../../helpers/test_app.dart';

void main() {
  bool? result;

  Future<void> openDialog(WidgetTester tester, {String? characterName}) async {
    result = null;
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showDeleteCharacterConfirmation(
                  context,
                  characterName: characterName,
                ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('names the character and warns it is irreversible', (
    tester,
  ) async {
    await openDialog(tester, characterName: 'Aldo');

    expect(find.text('Eliminare il personaggio?'), findsOneWidget);
    expect(
      find.text(
        "Sei sicuro di voler eliminare Aldo? L'azione è irreversibile.",
      ),
      findsOneWidget,
    );
    expect(find.text('Annulla'), findsOneWidget);
    expect(find.text('Elimina'), findsOneWidget);
  });

  testWidgets('falls back to a generic body without a name', (tester) async {
    await openDialog(tester);

    expect(
      find.text(
        "Sei sicuro di voler eliminare il tuo personaggio? "
        "L'azione è irreversibile.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('Elimina completes with true', (tester) async {
    await openDialog(tester, characterName: 'Aldo');

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('Annulla completes with false', (tester) async {
    await openDialog(tester, characterName: 'Aldo');

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
