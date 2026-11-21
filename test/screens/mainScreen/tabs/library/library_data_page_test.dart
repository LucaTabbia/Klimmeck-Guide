import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/letter_bookmarks.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_data_page.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/initial_letter.dart';

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

List<Lore> sixtyStates() => [
  for (var i = 1; i <= 60; i++)
    Lore.fromJson(
      loreJson(id: 'lore-state-$i', type: 'state', name: 'Stato $i'),
    ),
];

Future<void> pumpDataPage(
  WidgetTester tester, {
  LibraryBook book = LibraryBook.places,
  List<Lore> lore = const [],
  Set<String> newLoreIds = const {},
  VoidCallback? onBack,
  bool openFilters = true,
}) async {
  useLandscapePhone(tester);
  seedSvgCache([
    CloudinaryAssets.redBookmarkBack,
    CloudinaryAssets.greenBookmarkBack,
    CloudinaryAssets.yellowBookmarkBack,
    CloudinaryAssets.blueBookmarkBack,
    CloudinaryAssets.greenBookmark,
    CloudinaryAssets.arrowDown,
    ...CloudinaryAssets.letterBookmarks.values,
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
  if (openFilters) await showLetterBookmarks(tester);
}

/// Gli stendardi nascono ritirati sotto il titolo: li fa scendere, se ci sono
/// e non sono già fuori.
Future<void> showLetterBookmarks(WidgetTester tester) async {
  final banners = find.byType(LetterBookmarks);
  if (banners.evaluate().isEmpty) return;
  if (tester.widget<LetterBookmarks>(banners).isOpen) return;
  await tester.tap(find.byKey(LibraryDataPage.filtersToggleKey));
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
  (widget) => widget is CachedSvg && widget.url == book.backBookmarkUrl,
);

Finder letterBookmark(String letter) =>
    find.byKey(LetterBookmarks.keyOf(letter));

Future<void> tapLetter(WidgetTester tester, String letter) async {
  await tester.tap(letterBookmark(letter));
  await tester.pumpAndSettle();
}

List<String> shownLoreIds(WidgetTester tester) => tester
    .widgetList<LoreCard>(find.byType(LoreCard))
    .map((card) => card.lore.id)
    .toList();

void main() {
  testWidgets('the rule under the title takes the colour of the book', (
    tester,
  ) async {
    Future<Set<Color?>> ruleColorsOf(LibraryBook book) async {
      await pumpDataPage(tester, book: book);
      return tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(LibraryBookFrame.ruleKey),
              matching: find.byType(Container),
            ),
          )
          .map((line) => line.color)
          .toSet();
    }

    expect(await ruleColorsOf(LibraryBook.bestiary), {
      KlimmeckGuideTheme.royalCrimson,
    });
    expect(await ruleColorsOf(LibraryBook.places), {
      KlimmeckGuideTheme.healGreen,
    });
    expect(await ruleColorsOf(LibraryBook.religions), {
      KlimmeckGuideTheme.darkBronze,
    });
    expect(await ruleColorsOf(LibraryBook.knowledge), {
      KlimmeckGuideTheme.mysticBlue,
    });
  });

  testWidgets('a thread parts the entries, none follows the last one', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: [andogan, bosa]);
    await openSection(tester, 'Città');

    final thread = find.byKey(LibraryDataPage.loreDividerKey);
    expect(thread, findsOneWidget);
    expect(
      tester.getRect(thread).top,
      greaterThan(tester.getRect(cardOf('lore-andogan')).bottom - 1),
    );
    expect(
      tester.getRect(thread).bottom,
      lessThan(tester.getRect(cardOf('lore-bosa')).top + 1),
    );
  });

  testWidgets('a section with a single entry has no thread', (tester) async {
    await pumpDataPage(tester, lore: [andogan]);
    await openSection(tester, 'Città');

    expect(find.byKey(LibraryDataPage.loreDividerKey), findsNothing);
  });

  testWidgets('the arrow of a section turns as it opens and closes', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: [andogan, bosa]);
    double turns() => tester
        .widget<DropdownHeader>(
          find.byKey(LibraryDataPage.sectionKeyOf(LoreType.city)),
        )
        .turns;
    expect(turns(), 0);

    await tester.tap(find.text('Città'));
    await tester.pump();
    await tester.pump(LibraryDataPage.arrowTurnDuration ~/ 2);
    expect(turns(), greaterThan(0));
    expect(turns(), lessThan(0.5));
    await tester.pumpAndSettle();
    expect(turns(), 0.5);

    await tester.tap(find.text('Città'));
    await tester.pump();
    await tester.pump(LibraryDataPage.arrowTurnDuration ~/ 2);
    expect(turns(), greaterThan(0));
    expect(turns(), lessThan(0.5));
    await tester.pumpAndSettle();
    expect(turns(), 0);
  });

  testWidgets('at rest the first section starts below the banners', (
    tester,
  ) async {
    await pumpDataPage(tester, lore: [andogan, bosa]);

    expect(
      tester.getRect(find.byType(DropdownHeader).first).top,
      greaterThan(tester.getRect(find.byType(LetterBookmarks)).bottom),
    );
  });

  group('closing a section from the title row', () {
    final collapse = find.byKey(LibraryDataPage.collapseKey);
    final cityHeader = find.byKey(LibraryDataPage.sectionKeyOf(LoreType.city));
    final toggle = find.byKey(LibraryDataPage.filtersToggleKey);

    Future<void> scrollDown(WidgetTester tester, double distance) async {
      await tester.drag(find.byType(CustomScrollView), Offset(0, -distance));
      await tester.pumpAndSettle();
    }

    testWidgets('no control while the header of the open section is in view', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: sixtyCities());
      expect(collapse, findsNothing);

      await openSection(tester, 'Città');

      expect(collapse, findsNothing);
    });

    testWidgets(
      'once the banners cover the header the title row offers to close it, '
      'naming the section in a smaller hand than the title',
      (tester) async {
        await pumpDataPage(tester, lore: sixtyCities());
        await openSection(tester, 'Città');

        await scrollDown(tester, 600);

        expect(collapse, findsOneWidget);
        expect(cityHeader.hitTestable(), findsNothing);
        final name = find.descendant(
          of: collapse,
          matching: find.text('Città'),
        );
        expect(name, findsOneWidget);
        expect(
          tester.widget<Text>(name).style!.fontSize,
          lessThan(tester.widget<Text>(find.text('Luoghi')).style!.fontSize!),
        );
        final bar = tester.getRect(find.byKey(LibraryBookFrame.titleBarKey));
        final control = tester.getRect(collapse);
        expect(bar.contains(control.topLeft), isTrue);
        expect(bar.contains(control.bottomRight), isTrue);
        expect(
          control.left,
          greaterThan(tester.getRect(find.text('Luoghi')).right),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a tap closes the section and brings its header back under the banners',
      (tester) async {
        await pumpDataPage(tester, lore: sixtyCities());
        await openSection(tester, 'Città');
        await scrollDown(tester, 600);

        await tester.tap(collapse);
        await tester.pumpAndSettle();

        expect(find.byType(LoreCard), findsNothing);
        expect(collapse, findsNothing);
        final header = tester.getRect(cityHeader);
        final banners = tester.getRect(find.byType(LetterBookmarks));
        expect(header.top, greaterThanOrEqualTo(banners.bottom));
        expect(header.top, lessThan(banners.bottom + 60));
        expect(cityHeader.hitTestable(), findsOneWidget);
      },
    );

    testWidgets('the control names the open section being read', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [...sixtyCities(), valtorre, drustea]);
      await openSection(tester, 'Città');

      await scrollDown(tester, 600);

      expect(
        find.descendant(of: collapse, matching: find.text('Città')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: collapse, matching: find.text('Regioni')),
        findsNothing,
      );
    });

    testWidgets('scrolling back to the header takes the control away', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: sixtyCities());
      await openSection(tester, 'Città');
      await scrollDown(tester, 600);
      expect(collapse, findsOneWidget);

      await scrollDown(tester, -600);

      expect(collapse, findsNothing);
      expect(cityHeader.hitTestable(), findsOneWidget);
    });

    testWidgets('letting the banners down over a stuck header leaves it where '
        'it is: it fades under them and the title row takes over; folding '
        'them gives it back', (tester) async {
      await pumpDataPage(tester, lore: sixtyCities(), openFilters: false);
      await openSection(tester, 'Città');
      await scrollDown(tester, 600);
      final element = tester.element(cityHeader);
      final stuckAt = tester.getRect(cityHeader).top;
      expect(collapse, findsNothing);

      Future<void> toggleKeepingTheHeaderStill() async {
        await tester.tap(toggle);
        await tester.pump();
        for (var step = 0; step < 6; step++) {
          await tester.pump(LetterBookmarks.slideDuration ~/ 6);
          expect(tester.getRect(cityHeader).top, closeTo(stuckAt, 0.01));
        }
        await tester.pumpAndSettle();
        expect(tester.element(cityHeader), same(element));
        expect(tester.getRect(cityHeader).top, closeTo(stuckAt, 0.01));
      }

      await toggleKeepingTheHeaderStill();
      expect(cityHeader.hitTestable(), findsNothing);
      expect(collapse, findsOneWidget);

      await toggleKeepingTheHeaderStill();
      expect(cityHeader.hitTestable(), findsOneWidget);
      expect(collapse, findsNothing);
    });
  });

  group('folding the banners under the title', () {
    final toggle = find.byKey(LibraryDataPage.filtersToggleKey);

    Rect ruleRect(WidgetTester tester) =>
        tester.getRect(find.byKey(LibraryBookFrame.ruleKey));

    testWidgets('the banners start folded: only the tips of the long ones '
        'peek out from under the title', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa], openFilters: false);

      expect(tester.getRect(letterBookmark('a')).height, 0);
      final tip = tester.getRect(letterBookmark('b'));
      expect(tip.top, ruleRect(tester).bottom);
      expect(tip.height, greaterThan(4));
      expect(tip.height, lessThanOrEqualTo(12));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a folded banner ignores the tap', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa], openFilters: false);
      await openSection(tester, 'Città');

      await tester.tap(letterBookmark('b'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(shownLoreIds(tester), ['lore-andogan', 'lore-bosa']);
    });

    testWidgets('the arrow beside the title lets the banners down and folds '
        'them back', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa], openFilters: false);
      final title = tester.getRect(find.text('Luoghi'));
      final arrow = tester.getRect(toggle);
      expect(arrow.left, greaterThanOrEqualTo(title.right));
      expect(arrow.left - title.right, lessThan(16));
      expect(arrow.center.dy, closeTo(title.center.dy, 4));

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final lowered = tester.getRect(letterBookmark('b')).height;
      expect(lowered, greaterThan(60));
      expect(tester.getRect(letterBookmark('a')).height, greaterThan(30));

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.getRect(letterBookmark('a')).height, 0);
      expect(tester.getRect(letterBookmark('b')).height, lessThan(lowered));
    });

    testWidgets('a tap on the title itself lets the banners down and folds '
        'them back too', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa], openFilters: false);

      await tester.tap(find.text('Luoghi'));
      await tester.pumpAndSettle();
      expect(tester.getRect(letterBookmark('a')).height, greaterThan(30));

      await tester.tap(find.text('Luoghi'));
      await tester.pumpAndSettle();
      expect(tester.getRect(letterBookmark('a')).height, 0);
    });

    testWidgets('the banners slide: half way they are half out', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa], openFilters: false);

      await tester.tap(toggle);
      await tester.pump();
      await tester.pump(LetterBookmarks.slideDuration ~/ 2);
      final halfWay = tester.getRect(letterBookmark('a')).height;
      await tester.pumpAndSettle();

      expect(halfWay, greaterThan(0));
      expect(halfWay, lessThan(tester.getRect(letterBookmark('a')).height));
    });

    testWidgets('folding the banners keeps the chosen letter, and its banner '
        'peeks out longer than the others', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);
      await openSection(tester, 'Città');
      await tapLetter(tester, 'a');
      expect(shownLoreIds(tester), ['lore-andogan']);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(shownLoreIds(tester), ['lore-andogan']);
      expect(
        tester.getRect(letterBookmark('a')).height,
        greaterThan(tester.getRect(letterBookmark('b')).height),
      );
      expect(tester.getRect(letterBookmark('c')).height, 0);
    });

    testWidgets('with the banners folded the first section starts close '
        'under the title', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa], openFilters: false);

      final header = tester.getRect(find.byType(DropdownHeader).first);
      expect(header.top, greaterThan(ruleRect(tester).bottom + 12));
      expect(header.top, lessThan(ruleRect(tester).bottom + 40));
    });

    testWidgets('with the banners folded the header of the open section '
        'stays right under the title while its entries scroll', (tester) async {
      await pumpDataPage(tester, lore: sixtyCities(), openFilters: false);
      await openSection(tester, 'Città');

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final header = find.byKey(LibraryDataPage.sectionKeyOf(LoreType.city));
      expect(tester.getRect(header).top, closeTo(ruleRect(tester).bottom, 1));
      expect(find.byKey(LibraryDataPage.collapseKey), findsNothing);

      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(find.byType(LoreCard), findsNothing);
    });

    testWidgets('with the banners folded the next section pushes the stuck '
        'header away', (tester) async {
      await pumpDataPage(
        tester,
        lore: [andogan, bosa, valtorre, ...sixtyStates()],
        openFilters: false,
      );
      await openSection(tester, 'Stati');
      await openSection(tester, 'Città');

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(
        tester
            .getRect(find.byKey(LibraryDataPage.sectionKeyOf(LoreType.state)))
            .top,
        closeTo(ruleRect(tester).bottom, 1),
      );
      expect(
        find.byKey(LibraryDataPage.sectionKeyOf(LoreType.city)).hitTestable(),
        findsNothing,
      );
    });

    testWidgets('an empty book shows no arrow beside the title', (
      tester,
    ) async {
      await pumpDataPage(tester, book: LibraryBook.bestiary);

      expect(toggle, findsNothing);
    });
  });

  group('letter bookmarks', () {
    testWidgets('hang one per letter, short and long by turns', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);

      expect(find.byType(LetterBookmarks), findsOneWidget);
      for (final letter in alphabet) {
        expect(letterBookmark(letter), findsOneWidget);
      }
      final short = tester.getRect(letterBookmark('a'));
      final long = tester.getRect(letterBookmark('b'));
      final rule = tester.getRect(find.byKey(LibraryBookFrame.ruleKey));
      expect(short.top, rule.bottom);
      expect(long.top, rule.bottom);
      expect(long.height, greaterThan(short.height));
      expect(tester.getRect(letterBookmark('c')).height, short.height);
      expect(tester.getRect(letterBookmark('d')).height, long.height);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the upper end of every banner stays off the page', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);
      await tapLetter(tester, 'b');

      for (final letter in ['a', 'b']) {
        final art = tester.getRect(
          find.descendant(
            of: letterBookmark(letter),
            matching: find.byType(CachedSvg),
          ),
        );
        final rule = tester.getRect(find.byKey(LibraryBookFrame.ruleKey));
        expect(art.top, lessThan(rule.bottom - art.height * 0.1));
      }
    });

    testWidgets('the first and the last banner stay inside the page margins', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);

      final sections = tester.getRect(find.byType(DropdownHeader).first);
      expect(tester.getRect(letterBookmark('a')).left, sections.left);
      expect(tester.getRect(letterBookmark('z')).right, sections.right);
    });

    testWidgets('the banner shows its whole tip', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);

      final banner = tester.getRect(letterBookmark('a'));
      final art = tester.getRect(
        find.descendant(
          of: letterBookmark('a'),
          matching: find.byType(CachedSvg),
        ),
      );
      expect(art.bottom - banner.bottom, lessThan(art.height * 0.02));
    });

    testWidgets('a tap lengthens the banner and keeps only its initial', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa, valtorre]);
      final before = tester.getRect(letterBookmark('b')).height;

      await tapLetter(tester, 'b');

      expect(tester.getRect(letterBookmark('b')).height, greaterThan(before));
      expect(find.text('Città'), findsOneWidget);
      expect(find.text('Regioni'), findsNothing);
      await openSection(tester, 'Città');
      expect(shownLoreIds(tester), ['lore-bosa']);
    });

    testWidgets('a second tap on the chosen banner shows every entry again', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa, valtorre]);
      final before = tester.getRect(letterBookmark('b')).height;
      await tapLetter(tester, 'b');

      await tapLetter(tester, 'b');

      expect(tester.getRect(letterBookmark('b')).height, before);
      expect(find.text('Regioni'), findsOneWidget);
      await openSection(tester, 'Città');
      expect(shownLoreIds(tester), ['lore-andogan', 'lore-bosa']);
    });

    testWidgets('choosing another letter moves the selection', (tester) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);
      await openSection(tester, 'Città');
      await tapLetter(tester, 'b');

      await tapLetter(tester, 'a');

      expect(shownLoreIds(tester), ['lore-andogan']);
    });

    testWidgets('a letter with no entry is faded and ignores the tap', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);
      await openSection(tester, 'Città');
      double opacityOf(String letter) => tester
          .widget<Opacity>(
            find.descendant(
              of: letterBookmark(letter),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;

      await tapLetter(tester, 'z');

      expect(opacityOf('z'), lessThan(1));
      expect(opacityOf('a'), 1);
      expect(shownLoreIds(tester), ['lore-andogan', 'lore-bosa']);
    });

    testWidgets('an accented initial answers to its plain letter', (
      tester,
    ) async {
      final erebo = Lore.fromJson(loreJson(id: 'lore-erebo', name: 'Èrebo'));
      await pumpDataPage(tester, lore: [andogan, erebo]);
      await openSection(tester, 'Città');

      await tapLetter(tester, 'e');

      expect(shownLoreIds(tester), ['lore-erebo']);
    });

    testWidgets('an initial gone from the book shows every entry again', (
      tester,
    ) async {
      await pumpDataPage(tester, lore: [andogan, bosa]);
      await openSection(tester, 'Città');
      await tapLetter(tester, 'b');

      await pumpDataPage(tester, lore: [andogan]);

      expect(shownLoreIds(tester), ['lore-andogan']);
    });

    testWidgets('an empty book hangs no banner', (tester) async {
      await pumpDataPage(tester, book: LibraryBook.bestiary);

      expect(find.byType(LetterBookmarks), findsNothing);
    });
  });

  testWidgets(
    'the title, its rule and the banners stay still while the page scrolls',
    (tester) async {
      await pumpDataPage(tester, lore: sixtyCities());
      await openSection(tester, 'Città');
      final title = tester.getRect(find.text('Luoghi'));
      final rule = tester.getRect(find.byKey(LibraryBookFrame.ruleKey));
      final bar = tester.getRect(find.byKey(LibraryBookFrame.titleBarKey));
      final banners = tester.getRect(find.byType(LetterBookmarks));
      expect(rule.top, greaterThanOrEqualTo(title.bottom));
      expect(rule.width, bar.width);
      expect(rule.bottom, bar.bottom);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('Luoghi')), title);
      expect(tester.getRect(find.byKey(LibraryBookFrame.ruleKey)), rule);
      expect(tester.getRect(find.byType(LetterBookmarks)), banners);
    },
  );

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

  testWidgets(
    'a closed section holding a new entry carries the bookmark on its header',
    (tester) async {
      await pumpDataPage(
        tester,
        lore: [andogan, bosa, valtorre],
        newLoreIds: {'lore-bosa'},
      );

      final mark = find.byKey(
        LibraryDataPage.sectionNewMarkKeyOf(LoreType.city),
      );
      expect(
        find.descendant(
          of: find.byKey(LibraryDataPage.sectionKeyOf(LoreType.city)),
          matching: mark,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(LibraryDataPage.sectionNewMarkKeyOf(LoreType.region)),
        findsNothing,
      );
      final arrow = tester.getRect(
        find.descendant(
          of: find.byKey(LibraryDataPage.sectionKeyOf(LoreType.city)),
          matching: find.byType(RotationTransition),
        ),
      );
      expect(tester.getRect(mark).right, closeTo(arrow.left, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the new entries open their section, in the served order', (
    tester,
  ) async {
    final carro = Lore.fromJson(loreJson(id: 'lore-carro', name: 'Carro'));
    await pumpDataPage(
      tester,
      lore: [andogan, bosa, carro],
      newLoreIds: {'lore-bosa', 'lore-carro'},
    );
    await openSection(tester, 'Città');

    final shown = tester
        .widgetList<LoreCard>(find.byType(LoreCard))
        .map((card) => card.lore.id);
    expect(shown.take(2), ['lore-bosa', 'lore-carro']);
    expect(
      tester.getTopLeft(cardOf('lore-carro')).dy,
      greaterThan(tester.getTopLeft(cardOf('lore-bosa')).dy),
    );
  });

  testWidgets('marks only the new entries with «Novità» (D-07)', (
    tester,
  ) async {
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

    await tester.scrollUntilVisible(find.text('Città 60'), 500);

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
