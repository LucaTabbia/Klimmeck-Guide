import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  group('teleportFailureTextOf (D-17)', () {
    test('no failure means no line', () {
      expect(teleportFailureTextOf(null), isNull);
    });

    test('a character on a quest has its own line', () {
      expect(
        teleportFailureTextOf(InnkeeperFailure.questInProgress),
        'Il personaggio è in una missione in corso',
      );
    });

    test('a missing character or place has its own line', () {
      expect(
        teleportFailureTextOf(InnkeeperFailure.notFound),
        'Personaggio o luogo non trovato',
      );
    });

    test('any other failure asks to retry', () {
      for (final failure in [
        InnkeeperFailure.connection,
        InnkeeperFailure.timedOut,
        InnkeeperFailure.unknown,
      ]) {
        expect(
          teleportFailureTextOf(failure),
          'Teletrasporto non riuscito, riprova',
        );
      }
    });
  });

  group('TeleportModeChip (D-16)', () {
    late int cancels;

    setUp(() => cancels = 0);

    Future<void> pumpChip(
      WidgetTester tester, {
      InnkeeperFailure? failure,
      bool isTeleporting = false,
    }) async {
      await tester.pumpWidget(
        buildTestApp(
          home: Material(
            child: Center(
              child: TeleportModeChip(
                characterName: 'Bea',
                failure: failure,
                isTeleporting: isTeleporting,
                onCancel: () => cancels++,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('invites to drag the character and offers Annulla', (
      tester,
    ) async {
      await pumpChip(tester);

      expect(find.text('Trascina Bea su una città'), findsOneWidget);
      expect(find.text('Annulla'), findsOneWidget);
    });

    testWidgets('tapping Annulla cancels', (tester) async {
      await pumpChip(tester);

      await tester.tap(find.byKey(TeleportModeChip.cancelKey));

      expect(cancels, 1);
    });

    testWidgets('the cancel target is at least 44 by 44', (tester) async {
      await pumpChip(tester);

      final size = tester.getSize(find.byKey(TeleportModeChip.cancelKey));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('reads in progress while teleporting', (tester) async {
      await pumpChip(tester, isTeleporting: true);

      expect(find.text('Teletrasporto in corso…'), findsOneWidget);
      expect(find.text('Trascina Bea su una città'), findsNothing);
    });

    testWidgets('shows the failure line in the error style', (tester) async {
      await pumpChip(tester, failure: InnkeeperFailure.questInProgress);

      final line = tester.widget<Text>(
        find.text('Il personaggio è in una missione in corso'),
      );
      expect(line.style, KlimmeckGuideTheme.instance.errorText);
    });

    testWidgets('uses no Material chrome', (tester) async {
      await pumpChip(tester, failure: InnkeeperFailure.unknown);

      expect(find.byType(Chip), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
