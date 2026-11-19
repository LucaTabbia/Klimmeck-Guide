import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_details_route.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info_sheet.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const String _worgImage = 'v1/pets/worg.svg';
const Key _openKey = ValueKey('open-companion-details');

final _worg = Pet.fromJson(
  petJson(id: 'pet-worg', name: 'Worg', imagePath: _worgImage),
);

Future<void> _open(WidgetTester tester) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              key: _openKey,
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  showCompanionDetails(context, pet: _worg, name: 'Fenrir'),
              child: const SizedBox(width: 60, height: 60),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.redBookmarkBack,
      _worgImage,
    ]),
  );

  testWidgets('opens the companion details on the root navigator '
      '(D-22, D-35)', (tester) async {
    await _open(tester);

    expect(find.byType(CompanionInfoSheet), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(CompanionInfo.titleKey)).data,
      'Fenrir',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap outside the parchment closes it (D-22, D-35)', (
    tester,
  ) async {
    await _open(tester);

    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle();

    expect(find.byType(CompanionInfoSheet), findsNothing);
  });

  testWidgets('the route texts sit on a Material, never on the debug '
      'underlined style (D-35)', (tester) async {
    await _open(tester);

    final titleText = find.descendant(
      of: find.byKey(CompanionInfo.titleKey),
      matching: find.byType(RichText),
    );
    final style = tester.widget<RichText>(titleText).text.style;

    expect(style?.decoration, isNot(TextDecoration.underline));
    expect(Material.maybeOf(tester.element(titleText)), isNotNull);
  });

  testWidgets('the route sheet has no bookmark and no rename (D-19, D-35)', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(BookmarkRibbon), findsNothing);
    expect(find.byKey(CompanionInfo.renameKey), findsNothing);
  });
}
