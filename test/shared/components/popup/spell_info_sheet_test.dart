import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/popup/spell_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/spell_info.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/spell_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

final _fireDart = Spell.fromJson(spellJson());

Future<void> _pump(
  WidgetTester tester, {
  bool isActive = false,
  bool isPending = false,
  VoidCallback? onToggle,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SpellInfoSheet(
            spell: _fireDart,
            usages: 1,
            recovery: const SpellRecoveryCountdown(remainingMinutes: 12),
            isActive: isActive,
            isPending: isPending,
            onToggle: onToggle,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BookmarkRibbon _ribbon(WidgetTester tester) =>
    tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));

Finder _insideRibbon(Type type) => find.descendant(
  of: find.byType(BookmarkRibbon),
  matching: find.byType(type),
);

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
      CloudinaryAssets.fireEnergy,
      CloudinaryAssets.attackUse,
    ]),
  );

  group('content', () {
    testWidgets('shows the card, the details and the ribbon', (tester) async {
      await _pump(tester, onToggle: () {});

      final card = tester.widget<SpellCard>(find.byType(SpellCard));
      expect(find.byType(SpellCard), findsOneWidget);
      expect(card.usages, isNull);
      expect(card.isMarked, isNull);
      expect(find.byType(SpellInfo), findsOneWidget);
      expect(find.text('Usi: 1/3 · prossimo tra 12 min'), findsOneWidget);
      expect(find.byType(BookmarkRibbon), findsOneWidget);
      expect(_ribbon(tester).isMarked, isFalse);
      expect(_ribbon(tester).left, 20);
    });

    testWidgets('has no app chrome', (tester) async {
      await _pump(tester, onToggle: () {});

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('toggle', () {
    testWidgets('tapping the ribbon toggles the spell once', (tester) async {
      var taps = 0;
      await _pump(tester, onToggle: () => taps++);

      await tester.tap(_insideRibbon(RotatedBox));

      expect(taps, 1);
    });

    testWidgets('an active spell has the ribbon marked', (tester) async {
      await _pump(tester, isActive: true, onToggle: () {});

      expect(_ribbon(tester).isMarked, isTrue);
    });

    testWidgets('a pending spell dims the ribbon', (tester) async {
      await _pump(tester, isPending: true, onToggle: () {});

      final ink = tester.widget<AnimatedOpacity>(
        _insideRibbon(AnimatedOpacity),
      );
      expect(ink.opacity, KlimmeckGuideTheme.pendingInkOpacity);
    });

    testWidgets('a settled spell keeps the ribbon fully inked', (tester) async {
      await _pump(tester, onToggle: () {});

      final ink = tester.widget<AnimatedOpacity>(
        _insideRibbon(AnimatedOpacity),
      );
      expect(ink.opacity, 1.0);
    });

    testWidgets('without onToggle the ribbon is inert', (tester) async {
      await _pump(tester);

      expect(_insideRibbon(GestureDetector), findsNothing);
      await tester.tap(_insideRibbon(RotatedBox));
      expect(tester.takeException(), isNull);
    });
  });
}
