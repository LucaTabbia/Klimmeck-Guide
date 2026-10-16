import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/account_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late MockAuthCubit authCubit;
  late MockCharacterDeletionCubit deletionCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    deletionCubit = MockCharacterDeletionCubit();
    when(() => deletionCubit.deleteCharacter()).thenAnswer((_) async {});
    when(() => authCubit.logout()).thenAnswer((_) async {});
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    String? characterName = 'Aldo',
    CharacterDeletionState state = const CharacterDeletionState(),
  }) async {
    useLandscapePhone(tester);
    whenListen(
      deletionCubit,
      const Stream<CharacterDeletionState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<CharacterDeletionCubit>.value(value: deletionCubit),
            ],
            child: SingleChildScrollView(
              child: AccountSection(characterName: characterName),
            ),
          ),
        ),
      ),
    );
  }

  const deleteLabel = 'Elimina personaggio';
  final dialogConfirmDelete = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text('Elimina'),
  );

  testWidgets('renders Account with deletion above logout, both themed', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('Account'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Esci')).dy,
      greaterThan(tester.getTopLeft(find.text(deleteLabel)).dy),
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style,
      KlimmeckGuideTheme.destructiveOutlinedButtonStyle,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).style,
      KlimmeckGuideTheme.destructiveButtonStyle,
    );
  });

  testWidgets('cancelling the confirmation does not delete', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text(deleteLabel));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Sei sicuro di voler eliminare Aldo? L'azione è irreversibile.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => deletionCubit.deleteCharacter());
  });

  testWidgets('confirming deletes exactly once', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text(deleteLabel));
    await tester.pumpAndSettle();
    await tester.tap(dialogConfirmDelete);
    await tester.pumpAndSettle();

    verify(() => deletionCubit.deleteCharacter()).called(1);
  });

  testWidgets('falls back to a generic name when the name is unknown', (
    tester,
  ) async {
    await pumpSection(tester, characterName: null);

    await tester.tap(find.text(deleteLabel));
    await tester.pumpAndSettle();

    expect(find.textContaining('il tuo personaggio'), findsOneWidget);
  });

  testWidgets('while deleting the button is disabled with a progress', (
    tester,
  ) async {
    await pumpSection(
      tester,
      state: const CharacterDeletionState(isDeleting: true),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text(deleteLabel), findsNothing);
    await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
  });

  group('inline failure copy', () {
    const connection = 'Errore di connessione, riprova';
    const handover =
        'Personaggio eliminato, ma la sessione non si è aggiornata: esci e rientra';
    const generic = 'Impossibile eliminare il personaggio, riprova';

    final cases = {
      CharacterDeletionFailure.connection: connection,
      CharacterDeletionFailure.handoverRejected: handover,
      CharacterDeletionFailure.unknown: generic,
      CharacterDeletionFailure.unauthenticated: generic,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key.name} shows its domain message', (tester) async {
        await pumpSection(
          tester,
          state: CharacterDeletionState(failure: entry.key),
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('no failure shows none of them', (tester) async {
      await pumpSection(tester);

      expect(find.text(connection), findsNothing);
      expect(find.text(handover), findsNothing);
      expect(find.text(generic), findsNothing);
    });
  });

  testWidgets('Esci logs out only after the dialog confirmation', (
    tester,
  ) async {
    await pumpSection(tester);

    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();
    expect(find.text('Sei sicuro di voler uscire?'), findsOneWidget);
    verifyNever(() => authCubit.logout());

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Esci'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => authCubit.logout()).called(1);
  });
}
