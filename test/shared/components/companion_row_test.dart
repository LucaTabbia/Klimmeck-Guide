import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../../helpers/fixtures/shop_fixtures.dart';
import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

const double _rowSize = 120;

final _horse = Pet.fromJson(petJson());
final _cat = Pet.fromJson(catPetJson());

Future<void> _pump(WidgetTester tester, CompanionRow row) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(body: SizedBox(width: 600, child: row)),
    ),
  );
  await tester.pump();
}

CoinsDisplay _coinsDisplay(WidgetTester tester) =>
    tester.widget<CoinsDisplay>(find.byType(CoinsDisplay));

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  testWidgets('shows the name and the buy price (D-07)', (tester) async {
    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));

    expect(find.text('Cavallo da viaggio'), findsOneWidget);
    expect(_coinsDisplay(tester).coins, _horse.buyPrice);
  });

  testWidgets('shows the sell price on the sell side (D-07)', (tester) async {
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, isBuy: false),
    );

    expect(_coinsDisplay(tester).coins, _horse.sellPrice);
  });

  testWidgets('shows the speed line only for a mount (D-07)', (tester) async {
    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));
    expect(find.text('Velocità ×2'), findsOneWidget);

    await _pump(tester, CompanionRow(pet: _cat, size: _rowSize));
    expect(find.textContaining('Velocità'), findsNothing);
  });

  testWidgets('hides the coins in the Journal (D-10)', (tester) async {
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, showCoins: false),
    );

    expect(find.byType(CoinsDisplay), findsNothing);
  });

  testWidgets('marks the equipped companion (D-10)', (tester) async {
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, isEquipped: true),
    );
    expect(find.text(companionEquippedMark), findsOneWidget);

    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));
    expect(find.text(companionEquippedMark), findsNothing);
  });

  testWidgets('a tap calls onTap', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, onTap: () => taps++),
    );

    await tester.tap(find.text('Cavallo da viaggio'));

    expect(taps, 1);
  });

  testWidgets('is text-only: no image (D-13)', (tester) async {
    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));

    expect(find.byType(Image), findsNothing);
  });

  group('rarity (D-20)', () {
    TextStyle? nameStyle(WidgetTester tester) =>
        tester.widget<Text>(find.text('Cavallo da viaggio')).style;

    testWidgets('draws the name in the colour of the rarity (D-20)', (
      tester,
    ) async {
      final pet = Pet.fromJson(petJson(rarity: 'legendary'));

      await _pump(tester, CompanionRow(pet: pet, size: _rowSize));

      expect(nameStyle(tester)?.color, RarityType.legendary.color);
      expect(
        tester.widget<Text>(find.text('Velocità ×2')).style,
        KlimmeckGuideTheme.instance.bodyMedium,
      );
    });

    testWidgets('a pet without rarity keeps the name style of today (D-20)', (
      tester,
    ) async {
      await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));

      expect(nameStyle(tester), KlimmeckGuideTheme.instance.bodyMedium);
    });
  });

  group('attack and defense (D-13)', () {
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
    final attackLine = find.byKey(
      const ValueKey('companion-attack-pet-travel-horse'),
    );
    final defenseLine = find.byKey(
      const ValueKey('companion-defense-pet-travel-horse'),
    );
    final armed = Pet.fromJson(petJson(attack: attack, defense: defense));

    double top(WidgetTester tester, Finder finder) =>
        tester.getTopLeft(finder).dy;

    testWidgets(
      'shows the attack and the defense lines with their keys (D-13)',
      (tester) async {
        await _pump(tester, CompanionRow(pet: armed, size: _rowSize));

        expect(tester.widget<Text>(attackLine).data, attackText);
        expect(tester.widget<Text>(defenseLine).data, defenseText);
      },
    );

    testWidgets('each line is hidden when its damages are empty (D-13)', (
      tester,
    ) async {
      await _pump(
        tester,
        CompanionRow(
          pet: Pet.fromJson(petJson(attack: attack, defense: noDamages)),
          size: _rowSize,
        ),
      );
      expect(attackLine, findsOneWidget);
      expect(defenseLine, findsNothing);

      await _pump(
        tester,
        CompanionRow(
          pet: Pet.fromJson(petJson(attack: noDamages, defense: defense)),
          size: _rowSize,
        ),
      );
      expect(attackLine, findsNothing);
      expect(defenseLine, findsOneWidget);
    });

    testWidgets(
      'shows neither line when the wire carries no attack, defense, maxXp or rarity (lenient)',
      (tester) async {
        await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));

        expect(find.textContaining('Attacco'), findsNothing);
        expect(find.textContaining('Difesa'), findsNothing);
        expect(find.text('Velocità ×2'), findsOneWidget);
      },
    );

    testWidgets(
      'the lines sit between the speed and the equipped mark (D-13)',
      (tester) async {
        await _pump(
          tester,
          CompanionRow(pet: armed, size: _rowSize, isEquipped: true),
        );

        final tops = [
          top(tester, find.text('Cavallo da viaggio')),
          top(tester, find.text('Velocità ×2')),
          top(tester, attackLine),
          top(tester, defenseLine),
          top(tester, find.text(companionEquippedMark)),
        ];
        expect(tops, [...tops]..sort());
        expect(tops.toSet(), hasLength(5));
      },
    );
  });
}
