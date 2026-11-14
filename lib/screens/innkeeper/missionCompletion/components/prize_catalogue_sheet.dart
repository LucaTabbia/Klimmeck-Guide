import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Catalogo dei premi servito dal BE (D-07): l'app lo mostra com'è, la
/// ricerca filtra solo la vista per nome (regola 4). Toccare una voce la
/// passa a chi chiama e chiude il foglio.
class PrizeCatalogueSheet extends StatefulWidget {
  const PrizeCatalogueSheet({
    super.key,
    required this.options,
    required this.onPickItem,
    required this.onPickPet,
    required this.onPickSpell,
  });

  static const String itemsTab = 'Oggetti';
  static const String petsTab = 'Compagni';
  static const String spellsTab = 'Magie';
  static const String searchLabel = 'Cerca';
  static const Key searchKey = ValueKey('mission.catalogue.search');

  final MissionPrizeOptions options;
  final ValueChanged<AssetItem> onPickItem;
  final ValueChanged<Pet> onPickPet;
  final ValueChanged<Spell> onPickSpell;

  @override
  State<PrizeCatalogueSheet> createState() => _PrizeCatalogueSheetState();
}

class _PrizeCatalogueSheetState extends State<PrizeCatalogueSheet> {
  static const double _entrySize = 48;

  String _query = '';

  bool _matches(String? name) =>
      (name ?? '').toLowerCase().contains(_query.trim().toLowerCase());

  List<Pet> get _pets {
    final blockPet = widget.options.blockPet;
    final pets = widget.options.pets;
    final isListed = pets.any((pet) => pet.id == blockPet?.id);
    return [...pets, if (!isListed) ?blockPet];
  }

  List<Spell> get _spells {
    final blockSpell = widget.options.blockSpell;
    final spells = widget.options.spells;
    final isListed = spells.any((spell) => spell.id == blockSpell?.id);
    return [...spells, if (!isListed) ?blockSpell];
  }

  void _pick<T>(ValueChanged<T> onPick, T entry) {
    onPick(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.options.catalogueItems
        .where((item) => _matches(item.name))
        .toList();
    final pets = _pets.where((pet) => _matches(pet.name)).toList();
    final spells = _spells.where((spell) => _matches(spell.name)).toList();
    return DecoratedBox(
      decoration: KlimmeckGuideTheme.getParchmentBackground(),
      child: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingSm),
                child: TextField(
                  key: PrizeCatalogueSheet.searchKey,
                  decoration: const InputDecoration(
                    labelText: PrizeCatalogueSheet.searchLabel,
                  ),
                  onChanged: (query) => setState(() => _query = query),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: PrizeCatalogueSheet.itemsTab),
                  Tab(text: PrizeCatalogueSheet.petsTab),
                  Tab(text: PrizeCatalogueSheet.spellsTab),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, index) => _itemEntry(items[index]),
                    ),
                    ListView.builder(
                      itemCount: pets.length,
                      itemBuilder: (_, index) => CompanionRow(
                        pet: pets[index],
                        size: _entrySize,
                        showCoins: false,
                        onTap: () => _pick(widget.onPickPet, pets[index]),
                      ),
                    ),
                    ListView.builder(
                      itemCount: spells.length,
                      itemBuilder: (_, index) => _spellEntry(spells[index]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemEntry(AssetItem item) {
    return InkWell(
      onTap: () => _pick(widget.onPickItem, item),
      child: ItemRow(
        assetItem: item,
        showCoins: false,
        size: _entrySize,
        onSelect: (_) => _pick(widget.onPickItem, item),
      ),
    );
  }

  Widget _spellEntry(Spell spell) {
    return InkWell(
      onTap: () => _pick(widget.onPickSpell, spell),
      child: Padding(
        padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingSm),
        child: Row(
          children: [
            SpellCard(spell: spell, size: _entrySize),
            const SizedBox(width: KlimmeckGuideTheme.spacingSm),
            Expanded(
              child: Text(
                spell.name ?? '',
                style: KlimmeckGuideTheme.instance.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
