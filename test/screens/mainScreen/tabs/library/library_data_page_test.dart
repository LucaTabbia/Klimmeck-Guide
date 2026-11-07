import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_data_page.dart';

import '../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

Future<void> pumpDataPage(
  WidgetTester tester, {
  required List<LoreType> types,
  required String title,
  List<Lore> lore = const [],
}) async {
  useLandscapePhone(tester);
  seedSvgCache([CloudinaryAssets.bookmarkRed, CloudinaryAssets.arrowDown]);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: LibraryDataPage(
          key: ValueKey(title),
          lore: lore,
          types: types,
          title: title,
          bookmarkImagePath: CloudinaryAssets.url(CloudinaryAssets.bookmarkRed),
          onBack: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('titles the sections in Italian (D-15)', (tester) async {
    await pumpDataPage(
      tester,
      types: [LoreType.enemy, LoreType.animal, LoreType.plant],
      title: 'Bestiario',
      lore: [
        Lore.fromJson(
          loreJson(id: 'lore-goblin', type: 'enemy', name: 'Goblin'),
        ),
      ],
    );
    expect(find.text('Mostri'), findsOneWidget);
    expect(find.text('Animali'), findsOneWidget);
    expect(find.text('Piante'), findsOneWidget);
    expect(find.text('enemy'), findsNothing);

    await pumpDataPage(
      tester,
      types: [LoreType.city, LoreType.region, LoreType.state],
      title: 'Luoghi',
    );
    expect(find.text('Città'), findsOneWidget);
    expect(find.text('Regioni'), findsOneWidget);
    expect(find.text('Stati'), findsOneWidget);
  });
}
