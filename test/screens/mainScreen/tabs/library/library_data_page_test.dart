import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_data_page.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

import '../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

final Lore andogan = Lore.fromJson(
  loreJson(id: 'lore-andogan', name: 'Andogan'),
);
final Lore bosa = Lore.fromJson(loreJson(id: 'lore-bosa', name: 'Bosa'));
final Lore valtorre = Lore.fromJson(
  loreJson(id: 'lore-valtorre', type: 'region', name: 'Valtorre'),
);
final Lore drustea = Lore.fromJson(
  loreJson(id: 'lore-drustea', type: 'state', name: 'Drustea'),
);

const String _cityImageId = 'v1/library_data_page_test_city.svg';

/// Sessanta città con la stessa illustrazione (seminata una volta).
List<Lore> sixtyCities() => [
  for (var i = 1; i <= 60; i++)
    Lore.fromJson(
      loreJson(
        id: 'lore-city-$i',
        name: 'Città $i',
        image: CloudinaryAssets.url(_cityImageId),
      ),
    ),
];

Future<void> pumpDataPage(
  WidgetTester tester, {
  LibraryBook book = LibraryBook.places,
  List<Lore> lore = const [],
  Set<String> newLoreIds = const {},
  VoidCallback? onBack,
}) async {
  useLandscapePhone(tester);
  seedSvgCache([
    CloudinaryAssets.bookmarkRed,
    CloudinaryAssets.bookmarkGreen,
    CloudinaryAssets.bookmarkYellow,
    CloudinaryAssets.bookmarkBlue,
    CloudinaryAssets.arrowDown,
    _cityImageId,
  ]);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: LibraryDataPage(
          book: book,
          lore: lore,
          newLoreIds: newLoreIds,
          onBack: onBack ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openSection(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

List<Key?> sectionKeys(WidgetTester tester) => tester
    .widgetList<DropdownHeader>(find.byType(DropdownHeader))
    .map((header) => header.key)
    .toList();

Finder cardOf(String loreId) => find.byWidgetPredicate(
  (widget) => widget is LoreCard && widget.lore.id == loreId,
);

Finder backBookmarkOf(LibraryBook book) => find.byWidgetPredicate(
  (widget) => widget is CachedSvg && widget.url == book.bookmarkUrl,
);

void main() {
  testWidgets('titles the sections in Italian (D-15)', (tester) async {
    await pumpDataPage(
      tester,
      book: LibraryBook.bestiary,
      lore: [
        Lore.fromJson(
          loreJson(id: 'lore-goblin', type: 'enemy', name: 'Goblin'),
        ),
        Lore.fromJson(loreJson(id: 'lore-lupo', type: 'animal', name: 'Lupo')),
        Lore.fromJson(
          loreJson(id: 'lore-salvia', type: 'plant', name: 'Salvia'),
        ),
      ],
    );
    expect(find.text('Mostri'), findsOneWidget);
    expect(find.text('Animali'), findsOneWidget);
    expect(find.text('Piante'), findsOneWidget);
    expect(find.text('enemy'), findsNothing);

    await pumpDataPage(tester, lore: [andogan, valtorre, drustea]);
    expect(find.text('Città'), findsOneWidget);
    expect(find.text('Regioni'), findsOneWidget);
    expect(find.text('Stati'), findsOneWidget);
  });

  testWidgets('hides the sections with nothing unlocked (D-06)', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: [andogan, bosa]);

    expect(find.byType(DropdownHeader), findsOneWidget);
    expect(find.text('Città'), findsOneWidget);
    expect(find.text('Regioni'), findsNothing);
    expect(find.text('Stati'), findsNothing);
  });

  testWidgets(
    'an empty book shows one status line in place of the sections (D-06)',
    (tester) async {
      var backs = 0;
      await pumpDataPage(
        tester,
        book: LibraryBook.bestiary,
        onBack: () => backs++,
      );

      expect(
        tester.widget<Text>(find.byKey(LibraryDataPage.emptyBookKey)).data,
        'Le pagine di questo libro sono ancora bianche.',
      );
      expect(
        LibraryDataPage.emptyBookLine,
        'Le pagine di questo libro sono ancora bianche.',
      );
      expect(find.byType(DropdownHeader), findsNothing);
      expect(find.text('Bestiario'), findsOneWidget);

      await tester.tap(backBookmarkOf(LibraryBook.bestiary));
      expect(backs, 1);
    },
  );

  testWidgets('marks only the new entries with «Nuovo» (D-07)', (tester) async {
    await pumpDataPage(
      tester,
      lore: [andogan, bosa],
      newLoreIds: {'lore-bosa'},
    );
    await openSection(tester, 'Città');

    expect(find.byKey(LoreCard.newMarkKey), findsOneWidget);
    expect(
      find.descendant(
        of: cardOf('lore-bosa'),
        matching: find.byKey(LoreCard.newMarkKey),
      ),
      findsOneWidget,
    );
  });

  testWidgets('recomputes the sections from the new data (D-05)', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: [andogan]);
    expect(find.text('Regioni'), findsNothing);

    await pumpDataPage(tester, lore: [andogan, valtorre]);
    expect(find.text('Regioni'), findsOneWidget);
  });

  testWidgets(
    'keeps an open section open when an earlier one appears (D-05, D-20)',
    (tester) async {
      await pumpDataPage(tester, lore: [valtorre]);
      await openSection(tester, 'Regioni');
      expect(cardOf('lore-valtorre'), findsOneWidget);

      await pumpDataPage(tester, lore: [andogan, valtorre]);

      expect(sectionKeys(tester), [
        LibraryDataPage.sectionKeyOf(LoreType.city),
        LibraryDataPage.sectionKeyOf(LoreType.region),
      ]);
      expect(cardOf('lore-valtorre'), findsOneWidget);
      expect(cardOf('lore-andogan'), findsNothing);
    },
  );

  testWidgets('a closed section builds no card (D-20)', (tester) async {
    await pumpDataPage(tester, lore: [andogan, bosa]);

    expect(find.text('Città'), findsOneWidget);
    expect(find.byType(LoreCard), findsNothing);
  });

  testWidgets('builds only the cards on screen of an open section (D-20)', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: sixtyCities());
    await openSection(tester, 'Città');

    final built = find.byType(LoreCard).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(60));
    expect(cardOf('lore-city-60'), findsNothing);

    await tester.scrollUntilVisible(find.text('Città 60'), 300);

    expect(cardOf('lore-city-60'), findsOneWidget);
    expect(find.byType(LoreCard).evaluate().length, lessThan(60));
  });

  testWidgets('the back bookmark returns to the books (D-06)', (tester) async {
    var backs = 0;
    await pumpDataPage(tester, lore: [andogan], onBack: () => backs++);

    await tester.tap(backBookmarkOf(LibraryBook.places));
    expect(backs, 1);
  });
}
