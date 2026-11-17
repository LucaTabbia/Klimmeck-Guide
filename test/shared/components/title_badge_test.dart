import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/title_badge.dart';
import 'package:klimmeck_guide/shared/components/title_change.dart';

import '../../helpers/test_app.dart';
import '../../helpers/title_badge_finder.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    buildTestApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  CachedSvg imageOf(WidgetTester tester) =>
      tester.widget<CachedSvg>(find.byType(CachedSvg));

  testWidgets('draws the badge of its title as a square of the given size', (
    tester,
  ) async {
    await pump(tester, const TitleBadge(title: TitleType.mage, size: 40));

    final image = imageOf(tester);
    expect(image.url, TitleType.mage.badgePath);
    expect((image.width, image.height), (40, 40));
  });

  testWidgets('reads the name of the title to a screen reader', (tester) async {
    await pump(tester, const TitleBadge(title: TitleType.hero, size: 40));

    expect(
      tester.getSemantics(find.byType(TitleBadge)).label,
      TitleType.hero.label,
    );
  });

  testWidgets('a given semantic label replaces the name of the title', (
    tester,
  ) async {
    await pump(
      tester,
      const TitleBadge(
        title: TitleType.hero,
        size: 40,
        semanticLabel: 'Titolo minimo: Eroe',
      ),
    );

    expect(
      tester.getSemantics(find.byType(TitleBadge)).label,
      'Titolo minimo: Eroe',
    );
  });

  testWidgets(
    'a title change draws the old badge, an arrow and the new badge',
    (tester) async {
      await pump(
        tester,
        const TitleChange(
          before: TitleType.rookie,
          after: TitleType.adventurer,
        ),
      );

      final before = tester.getCenter(findTitleBadge(TitleType.rookie)).dx;
      final arrow = tester.getCenter(find.text('→')).dx;
      final after = tester.getCenter(findTitleBadge(TitleType.adventurer)).dx;
      expect(before, lessThan(arrow));
      expect(arrow, lessThan(after));
    },
  );
}
