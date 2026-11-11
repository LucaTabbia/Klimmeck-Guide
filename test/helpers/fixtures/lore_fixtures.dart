/// Lore sul filo come la seleziona `LoreQueries` (`id imagePath type name
/// description relatedLore { id name }`); di default una città senza immagine.
Map<String, dynamic> loreJson({
  String id = 'lore-1',
  String type = 'city',
  String name = 'Talmvere',
  String? description = 'Un villaggio',
  String? image,
}) => {
  'id': id,
  'type': type,
  'name': name,
  'description': description,
  'imagePath': image,
  'relatedLore': const <Map<String, dynamic>>[],
};

/// Voce di `QuestResult.loreUnlocked` (BE Phase 16): selezione `{ id name type }`.
Map<String, dynamic> loreRefJson({
  String id = 'lore-goblin',
  String name = 'Goblin',
  String type = 'enemy',
}) => {'id': id, 'name': name, 'type': type};
