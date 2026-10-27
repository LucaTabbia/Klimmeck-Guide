import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

Future<List<UseType?>> _pump(
  WidgetTester tester, {
  List<UseType> values = const [UseType.defense, UseType.attack],
}) async {
  final taps = <UseType?>[];
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: ItemsFilter<UseType>(
          values: values,
          current: null,
          onTap: taps.add,
          getImage: (useType) => useType.imagePath,
        ),
      ),
    ),
  );
  await tester.pump();
  return taps;
}

Finder _chip(UseType useType) => find.byWidgetPredicate(
  (widget) => widget is CachedSvg && widget.url == useType.imagePath,
);

void main() {
  setUp(
    () =>
        seedSvgCache([CloudinaryAssets.attackUse, CloudinaryAssets.defenseUse]),
  );

  testWidgets('shows «Tutti» and one chip per value in order', (tester) async {
    await _pump(tester);

    expect(find.text('Tutti'), findsOneWidget);
    final urls = tester
        .widgetList<CachedSvg>(find.byType(CachedSvg))
        .map((svg) => svg.url)
        .toList();
    expect(urls, [UseType.defense.imagePath, UseType.attack.imagePath]);
  });

  testWidgets('a chip reports its value, «Tutti» reports null', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(_chip(UseType.attack));
    expect(taps, [UseType.attack]);

    await tester.tap(find.text('Tutti'));
    expect(taps.last, isNull);
  });

  testWidgets('no values shows only «Tutti»', (tester) async {
    await _pump(tester, values: const []);

    expect(find.text('Tutti'), findsOneWidget);
    expect(find.byType(CachedSvg), findsNothing);
  });
}
