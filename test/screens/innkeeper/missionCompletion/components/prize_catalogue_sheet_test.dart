import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

Map<String, dynamic> _equipment(String id) =>
    equipmentAssetJson(id: id)['item'] as Map<String, dynamic>;

Map<String, dynamic> _loot(String id) =>
    lootAssetJson(id: id)['item'] as Map<String, dynamic>;

/// Catalogo servito in quest'ordine; il blocco aggiunge cavallo e magia.
final MissionPrizeOptions _options = MissionPrizeOptions.tryFromJson(
  missionPrizeOptionsJson(
    equipment: [_equipment('e-sword'), _equipment('e-axe')],
    loot: [_loot('l-herb')],
    pets: [catPetJson()],
    spells: [spellJson(id: 'spell-dart')],
    block: {
      'randomLoot': [
        {'item': _loot('l-relic'), 'quantity': 1},
      ],
      'pet': petJson(),
      'spell': spellJson(id: fireballSpellId, name: 'Palla di fuoco'),
    },
  ),
)!;

final MissionPrizeOptions _noSpells = MissionPrizeOptions.tryFromJson(
  missionPrizeOptionsJson(equipment: [_equipment('e-sword')]),
)!;

void main() {
  late List<AssetItem> items;
  late List<Pet> pets;
  late List<Spell> spells;

  setUp(() {
    seedSvgCache([CloudinaryAssets.emptyCardSheet]);
    items = [];
    pets = [];
    spells = [];
  });

  Future<void> openSheet(
    WidgetTester tester,
    MissionPrizeOptions options,
  ) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PrizeCatalogueSheet(
                  options: options,
                  onPickItem: items.add,
                  onPickPet: pets.add,
                  onPickSpell: spells.add,
                ),
              ),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }

  List<String> itemIds(WidgetTester tester) => [
    for (final row in tester.widgetList<ItemRow>(find.byType(ItemRow)))
      row.assetItem.id,
  ];

  testWidgets(
    'three tabs list the served items, pets and spells in served order (D-07)',
    (tester) async {
      await openSheet(tester, _options);

      expect(find.text(PrizeCatalogueSheet.itemsTab), findsOneWidget);
      expect(itemIds(tester), ['e-sword', 'e-axe', 'l-herb', 'l-relic']);

      await openTab(tester, PrizeCatalogueSheet.petsTab);
      expect(
        [
          for (final row in tester.widgetList<CompanionRow>(
            find.byType(CompanionRow),
          ))
            row.pet.id,
        ],
        ['pet-cat', 'pet-travel-horse'],
      );

      await openTab(tester, PrizeCatalogueSheet.spellsTab);
      expect(
        [
          for (final card in tester.widgetList<SpellCard>(
            find.byType(SpellCard),
          ))
            card.spell.id,
        ],
        ['spell-dart', fireballSpellId],
      );
    },
  );

  testWidgets('an empty spells list shows an empty tab (D-07)', (tester) async {
    await openSheet(tester, _noSpells);

    await openTab(tester, PrizeCatalogueSheet.spellsTab);

    expect(find.byType(SpellCard), findsNothing);
  });

  testWidgets('«Cerca» filters the display by name only (D-07)', (
    tester,
  ) async {
    await openSheet(tester, _options);

    await tester.enterText(find.byKey(PrizeCatalogueSheet.searchKey), 'AXE');
    await tester.pumpAndSettle();
    expect(itemIds(tester), ['e-axe']);

    await tester.enterText(find.byKey(PrizeCatalogueSheet.searchKey), 'Gatto');
    await tester.pumpAndSettle();
    expect(itemIds(tester), isEmpty);
    await openTab(tester, PrizeCatalogueSheet.petsTab);
    expect(find.text('Gatto di bottega'), findsOneWidget);
    expect(find.text('Cavallo da viaggio'), findsNothing);
  });

  testWidgets('picking calls back and closes', (tester) async {
    await openSheet(tester, _options);

    await tester.tap(find.text('Equipaggiamento e-axe'));
    await tester.pumpAndSettle();

    expect(items.map((item) => item.id), ['e-axe']);
    expect(find.byType(PrizeCatalogueSheet), findsNothing);
    expect(pets, isEmpty);
    expect(spells, isEmpty);
  });

  testWidgets('lists are built lazily (ui-ux)', (tester) async {
    final many = MissionPrizeOptions.tryFromJson(
      missionPrizeOptionsJson(
        loot: [for (var i = 0; i < 40; i++) _loot('l-item-$i')],
      ),
    )!;
    await openSheet(tester, many);

    final list = tester.widget<ListView>(find.byType(ListView).first);
    expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
    expect(find.byType(ItemRow).evaluate().length, lessThan(40));
  });
}
