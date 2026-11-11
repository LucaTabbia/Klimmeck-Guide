import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

void main() {
  setUp(() {
    seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
    ]);
  });

  Future<void> pump(WidgetTester tester, Pet pet, {bool? isMarked}) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Center(
            child: CompanionCard(pet: pet, size: 120, isMarked: isMarked),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the name and the speed of a riding companion (D-17)', (
    tester,
  ) async {
    await pump(tester, Pet.fromJson(petJson()));

    expect(find.text('Cavallo da viaggio'), findsOneWidget);
    expect(find.text('Velocità ×2'), findsOneWidget);
    expect(find.byType(CoinsDisplay), findsNothing);
    expect(find.byType(CardBookmark), findsNothing);
  });

  testWidgets('shows only the name of a companion without speed (D-17)', (
    tester,
  ) async {
    await pump(tester, Pet.fromJson(catPetJson()));

    expect(find.text('Gatto di bottega'), findsOneWidget);
    expect(find.textContaining('Velocità'), findsNothing);
  });

  testWidgets('carries the bookmark when asked to mark the card (D-17)', (
    tester,
  ) async {
    await pump(tester, Pet.fromJson(petJson()), isMarked: true);

    final bookmark = tester.widget<CardBookmark>(find.byType(CardBookmark));
    expect(bookmark.isMarked, isTrue);
  });

  const attackText = 'Attacco: tagliente 12, fuoco 5';
  const defenseText = 'Difesa: contundente 4';
  const noDamages = <String, dynamic>{'base': [], 'energy': []};
  const attack = <String, dynamic>{
    'base': [
      {'type': 'cut', 'power': 12},
    ],
    'energy': [
      {'type': 'fire', 'power': 5},
    ],
  };
  const defense = <String, dynamic>{
    'base': [
      {'type': 'blunt', 'power': 4},
    ],
    'energy': [],
  };

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  List<String?> cardTexts(WidgetTester tester) => [
    for (final text in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(CompanionCard),
        matching: find.byType(Text),
      ),
    ))
      text.data,
  ];

  group('attack and defense (D-13)', () {
    testWidgets('shows the attack and the defense under the speed (D-13)', (
      tester,
    ) async {
      await pump(
        tester,
        Pet.fromJson(petJson(attack: attack, defense: defense)),
      );

      expect(find.text(attackText), findsOneWidget);
      expect(find.text(defenseText), findsOneWidget);
      expect(
        top(tester, 'Cavallo da viaggio'),
        lessThan(top(tester, 'Velocità ×2')),
      );
      expect(top(tester, 'Velocità ×2'), lessThan(top(tester, attackText)));
      expect(top(tester, attackText), lessThan(top(tester, defenseText)));
    });

    testWidgets('hides the defense when it is empty (D-13)', (tester) async {
      await pump(
        tester,
        Pet.fromJson(petJson(attack: attack, defense: noDamages)),
      );

      expect(find.text(attackText), findsOneWidget);
      expect(find.textContaining('Difesa'), findsNothing);
    });

    testWidgets(
      'hides the attack of a pet without attack and keeps its defense (D-13)',
      (tester) async {
        await pump(tester, Pet.fromJson(petJson(defense: defense)));

        expect(find.textContaining('Attacco'), findsNothing);
        expect(find.text(defenseText), findsOneWidget);
      },
    );

    testWidgets(
      'shows neither line when the wire carries no attack, defense, maxXp or rarity (lenient)',
      (tester) async {
        await pump(tester, Pet.fromJson(petJson()));

        expect(find.textContaining('Attacco'), findsNothing);
        expect(find.textContaining('Difesa'), findsNothing);
        expect(find.text('Cavallo da viaggio'), findsOneWidget);
        expect(find.text('Velocità ×2'), findsOneWidget);
      },
    );

    testWidgets('four labels fit the parchment without overflow (D-13)', (
      tester,
    ) async {
      await pump(
        tester,
        Pet.fromJson(petJson(attack: attack, defense: defense)),
      );

      expect(tester.takeException(), isNull);
      expect(cardTexts(tester), hasLength(4));
    });
  });

  group('rarity (D-20)', () {
    Color? inkOfToday() => KlimmeckGuideTheme.instance.bodyLarge.color;

    testWidgets(
      'draws the name in the colour of the rarity like the item cards (D-20)',
      (tester) async {
        await pump(tester, Pet.fromJson(petJson(rarity: 'rare')));

        expect(colorOf(tester, 'Cavallo da viaggio'), RarityType.rare.color);
      },
    );

    testWidgets('a pet without rarity keeps the name colour of today (D-20)', (
      tester,
    ) async {
      await pump(tester, Pet.fromJson(petJson()));

      expect(colorOf(tester, 'Cavallo da viaggio'), inkOfToday());
      expect(cardTexts(tester), ['Cavallo da viaggio', 'Velocità ×2']);
    });

    testWidgets('the rarity adds no text (D-20)', (tester) async {
      await pump(
        tester,
        Pet.fromJson(
          petJson(rarity: 'legendary', attack: attack, defense: defense),
        ),
      );

      expect(cardTexts(tester), [
        'Cavallo da viaggio',
        'Velocità ×2',
        attackText,
        defenseText,
      ]);
    });

    testWidgets(
      'the speed, attack and defense labels keep their colour (D-20)',
      (tester) async {
        await pump(
          tester,
          Pet.fromJson(
            petJson(rarity: 'rare', attack: attack, defense: defense),
          ),
        );

        expect(inkOfToday(), isNot(RarityType.rare.color));
        expect(colorOf(tester, 'Velocità ×2'), inkOfToday());
        expect(colorOf(tester, attackText), inkOfToday());
        expect(colorOf(tester, defenseText), inkOfToday());
      },
    );
  });
}
