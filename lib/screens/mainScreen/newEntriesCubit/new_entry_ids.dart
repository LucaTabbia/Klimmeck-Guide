import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';

/// Le voci che il personaggio ha ora, per categoria: ciò che `NewEntriesCubit`
/// confronta con il già visto. Una ferita si riconosce dal nome, una voce di
/// background dal suo testo, il resto dall'id a catalogo.
Map<NewEntryCategory, Set<String>> newEntryIdsOf(Character character) {
  final status = character.status;
  final assets = character.assets;
  return {
    NewEntryCategory.spells: {
      for (final state in status?.spellStates ?? const <SpellState>[])
        state.spell.id,
    },
    NewEntryCategory.companions: {
      for (final owned in assets?.ownedPets ?? const <OwnedPet>[]) owned.pet.id,
    },
    NewEntryCategory.equipment: _assetIdsOf(assets?.ownedEquipments),
    NewEntryCategory.injuries: {
      for (final injury in status?.injuries ?? const <InjuryType>[])
        injury.name,
    },
    NewEntryCategory.items: _assetIdsOf(assets?.ownedItems),
    NewEntryCategory.background: {...?character.infos?.background},
  };
}

Set<String> _assetIdsOf(List<AssetQuantity>? owned) => {
  for (final entry in owned ?? const <AssetQuantity>[])
    if (entry.item case final item?) item.id,
};
