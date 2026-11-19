import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/novelty_bookmark.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

Future<void> pumpCard(WidgetTester tester, LoreCard card) async {
  useLandscapePhone(tester);
  seedSvgCache([CloudinaryAssets.greenBookmark]);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final Lore andogan = Lore.fromJson(
    loreJson(id: 'lore-andogan', name: 'Andogan'),
  );

  testWidgets('a new entry carries the «Novità» bookmark of its book (D-07)', (
    tester,
  ) async {
    await pumpCard(
      tester,
      LoreCard(lore: andogan, newInBook: LibraryBook.places),
    );

    final mark = tester.widget<NoveltyBookmark>(
      find.byKey(LoreCard.newMarkKey),
    );
    expect(mark.book, LibraryBook.places);
    expect(
      find.descendant(
        of: find.byKey(LoreCard.newMarkKey),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CachedSvg &&
              widget.url ==
                  CloudinaryAssets.url(CloudinaryAssets.greenBookmark),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Nuovo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an entry already seen carries no bookmark (D-07)', (
    tester,
  ) async {
    await pumpCard(tester, LoreCard(lore: andogan));

    expect(find.byKey(LoreCard.newMarkKey), findsNothing);
  });

  test('every book has its own bookmark, back ribbon and open cover', () {
    for (final art in <String Function(LibraryBook)>[
      (book) => book.noveltyBookmarkUrl,
      (book) => book.backBookmarkUrl,
      (book) => book.openCoverUrl,
    ]) {
      expect(LibraryBook.values.map(art).toSet(), hasLength(4));
    }
    expect(
      LibraryBook.religions.noveltyBookmarkUrl,
      CloudinaryAssets.url(CloudinaryAssets.yellowBookmark),
    );
    expect(
      LibraryBook.knowledge.backBookmarkUrl,
      CloudinaryAssets.url(CloudinaryAssets.blueBookmarkBack),
    );
    expect(
      LibraryBook.bestiary.openCoverUrl,
      CloudinaryAssets.url(CloudinaryAssets.bestiaryOpen),
    );
  });

  testWidgets('a lore without description still shows its name (D-06)', (
    tester,
  ) async {
    await pumpCard(
      tester,
      LoreCard(
        lore: Lore.fromJson(
          loreJson(id: 'lore-bosa', name: 'Bosa', description: null),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Bosa'), findsOneWidget);
  });
}
