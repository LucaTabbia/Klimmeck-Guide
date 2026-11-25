import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/player_account_deletion_messages.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

const double _landscapeHeight = 360;
const double _keyboardHeight = 200;
const double _devicePixelRatio = 3;

const Duration _routeTransition = Duration(seconds: 1);

void main() {
  late MockPlayerAccountDeletionCubit cubit;
  late StreamController<PlayerAccountDeletionState> states;

  setUp(() {
    cubit = MockPlayerAccountDeletionCubit();
    states = StreamController<PlayerAccountDeletionState>.broadcast();
    whenListen(
      cubit,
      states.stream,
      initialState: const PlayerAccountDeletionState(),
    );
    when(() => cubit.isClosed).thenReturn(false);
    when(() => cubit.deletePlayer(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await states.close();
  });

  Finder inDialog(Finder matching) => find.descendant(
    of: find.byType(PlayerAccountDeletionDialog),
    matching: matching,
  );

  Finder field() => find.byKey(PlayerAccountDeletionDialog.fieldKey);

  ElevatedButton nextButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(inDialog(find.byType(ElevatedButton)));

  Future<void> openDialog(WidgetTester tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPlayerAccountDeletionDialog(context, cubit),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  Future<void> typeAndGoOn(WidgetTester tester, String text) async {
    await tester.enterText(field(), text);
    await tester.pump();
    await tester.tap(inDialog(find.text('Avanti')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the dialog asks the Twitch username with Avanti disabled while blank (D-15)',
    (tester) async {
      await openDialog(tester);

      verify(() => cubit.reset()).called(1);
      expect(inDialog(find.text('Elimina un account')), findsOneWidget);
      expect(inDialog(find.text('Nome utente Twitch')), findsOneWidget);
      expect(inDialog(find.text('Annulla')), findsOneWidget);
      expect(nextButton(tester).onPressed, isNull);

      await tester.enterText(field(), '   ');
      await tester.pump();
      expect(nextButton(tester).onPressed, isNull);

      await tester.enterText(field(), 'rossa_k');
      await tester.pump();
      expect(nextButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets('Annulla closes the dialog and deletes nothing', (tester) async {
    await openDialog(tester);

    await tester.tap(inDialog(find.text('Annulla')));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerAccountDeletionDialog), findsNothing);
    verifyNever(() => cubit.deletePlayer(any()));
  });

  testWidgets('Avanti opens the confirmation naming the username (D-15)', (
    tester,
  ) async {
    await openDialog(tester);

    await typeAndGoOn(tester, ' rossa_k ');

    expect(find.text("Eliminare l'account di rossa_k?"), findsOneWidget);
    expect(
      find.text(
        'Tutti i personaggi di rossa_k, anche quelli archiviati, il saldo dei '
        'punti e il ritratto andranno perduti per sempre. '
        "L'azione è irreversibile.",
      ),
      findsOneWidget,
    );
    expect(find.text('Elimina'), findsOneWidget);
  });

  testWidgets('Annulla in the confirmation deletes nothing', (tester) async {
    await openDialog(tester);
    await typeAndGoOn(tester, 'rossa_k');

    await tester.tap(find.text('Annulla').last);
    await tester.pumpAndSettle();

    verifyNever(() => cubit.deletePlayer(any()));
    expect(find.byType(PlayerAccountDeletionDialog), findsOneWidget);
    expect(find.text('rossa_k'), findsOneWidget);
  });

  testWidgets('Elimina deletes the trimmed username once (D-15)', (
    tester,
  ) async {
    await openDialog(tester);
    await typeAndGoOn(tester, '  rossa_k ');

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    verify(() => cubit.deletePlayer('rossa_k')).called(1);
  });

  testWidgets(
    'a refusal reads inside the dialog and keeps the text (D-15, D-16)',
    (tester) async {
      await openDialog(tester);
      await tester.enterText(field(), 'rossa_k');
      await tester.pump();

      for (final failure in PlayerAccountDeletionFailure.values) {
        states.add(PlayerAccountDeletionState(failure: failure));
        await tester.pump();

        final line = inDialog(find.text(failure.message));
        expect(line, findsOneWidget, reason: failure.name);
        expect(
          tester.getTopLeft(line).dy,
          greaterThan(tester.getTopLeft(field()).dy),
          reason: failure.name,
        );
        expect(
          tester.widget<TextField>(field()).controller?.text,
          'rossa_k',
          reason: failure.name,
        );
      }
      expect(nextButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets('a success closes the dialog (D-15)', (tester) async {
    await openDialog(tester);

    states.add(const PlayerAccountDeletionState(hasDeleted: true));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerAccountDeletionDialog), findsNothing);
  });

  testWidgets('while deleting Avanti shows a spinner and cannot be tapped', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.enterText(field(), 'rossa_k');
    await tester.pump();

    states.add(const PlayerAccountDeletionState(isDeleting: true));
    await tester.pump();

    expect(inDialog(find.byType(CircularProgressIndicator)), findsOneWidget);
    expect(inDialog(find.text('Avanti')), findsNothing);
    expect(nextButton(tester).onPressed, isNull);
  });

  group('while the deletion is in flight (WR-03)', () {
    final cancel = inDialog(find.widgetWithText(TextButton, 'Annulla'));

    Future<void> startDeleting(WidgetTester tester) async {
      await openDialog(tester);
      await tester.enterText(field(), 'rossa_k');
      await tester.pump();
      states.add(const PlayerAccountDeletionState(isDeleting: true));
      await tester.pump();
    }

    /// Annulla e il tasto indietro, poi il tempo perché un dialog chiuso esca
    /// davvero dall'albero.
    Future<void> tryToClose(WidgetTester tester) async {
      await tester.tap(cancel, warnIfMissed: false);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(_routeTransition);
      await tester.pump();
    }

    testWidgets('Annulla and the back button cannot close the dialog', (
      tester,
    ) async {
      await startDeleting(tester);

      expect(tester.widget<TextButton>(cancel).onPressed, isNull);
      await tryToClose(tester);

      expect(find.byType(PlayerAccountDeletionDialog), findsOneWidget);
    });

    testWidgets('a failure arriving reads in the still-open dialog', (
      tester,
    ) async {
      await startDeleting(tester);
      await tryToClose(tester);

      const failure = PlayerAccountDeletionFailure.twitchUnavailable;
      states.add(const PlayerAccountDeletionState(failure: failure));
      await tester.pump();

      expect(inDialog(find.text(failure.message)), findsOneWidget);
      expect(tester.widget<TextButton>(cancel).onPressed, isNotNull);
    });
  });

  testWidgets(
    'in landscape with the keyboard the field stays visible and nothing overflows (C5)',
    (tester) async {
      await openDialog(tester);
      tester.view.viewInsets = const FakeViewPadding(
        bottom: _keyboardHeight * _devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final rect = tester.getRect(field());
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(
        rect.bottom,
        lessThanOrEqualTo(_landscapeHeight - _keyboardHeight),
      );
      expect(field().hitTestable(), findsOneWidget);
    },
  );
}
