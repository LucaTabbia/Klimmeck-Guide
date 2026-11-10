import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const _bossIntact = [CloudinaryAssets.bossSheet1, CloudinaryAssets.bossSheet2];
const _bossTorn = [
  CloudinaryAssets.bossTornSheet1,
  CloudinaryAssets.bossTornSheet2,
];

Future<void> _pump(
  WidgetTester tester,
  Quest quest, {
  required bool isTorn,
  ValueChanged<Quest>? onTap,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Sheet(
          quest: quest,
          isTorn: isTorn,
          onTap: onTap ?? (_) {},
          randomizer: 10,
        ),
      ),
    ),
  );
  await tester.pump();
}

String _url(WidgetTester tester) =>
    tester.widget<CachedSvg>(find.byType(CachedSvg)).url;

void main() {
  setUp(
    () => seedSvgCache([
      ..._bossIntact,
      ..._bossTorn,
      CloudinaryAssets.magicSheet,
      CloudinaryAssets.magicTornSheet,
    ]),
  );

  testWidgets('a magic quest shows its own sheet (quick 261110-mag)', (
    tester,
  ) async {
    final magic = buildQuest(id: 'm-1', type: 'magic');
    await _pump(tester, magic, isTorn: false);
    expect(_url(tester), CloudinaryAssets.url(CloudinaryAssets.magicSheet));

    await _pump(tester, magic, isTorn: true);
    expect(_url(tester), CloudinaryAssets.url(CloudinaryAssets.magicTornSheet));
  });

  testWidgets('a torn boss shows a torn boss paper', (tester) async {
    await _pump(tester, buildQuest(id: 'b-1', type: 'boss'), isTorn: true);

    expect(_url(tester), isIn(_bossTorn.map(CloudinaryAssets.url)));
  });

  testWidgets('an intact boss shows an intact boss paper', (tester) async {
    await _pump(tester, buildQuest(id: 'b-1', type: 'boss'), isTorn: false);

    expect(_url(tester), isIn(_bossIntact.map(CloudinaryAssets.url)));
  });

  testWidgets('the paper does not change across rebuilds', (tester) async {
    final quest = buildQuest(id: 'b-2', type: 'boss');
    await _pump(tester, quest, isTorn: false);
    final first = _url(tester);

    await _pump(tester, quest, isTorn: false);

    expect(_url(tester), first);
  });

  testWidgets('tapping calls onTap with the quest', (tester) async {
    final quest = buildQuest(id: 'b-3', type: 'boss');
    Quest? tapped;
    await _pump(tester, quest, isTorn: false, onTap: (q) => tapped = q);

    await tester.tap(find.byType(Sheet));

    expect(tapped, quest);
  });

  testWidgets('a paper is tappable before its image is cached (D-21)', (
    tester,
  ) async {
    // The announcement papers are not seeded: the box stays empty.
    final quest = buildQuest(id: 'h-9', type: 'heal');
    Quest? tapped;
    await _pump(tester, quest, isTorn: false, onTap: (q) => tapped = q);

    await tester.tap(find.byType(Sheet));

    expect(tapped, quest);
  });
}
