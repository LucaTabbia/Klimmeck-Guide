import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/mission/mission_entries.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest/quest_cure.dart';
import 'package:klimmeck_guide/models/spell.dart';

/// Catalogo dei premi di un personaggio servito dal BE (D-07): già filtrato
/// per rango, l'app lo mostra com'è e non filtra mai (regola 4). Il blocco
/// serve solo a dare un nome alle voci della bozza e a dire se la cura si può
/// rimettere (D-22).
class MissionPrizeOptions extends Equatable {
  const MissionPrizeOptions({
    required this.characterId,
    this.title,
    this.maxRarity,
    this.equipment = const [],
    this.loot = const [],
    this.pets = const [],
    this.spells = const [],
    this.blockItems = const [],
    this.blockPet,
    this.blockSpell,
    this.blockCure,
  });

  final String characterId;
  final TitleType? title;
  final RarityType? maxRarity;
  final List<EquipmentItem> equipment;
  final List<LootItem> loot;
  final List<Pet> pets;
  final List<Spell> spells;

  /// Oggetti del blocco del rango (`prizeItem` e `randomLoot`), in ordine.
  final List<AssetItem> blockItems;
  final Pet? blockPet;
  final Spell? blockSpell;

  /// Cura del blocco: il BE accetta `cure: true` solo quando c'è.
  final QuestCure? blockCure;

  /// Equipaggiamento e loot serviti, poi le voci del blocco non già elencate.
  List<AssetItem> get catalogueItems {
    final listed = <AssetItem>[...equipment, ...loot];
    final listedIds = {for (final item in listed) item.id};
    return List.unmodifiable([
      ...listed,
      ...blockItems.where((item) => !listedIds.contains(item.id)),
    ]);
  }

  /// Solo per mostrare una voce: catalogo e blocco.
  AssetItem? itemById(String id) => _firstWithId(catalogueItems, id, _itemId);

  Pet? petById(String id) =>
      _firstWithId([...pets, ?blockPet], id, (pet) => pet.id);

  Spell? spellById(String id) =>
      _firstWithId([...spells, ?blockSpell], id, (spell) => spell.id);

  static String _itemId(AssetItem item) => item.id;

  static T? _firstWithId<T>(
    Iterable<T> entries,
    String id,
    String Function(T entry) idOf,
  ) {
    for (final entry in entries) {
      if (idOf(entry) == id) return entry;
    }
    return null;
  }

  /// Confine di parsing: senza `character` vale `null`; una voce del catalogo
  /// o del blocco che non si legge è scartata (Pitfall 8).
  static MissionPrizeOptions? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final characterId = json['character'];
    if (characterId is! String) return null;
    final block = json['block'];
    final blockJson = block is Map<String, dynamic>
        ? block
        : const <String, dynamic>{};
    return MissionPrizeOptions(
      characterId: characterId,
      title: TitleType.values.asNameMap()[json['title']],
      maxRarity: RarityType.values.asNameMap()[json['maxRarity']],
      equipment: missionEntriesOf(json['equipment'], EquipmentItem.tryFromJson),
      loot: missionEntriesOf(json['loot'], _lootOrNull),
      pets: missionEntriesOf(json['pets'], Pet.tryFromEntryJson),
      spells: missionEntriesOf(json['spells'], _spellOrNull),
      blockItems: _blockItemsOf(blockJson),
      blockPet: Pet.tryFromEntryJson(blockJson['pet']),
      blockSpell: _spellOrNull(blockJson['spell']),
      blockCure: QuestCure.tryFromJson(blockJson['cure']),
    );
  }

  static List<AssetItem> _blockItemsOf(Map<String, dynamic> block) {
    final randomLoot = block['randomLoot'];
    final entries = [block['prizeItem'], if (randomLoot is List) ...randomLoot];
    return missionEntriesOf(
      entries,
      (entry) => AssetQuantity.tryFromJson(entry)?.item,
    );
  }

  static LootItem? _lootOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return LootItem.fromJson(json);
    } on Object {
      return null;
    }
  }

  static Spell? _spellOrNull(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! String) return null;
    try {
      return Spell.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    characterId,
    title,
    maxRarity,
    equipment,
    loot,
    pets,
    spells,
    blockItems,
    blockPet,
    blockSpell,
    blockCure,
  ];
}
