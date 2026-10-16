import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

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
  });

  Future<List<int>> pumpItem(WidgetTester tester, SatchelEntry entry) async {
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
}
