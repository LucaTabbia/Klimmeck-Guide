import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_menu.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/test_app.dart';

void main() {
  const screen = Size(780, 360);

  setUp(() {
    final svg =
        File('${Directory.systemTemp.createTempSync('kg_svg').path}/item.svg')
          ..writeAsStringSync(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
          );
    for (final entry in SatchelLayout.entries) {
      SvgCache().add(CloudinaryAssets.url(entry.assetPath), svg);
    }
    SvgCache().add(CloudinaryAssets.url(CloudinaryAssets.pouch), svg);
  });

  testWidgets('builds one MenuItem per layout entry', (tester) async {
    useLandscapePhone(tester);
    final parent = AnimationController(vsync: const TestVSync());
    addTearDown(parent.dispose);

    await tester.pumpWidget(
      buildTestApp(
        home: SatchelMenu(
          currentPage: 0,
          onItemTap: (_) {},
          parentAnimationController: parent,
        ),
      ),
    );
    await tester.pump();

    final items = tester.widgetList<MenuItem>(find.byType(MenuItem)).toList();
    expect(items.map((i) => i.pageIndex), [0, 1, 2, 3, 4, 5, 6]);
    expect(items.map((i) => i.imagePath), [
      for (final e in SatchelLayout.entries) CloudinaryAssets.url(e.assetPath),
    ]);
    expect(
      items[6].end,
      SatchelLayout.flightEnd(SatchelLayout.entries[6], screen, 100),
    );
  });

  testWidgets('a disabled item does not report taps, the others do', (
    tester,
  ) async {
    useLandscapePhone(tester);
    final parent = AnimationController(vsync: const TestVSync());
    addTearDown(parent.dispose);
    final taps = <int>[];

    await tester.pumpWidget(
      buildTestApp(
        home: SatchelMenu(
          currentPage: 0,
          onItemTap: taps.add,
          parentAnimationController: parent,
          disabledPages: const {4},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(CachedSvg).last);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tapAt(
      SatchelLayout.centerOf(SatchelLayout.entries[4], screen),
    );
    await tester.pump();
    expect(taps, isEmpty);

    await tester.tapAt(
      SatchelLayout.centerOf(SatchelLayout.entries[5], screen),
    );
    await tester.pump();
    expect(taps, [5]);
  });
}
