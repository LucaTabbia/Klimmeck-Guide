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

const _huntIntact = [CloudinaryAssets.huntSheet1, CloudinaryAssets.huntSheet2];
const _huntTorn = [
  CloudinaryAssets.huntTornSheet1,
  CloudinaryAssets.huntTornSheet2,
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
  setUp(() => seedSvgCache([..._huntIntact, ..._huntTorn]));

  testWidgets('a torn boss shows a torn hunt paper', (tester) async {
    await _pump(tester, buildQuest(id: 'b-1', type: 'boss'), isTorn: true);

    expect(_url(tester), isIn(_huntTorn.map(CloudinaryAssets.url)));
  });

  testWidgets('an intact boss shows an intact hunt paper', (tester) async {
    await _pump(tester, buildQuest(id: 'b-1', type: 'boss'), isTorn: false);

    expect(_url(tester), isIn(_huntIntact.map(CloudinaryAssets.url)));
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
}
