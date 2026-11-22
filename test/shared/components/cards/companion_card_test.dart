import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

/// Lato della carta nel Diario in landscape: `(780 - 180) / 5`.
const double journalCardSize = 120;
const String worgId = 'pet-worg';
const String worgImage = 'v1/pets/worg.svg';

void main() {
  setUp(() {
    seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.redBookmarkBack,
      worgImage,
    ]);
  });

  Future<void> pump(
    WidgetTester tester,
    Pet pet, {
    bool? isMarked,
    String? name,
    int? level,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Center(
            child: CompanionCard(
              pet: pet,
              size: journalCardSize,
              name: name,
              level: level,
              isMarked: isMarked,
            ),
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
    expect(
      tester.getTopLeft(find.text('Cavallo da viaggio')).dy,
      lessThan(tester.getTopLeft(find.text('Velocità ×2')).dy),
    );
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

  String? textIn(WidgetTester tester, Key key) => tester
      .widget<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
      )
      .data;

  final worg = Pet.fromJson(
    petJson(
      id: worgId,
      name: 'Worg',
      speedModifier: null,
      rarity: 'rare',
      imagePath: worgImage,
    ),
  );

  group('image (D-34)', () {
    testWidgets('shows the pet image above the title (D-34)', (tester) async {
      await pump(tester, worg);

      final image = find.byKey(CompanionCard.imageKeyOf(worgId));
      expect(image, findsOneWidget);
      expect(tester.widget<EnemyPortrait>(image).imagePath, worgImage);
      expect(
        tester.getTopLeft(image).dy,
        lessThan(
          tester.getTopLeft(find.byKey(CompanionCard.titleKeyOf(worgId))).dy,
        ),
      );
    });

    testWidgets('no image when the path cannot be resolved (D-34)', (
      tester,
    ) async {
      await pump(
        tester,
        Pet.fromJson(petJson(id: worgId, imagePath: 'assets/images/x.png')),
      );

      expect(find.byKey(CompanionCard.imageKeyOf(worgId)), findsNothing);
      expect(find.byType(EnemyPortrait), findsNothing);
    });

    testWidgets('a companion whose lore is not unlocked is a black silhouette '
        'with its name, as an unknown enemy (UAT 2026-11-15)', (tester) async {
      await pump(tester, worg.copyWith(known: false));

      final image = find.byKey(CompanionCard.imageKeyOf(worgId));
      expect(tester.widget<EnemyPortrait>(image).known, isFalse);
      final silhouette = tester.widget<ColorFiltered>(
        find.descendant(of: image, matching: find.byType(ColorFiltered)),
      );
      expect(silhouette.colorFilter, EnemyPortrait.silhouetteFilter);
      expect(
        find.bySemanticsLabel(EnemyPortrait.unknownSemanticLabel),
        findsOneWidget,
      );
      expect(find.text('Worg'), findsOneWidget);
    });

    testWidgets('a known companion keeps its picture (UAT 2026-11-15)', (
      tester,
    ) async {
      await pump(tester, worg);

      final image = find.byKey(CompanionCard.imageKeyOf(worgId));
      expect(tester.widget<EnemyPortrait>(image).known, isTrue);
      expect(
        find.descendant(of: image, matching: find.byType(ColorFiltered)),
        findsNothing,
      );
    });
  });

  group('name and species (D-20)', () {
    testWidgets(
      'a named companion reads the name as title and the species below (D-20)',
      (tester) async {
        await pump(tester, worg, name: 'Fenrir');

        expect(textIn(tester, CompanionCard.titleKeyOf(worgId)), 'Fenrir');
        expect(colorOf(tester, 'Fenrir'), RarityType.rare.color);
        expect(textIn(tester, CompanionCard.speciesKeyOf(worgId)), 'Worg');
        expect(top(tester, 'Fenrir'), lessThan(top(tester, 'Worg')));
      },
    );

    testWidgets(
      'an unnamed companion reads the species as title and no sub-label (D-20)',
      (tester) async {
        await pump(tester, worg, name: '   ');

        expect(textIn(tester, CompanionCard.titleKeyOf(worgId)), 'Worg');
        expect(find.byKey(CompanionCard.speciesKeyOf(worgId)), findsNothing);
        expect(cardTexts(tester), ['Worg']);
      },
    );
  });

  group('level (D-37)', () {
    testWidgets(
      'a named companion with a level reads «Worg · Livello 3» below the name (D-37)',
      (tester) async {
        await pump(tester, worg, name: 'Fenrir', level: 3);

        expect(
          textIn(tester, CompanionCard.speciesKeyOf(worgId)),
          'Worg · Livello 3',
        );
      },
    );

    testWidgets(
      'an unnamed companion with a level reads «Livello 3» below the species (D-37)',
      (tester) async {
        await pump(tester, worg, level: 3);

        expect(textIn(tester, CompanionCard.titleKeyOf(worgId)), 'Worg');
        expect(textIn(tester, CompanionCard.speciesKeyOf(worgId)), 'Livello 3');
      },
    );

    testWidgets('without a level nothing about levels is shown (D-37)', (
      tester,
    ) async {
      await pump(tester, worg, name: 'Fenrir');

      expect(find.textContaining('Livello'), findsNothing);
    });
  });

  testWidgets(
    'the card carries no attack or defense: they live in the details (D-22)',
    (tester) async {
      await pump(
        tester,
        Pet.fromJson(petJson(attack: attack, defense: defense)),
      );

      expect(find.text(attackText), findsNothing);
      expect(find.text(defenseText), findsNothing);
      expect(find.textContaining('Attacco'), findsNothing);
      expect(find.textContaining('Difesa'), findsNothing);
      expect(cardTexts(tester), ['Cavallo da viaggio', 'Velocità ×2']);
    },
  );

  testWidgets('fits without overflow at Journal size in landscape (D-22)', (
    tester,
  ) async {
    await pump(
      tester,
      Pet.fromJson(
        petJson(
          id: worgId,
          name: 'Worg',
          rarity: 'legendary',
          imagePath: worgImage,
          attack: attack,
          defense: defense,
        ),
      ),
      name: 'Fenrir',
      level: 3,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(CompanionCard.imageKeyOf(worgId)), findsOneWidget);
    expect(cardTexts(tester), ['Fenrir', 'Worg · Livello 3', 'Velocità ×2']);
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

      expect(cardTexts(tester), ['Cavallo da viaggio', 'Velocità ×2']);
    });

    testWidgets('the species and speed labels keep their colour (D-20)', (
      tester,
    ) async {
      await pump(
        tester,
        Pet.fromJson(petJson(name: 'Worg', rarity: 'rare')),
        name: 'Fenrir',
      );

      expect(inkOfToday(), isNot(RarityType.rare.color));
      expect(colorOf(tester, 'Fenrir'), RarityType.rare.color);
      expect(colorOf(tester, 'Worg'), inkOfToday());
      expect(colorOf(tester, 'Velocità ×2'), inkOfToday());
    });
  });
}
