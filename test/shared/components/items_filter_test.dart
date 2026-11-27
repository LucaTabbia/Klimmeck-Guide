import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

Future<List<Set<UseType>>> _pump(
  WidgetTester tester, {
  List<UseType> values = const [UseType.defense, UseType.attack],
  Set<UseType> selected = const {},
  double width = 400,
}) async {
  final changes = <Set<UseType>>[];
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ItemsFilter<UseType>(
              values: values,
              selected: selected,
              onChanged: changes.add,
              getImage: (useType) => useType.imagePath,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return changes;
}

Finder _chip(UseType useType) => find.byWidgetPredicate(
  (widget) => widget is CachedSvg && widget.url == useType.imagePath,
);

void main() {
  setUp(
    () => seedSvgCache(
      [
        for (final useType in UseType.values) useType.imagePath,
      ].map((url) => url.split('/upload/').last),
    ),
  );

  testWidgets('shows one chip per value in order, without «Tutti»', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Tutti'), findsNothing);
    final urls = tester
        .widgetList<CachedSvg>(find.byType(CachedSvg))
        .map((svg) => svg.url)
        .toList();
    expect(urls, [UseType.defense.imagePath, UseType.attack.imagePath]);
  });

  testWidgets('a chip not selected joins the selection', (tester) async {
    final changes = await _pump(tester, selected: {UseType.defense});

    await tester.tap(_chip(UseType.attack));

    expect(changes, [
      {UseType.defense, UseType.attack},
    ]);
  });

  testWidgets('a selected chip leaves the selection', (tester) async {
    final changes = await _pump(tester, selected: {UseType.defense});

    await tester.tap(_chip(UseType.defense));

    expect(changes, [<UseType>{}]);
  });

  testWidgets('many chips shrink to fit the width and never scroll', (
    tester,
  ) async {
    await _pump(tester, values: UseType.values, width: 200);

    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
    for (final useType in UseType.values) {
      expect(tester.getRect(_chip(useType)).right, lessThanOrEqualTo(200));
    }
  });
}
