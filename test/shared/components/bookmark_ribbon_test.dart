import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

const _stackKey = Key('ribbon-stack');

Future<void> _pumpRibbon(
  WidgetTester tester, {
  required bool isMarked,
  double? width,
  double? opacity,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: _stackKey,
            height: 200,
            width: 200,
            child: Stack(
              children: [
                if (opacity == null)
                  BookmarkRibbon(
                    isMarked: isMarked,
                    length: 40,
                    peek: 20,
                    width: width,
                    onTap: onTap,
                  )
                else
                  BookmarkRibbon(
                    isMarked: isMarked,
                    length: 40,
                    peek: 20,
                    width: width,
                    opacity: opacity,
                    onTap: onTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

AnimatedPositioned _positioned(WidgetTester tester) =>
    tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));

double _renderedTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(RotatedBox)).dy -
    tester.getTopLeft(find.byKey(_stackKey)).dy;

Finder _insideRibbon(Type type) => find.descendant(
  of: find.byType(BookmarkRibbon),
  matching: find.byType(type),
);

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.bookmarkRed]));

  group('BookmarkRibbon', () {
    testWidgets('a marked ribbon is fully visible', (tester) async {
      await _pumpRibbon(tester, isMarked: true);
      await tester.pumpAndSettle();

      expect(_positioned(tester).top, 0);
      expect(_positioned(tester).left, 5);
    });

    testWidgets('an unmarked ribbon only peeks out', (tester) async {
      await _pumpRibbon(tester, isMarked: false);
      await tester.pumpAndSettle();

      expect(_positioned(tester).top, -20);
      expect(_renderedTop(tester), -20);
    });

    testWidgets('marking the ribbon slides it down', (tester) async {
      await _pumpRibbon(tester, isMarked: false);
      await tester.pumpAndSettle();

      await _pumpRibbon(tester, isMarked: true);
      await tester.pump(const Duration(milliseconds: 150));

      final top = _renderedTop(tester);
      expect(top, greaterThan(-20));
      expect(top, lessThan(0));

      await tester.pumpAndSettle();
      expect(_renderedTop(tester), 0);
    });

    testWidgets('with onTap the ribbon is a toggle', (tester) async {
      var taps = 0;
      await _pumpRibbon(tester, isMarked: true, onTap: () => taps++);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RotatedBox));

      expect(taps, 1);
    });

    testWidgets('without onTap the ribbon has no gesture detector', (
      tester,
    ) async {
      await _pumpRibbon(tester, isMarked: true);

      expect(_insideRibbon(GestureDetector), findsNothing);
    });

    testWidgets('without width the svg keeps its natural proportions', (
      tester,
    ) async {
      await _pumpRibbon(tester, isMarked: true);

      final svg = tester.widget<CachedSvg>(_insideRibbon(CachedSvg));
      expect(svg.height, 40);
      expect(svg.width, isNull);
    });

    testWidgets('with width the svg is boxed in length x width', (
      tester,
    ) async {
      await _pumpRibbon(tester, isMarked: true, width: 40);

      final svg = tester.widget<CachedSvg>(_insideRibbon(CachedSvg));
      final box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: _insideRibbon(CachedSvg),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(svg.height, isNull);
      expect(box.height, 40);
      expect(box.width, 40);
    });
  });

  group('BookmarkRibbon opacity', () {
    testWidgets('default opacity is 1', (tester) async {
      await _pumpRibbon(tester, isMarked: true);

      final ribbon = tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));
      final ink = tester.widget<AnimatedOpacity>(
        _insideRibbon(AnimatedOpacity),
      );
      expect(ribbon.opacity, 1);
      expect(ink.opacity, 1);
    });

    testWidgets('a pending opacity fades the ribbon with the pending ink', (
      tester,
    ) async {
      await _pumpRibbon(tester, isMarked: true, opacity: 0.5);

      expect(_insideRibbon(AnimatedOpacity), findsOneWidget);
      final ink = tester.widget<AnimatedOpacity>(
        _insideRibbon(AnimatedOpacity),
      );
      expect(ink.opacity, 0.5);
      expect(ink.duration, KlimmeckGuideTheme.pendingInkDuration);
    });
  });

  group('CardBookmark', () {
    testWidgets('sizes the ribbon on the card', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  children: [CardBookmark(isMarked: true, cardSize: 120)],
                ),
              ),
            ),
          ),
        ),
      );

      final ribbon = tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));
      expect(find.byType(BookmarkRibbon), findsOneWidget);
      expect(ribbon.isMarked, isTrue);
      expect(ribbon.length, 120 / 2.5);
      expect(ribbon.width, 120 / 2.5);
      expect(ribbon.peek, 20);
      expect(ribbon.curve, Curves.easeInOut);
    });
  });
}
