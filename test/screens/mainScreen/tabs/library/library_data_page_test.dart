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

List<Key?> dropdownKeys(WidgetTester tester) => tester
    .widgetList<Dropdown>(find.byType(Dropdown))
    .map((d) => d.key)
    .toList();

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

    expect(find.byType(Dropdown), findsOneWidget);
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
      expect(find.byType(Dropdown), findsNothing);
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

    expect(find.byKey(LoreCard.newMarkKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is LoreCard && widget.lore.id == 'lore-bosa',
        ),
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

  testWidgets('keeps an open section open when an earlier one appears (D-05)', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: [valtorre]);
    await tester.tap(find.text('Regioni'));
    await tester.pumpAndSettle();

    await pumpDataPage(tester, lore: [andogan, valtorre]);

    expect(dropdownKeys(tester), [
      const ValueKey<LoreType>(LoreType.city),
      const ValueKey<LoreType>(LoreType.region),
    ]);
    final regionBody = tester.widget<SizeTransition>(
      find.descendant(
        of: find.byKey(const ValueKey<LoreType>(LoreType.region)),
        matching: find.byType(SizeTransition),
      ),
    );
    expect(regionBody.sizeFactor.value, 1.0);
  });

  testWidgets('the back bookmark returns to the books (D-06)', (tester) async {
    var backs = 0;
    await pumpDataPage(tester, lore: [andogan], onBack: () => backs++);

    await tester.tap(backBookmarkOf(LibraryBook.places));
    expect(backs, 1);
  });
}
