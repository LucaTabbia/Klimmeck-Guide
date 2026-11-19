import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/test_app.dart';

void main() {
  const screen = Size(780, 360);
  const itemSize = 100.0;
  const url = 'https://example.test/item.svg';

  setUp(() {
    final svg =
        File('${Directory.systemTemp.createTempSync('kg_svg').path}/item.svg')
          ..writeAsStringSync(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
          );
    SvgCache().add(url, svg);
    SvgCache().add(NewEntrySigil.url, svg);
  });

  Future<List<int>> pumpItem(
    WidgetTester tester,
    SatchelEntry entry, {
    bool isEnabled = true,
    bool hasNews = false,
  }) async {
    useLandscapePhone(tester);
    final controller = AnimationController(vsync: const TestVSync())
      ..value = 1.0;
    addTearDown(controller.dispose);
    final taps = <int>[];
    await tester.pumpWidget(
      buildTestApp(
        home: SizedBox.expand(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              MenuItem(
                itemAnimationController: controller,
                pageIndex: entry.pageIndex,
                itemSize: itemSize,
                showItems: true,
                imagePath: url,
                end: SatchelLayout.flightEnd(entry, screen, itemSize),
                onTap: taps.add,
                isEnabled: isEnabled,
                hasNews: hasNews,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    return taps;
  }

  testWidgets('the Impostazioni item lands on its cell centre', (tester) async {
    final entry = SatchelLayout.entries[6];
    final taps = await pumpItem(tester, entry);

    await tester.tapAt(SatchelLayout.centerOf(entry, screen));

    expect(taps, [6]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Mappa item lands on its two-row cell centre', (
    tester,
  ) async {
    final entry = SatchelLayout.entries[0];
    final taps = await pumpItem(tester, entry);

    await tester.tapAt(SatchelLayout.centerOf(entry, screen));

    expect(taps, [0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a disabled item ignores taps and dims its icon', (tester) async {
    final entry = SatchelLayout.entries[4];
    final taps = await pumpItem(tester, entry, isEnabled: false);

    await tester.tapAt(SatchelLayout.centerOf(entry, screen));

    expect(taps, isEmpty);
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(MenuItem),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, lessThan(1));
  });

  Finder sigil() => find.byWidgetPredicate(
    (widget) => widget is CachedSvg && widget.url == NewEntrySigil.url,
  );

  testWidgets('an item with news carries the sigil on its top right corner', (
    tester,
  ) async {
    final entry = SatchelLayout.entries[3];
    final taps = await pumpItem(tester, entry, hasNews: true);

    final icon = tester.getRect(find.byType(AnimatedContainer));
    final seal = tester.getRect(sigil());
    expect(seal.topRight, icon.topRight);
    expect(seal.width, lessThan(icon.width / 2));

    await tester.tapAt(SatchelLayout.centerOf(entry, screen));
    expect(taps, [3]);
  });

  testWidgets('an item without news carries no sigil', (tester) async {
    await pumpItem(tester, SatchelLayout.entries[3]);

    expect(sigil(), findsNothing);
  });

  testWidgets('an enabled item keeps full opacity', (tester) async {
    final entry = SatchelLayout.entries[4];
    await pumpItem(tester, entry);

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(MenuItem),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });
}
