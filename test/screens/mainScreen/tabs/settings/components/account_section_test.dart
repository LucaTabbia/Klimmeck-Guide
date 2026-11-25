import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/account_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/auth_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late MockAuthCubit authCubit;
  late MockCharacterDeletionCubit deletionCubit;
  late MockAccountDeletionCubit accountDeletionCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    deletionCubit = MockCharacterDeletionCubit();
    accountDeletionCubit = MockAccountDeletionCubit();
    when(() => deletionCubit.isClosed).thenReturn(false);
    when(() => deletionCubit.deleteCharacter()).thenAnswer((_) async {});
    when(() => accountDeletionCubit.isClosed).thenReturn(false);
    when(() => accountDeletionCubit.deleteAccount()).thenAnswer((_) async {});
    when(() => authCubit.logout()).thenAnswer((_) async {});
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    String? characterName = 'Aldo',
    CharacterDeletionState state = const CharacterDeletionState(),
    AccountDeletionState accountDeletionState = const AccountDeletionState(),
    RoleType role = RoleType.adventurer,
  }) async {
    useLandscapePhone(tester);
    whenListen(
      deletionCubit,
      const Stream<CharacterDeletionState>.empty(),
      initialState: state,
    );
    whenListen(
      accountDeletionCubit,
      const Stream<AccountDeletionState>.empty(),
      initialState: accountDeletionState,
    );
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUser(role: role),
        accessToken: testAccessToken,
      ),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<CharacterDeletionCubit>.value(value: deletionCubit),
              BlocProvider<AccountDeletionCubit>.value(
                value: accountDeletionCubit,
              ),
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
  final characterButton = find.byType(OutlinedButton).first;
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
      tester.widget<OutlinedButton>(characterButton).style,
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

  testWidgets('confirming after the cubit was closed does not delete', (
    tester,
  ) async {
    await pumpSection(tester);

    await tester.tap(find.text(deleteLabel));
    await tester.pumpAndSettle();
    when(() => deletionCubit.isClosed).thenReturn(true);
    await tester.tap(dialogConfirmDelete);
    await tester.pumpAndSettle();

    verifyNever(() => deletionCubit.deleteCharacter());
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

    final button = tester.widget<OutlinedButton>(characterButton);
    expect(button.onPressed, isNull);
    expect(
      find.descendant(
        of: characterButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text(deleteLabel), findsNothing);
    await tester.tap(characterButton, warnIfMissed: false);
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
  group('Elimina account', () {
    const accountLabel = 'Elimina account';
    final accountButton = find.widgetWithText(OutlinedButton, accountLabel);

    Future<void> openDialog(WidgetTester tester) async {
      await pumpSection(tester);
      await tester.tap(find.text(accountLabel));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Elimina account is the last button, under Esci, detached, red outline '
      '(D-02)',
      (tester) async {
        await pumpSection(tester);

        final characterTop = tester.getTopLeft(find.text(deleteLabel)).dy;
        final logout = find.widgetWithText(ElevatedButton, 'Esci');
        final logoutTop = tester.getTopLeft(logout).dy;
        final accountTop = tester.getTopLeft(accountButton).dy;
        expect(logoutTop, greaterThan(characterTop));
        expect(accountTop, greaterThan(logoutTop));
        expect(
          accountTop - tester.getBottomLeft(logout).dy,
          greaterThanOrEqualTo(KlimmeckGuideTheme.spacingLg),
        );
        expect(
          tester.widget<OutlinedButton>(accountButton).style,
          KlimmeckGuideTheme.destructiveOutlinedButtonStyle,
        );
      },
    );

    testWidgets('the innkeeper sees no Elimina account (D-16)', (tester) async {
      await pumpSection(tester, role: RoleType.innkeeper);

      expect(find.text(accountLabel), findsNothing);
      expect(find.text('Esci'), findsOneWidget);
    });

    testWidgets('Annulla deletes nothing (D-01)', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => accountDeletionCubit.deleteAccount());
    });

    testWidgets('Elimina deletes once (D-01)', (tester) async {
      await openDialog(tester);

      await tester.tap(dialogConfirmDelete);
      await tester.pumpAndSettle();

      verify(() => accountDeletionCubit.deleteAccount()).called(1);
      verifyNever(() => deletionCubit.deleteCharacter());
    });

    testWidgets(
      'the dialog lists what is lost and that channel points are not given '
      'back (D-05)',
      (tester) async {
        await openDialog(tester);

        final dialog = find.byType(AlertDialog);
        Finder inDialog(String text) =>
            find.descendant(of: dialog, matching: find.textContaining(text));
        expect(inDialog("Eliminare l'account?"), findsOneWidget);
        expect(inDialog('anche quelli archiviati'), findsOneWidget);
        expect(inDialog('il saldo dei punti'), findsOneWidget);
        expect(inDialog('il ritratto'), findsOneWidget);
        expect(inDialog('non verranno restituiti'), findsOneWidget);
      },
    );

    testWidgets(
      'while deleting the button shows a spinner and cannot be tapped again '
      '(D-06)',
      (tester) async {
        await pumpSection(
          tester,
          accountDeletionState: const AccountDeletionState(isDeleting: true),
        );

        final button = find.byType(OutlinedButton).last;
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
        expect(
          find.descendant(
            of: button,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(find.text(accountLabel), findsNothing);
        expect(find.text(deleteLabel), findsOneWidget);
        await tester.tap(button, warnIfMissed: false);
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'while the account deletion runs Esci and Elimina personaggio are '
      'inert: no logout can race the deletion (D-06, WR-01)',
      (tester) async {
        await pumpSection(
          tester,
          accountDeletionState: const AccountDeletionState(isDeleting: true),
        );

        final logout = find.widgetWithText(ElevatedButton, 'Esci');
        expect(tester.widget<ElevatedButton>(logout).onPressed, isNull);
        expect(
          tester.widget<OutlinedButton>(characterButton).onPressed,
          isNull,
        );
        expect(find.text(deleteLabel), findsOneWidget);

        await tester.tap(logout, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(characterButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        verifyNever(() => authCubit.logout());
        verifyNever(() => deletionCubit.deleteCharacter());
      },
    );

    testWidgets('a failure reads under the button (D-06)', (tester) async {
      await pumpSection(
        tester,
        accountDeletionState: const AccountDeletionState(
          failure: AccountDeletionFailure.innkeeperProtected,
        ),
      );

      final failure = find.text(
        "L'oste non può eliminare il proprio account dall'App",
      );
      expect(failure, findsOneWidget);
      expect(
        tester.getTopLeft(failure).dy,
        greaterThan(tester.getTopLeft(accountButton).dy),
      );
    });
  });
}
