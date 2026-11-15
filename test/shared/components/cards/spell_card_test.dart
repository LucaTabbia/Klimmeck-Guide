import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/spell_origin.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/shared/components/animated_pencil_text.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/spell_fixtures.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

Future<void> _pump(
  WidgetTester tester,
  Spell spell, {
  bool? isMarked,
  int? usages,
  double size = 120,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(
          child: SpellCard(
            spell: spell,
            size: size,
            isMarked: isMarked,
            usages: usages,
          ),
        ),
      ),
    ),
  );
}

final _fireDart = Spell.fromJson(spellJson());

List<CachedSvg> _icons(WidgetTester tester) => tester
    .widgetList<CachedSvg>(find.byType(CachedSvg))
    .where(
      (svg) => svg.url != CloudinaryAssets.url(CloudinaryAssets.emptyCardSheet),
    )
    .toList();

BookmarkRibbon _ribbon(WidgetTester tester) =>
    tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
      CloudinaryAssets.fireEnergy,
      CloudinaryAssets.attackUse,
      CloudinaryAssets.arcaneOrigin,
      CloudinaryAssets.shamanicOrigin,
      CloudinaryAssets.voidOrigin,
    ]),
  );

  group('origin', () {
    testWidgets(
      'the origin icon is drawn first, before use and energy (D-01, D-05)',
      (tester) async {
        await _pump(tester, Spell.fromJson(spellJson(origin: 'void')));

        final urls = tester
            .widgetList<CachedSvg>(find.byType(CachedSvg))
            .map((svg) => svg.url)
            .toList();
        expect(urls, [
          CloudinaryAssets.url(CloudinaryAssets.emptyCardSheet),
          SpellOrigin.theVoid.imagePath,
          CloudinaryAssets.url(CloudinaryAssets.attackUse),
          CloudinaryAssets.url(CloudinaryAssets.fireEnergy),
        ]);
      },
    );

    testWidgets('three icons shrink to fit the card (D-05, Pitfall 5)', (
      tester,
    ) async {
      await _pump(tester, Spell.fromJson(spellJson(origin: 'void')));

      final icons = _icons(tester);
      expect(icons, hasLength(3));
      for (final icon in icons) {
        expect(icon.width, 120 / 3.2);
        expect(icon.height, 120 / 3.2);
      }
    });

    testWidgets(
      'three icons never overflow the smallest card in use (D-05, Pitfall 5)',
      (tester) async {
        await _pump(
          tester,
          Spell.fromJson(spellJson(origin: 'shamanic')),
          size: 48,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Dardo di fuoco'), findsOneWidget);
      },
    );

    testWidgets(
      'a spell without origin keeps its two icons at today\'s size (D-05)',
      (tester) async {
        await _pump(tester, _fireDart);

        final icons = _icons(tester);
        expect(icons, hasLength(2));
        for (final icon in icons) {
          expect(icon.width, 120 / 2.5);
          expect(icon.height, 120 / 2.5);
        }
        final originUrls = SpellOrigin.values.map((origin) => origin.imagePath);
        expect(
          icons.map((icon) => icon.url),
          isNot(anyElement(isIn(originUrls))),
        );
      },
    );

    testWidgets('an origin with one other icon keeps today\'s size (D-05)', (
      tester,
    ) async {
      await _pump(
        tester,
        Spell.fromJson(spellJson(origin: 'arcane', energy: null)),
      );

      final icons = _icons(tester);
      expect(icons.map((icon) => icon.url), [
        SpellOrigin.arcane.imagePath,
        CloudinaryAssets.url(CloudinaryAssets.attackUse),
      ]);
      for (final icon in icons) {
        expect(icon.width, 120 / 2.5);
      }
    });
  });

  group('content', () {
    testWidgets('shows name and power, no bookmark and no counter', (
      tester,
    ) async {
      await _pump(tester, _fireDart);

      expect(find.text('Dardo di fuoco'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byType(BookmarkRibbon), findsNothing);
      expect(find.byType(AnimatedPencilText), findsNothing);
    });

    testWidgets('a zero power is not shown', (tester) async {
      await _pump(tester, Spell.fromJson(spellJson(power: 0)));

      expect(find.text('0'), findsNothing);
    });

    testWidgets('a missing power is not shown', (tester) async {
      await _pump(tester, Spell.fromJson(spellJson(power: null)));

      expect(tester.takeException(), isNull);
      expect(find.text('Dardo di fuoco'), findsOneWidget);
      expect(find.text('null'), findsNothing);
    });

    testWidgets('a spell without use type and energy still renders', (
      tester,
    ) async {
      await _pump(
        tester,
        Spell.fromJson(spellJson(useType: null, energy: null)),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Dardo di fuoco'), findsOneWidget);
      expect(find.byType(CachedSvg), findsOneWidget);
    });
  });

  group('bookmark', () {
    testWidgets('an active spell is marked', (tester) async {
      await _pump(tester, _fireDart, isMarked: true);

      expect(find.byType(CardBookmark), findsOneWidget);
      expect(_ribbon(tester).isMarked, isTrue);
    });

    testWidgets('an inactive spell is not marked', (tester) async {
      await _pump(tester, _fireDart, isMarked: false);

      expect(_ribbon(tester).isMarked, isFalse);
    });

    testWidgets('without a mark state there is no bookmark', (tester) async {
      await _pump(tester, _fireDart);

      expect(find.byType(BookmarkRibbon), findsNothing);
    });
  });

  testWidgets('a slot card shows the usages counter', (tester) async {
    await _pump(tester, _fireDart, usages: 2);

    final counter = tester.widget<AnimatedPencilText>(
      find.byType(AnimatedPencilText),
    );
    expect(counter.text, '2');
    final shared = tester.widget<UsagesPencilCounter>(
      find.byType(UsagesPencilCounter),
    );
    expect(shared.value, 2);
  });

  test('pending ink tokens', () {
    expect(KlimmeckGuideTheme.pendingInkOpacity, 0.5);
    expect(
      KlimmeckGuideTheme.pendingInkDuration,
      const Duration(milliseconds: 200),
    );
  });
}
