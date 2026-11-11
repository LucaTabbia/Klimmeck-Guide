Map<String, dynamic> coinsJson({
  int gold = 0,
  int silver = 0,
  int copper = 0,
}) => {'gold': gold, 'silver': silver, 'copper': copper};

/// Cavallo da viaggio (BE Phase 11 inventory): 1 oro / 50 ag, velocità ×2.
Map<String, dynamic> petJson({
  String id = 'pet-travel-horse',
  String name = 'Cavallo da viaggio',
  num? speedModifier = 2,
  bool? sellable = true,
  Map<String, dynamic>? buyPrice,
  Map<String, dynamic>? sellPrice,
  int? maxXp,
  Map<String, dynamic>? attack,
  Map<String, dynamic>? defense,
  String? rarity,
}) => {
  'id': id,
  'name': name,
  'speedModifier': speedModifier,
  'sellable': sellable,
  'buyPrice': buyPrice ?? coinsJson(gold: 1),
  'sellPrice': sellPrice ?? coinsJson(silver: 50),
  if (maxXp != null) 'maxXp': maxXp,
  if (attack != null) 'attack': attack,
  if (defense != null) 'defense': defense,
  if (rarity != null) 'rarity': rarity,
};

/// Compagno posseduto nella forma della BE Phase 19 (D-03).
Map<String, dynamic> ownedPetJson({
  Map<String, dynamic>? pet,
  int xp = 0,
  int currentLifePoints = 10,
}) => {
  'pet': pet ?? petJson(),
  'xp': xp,
  'currentLifePoints': currentLifePoints,
};

/// Compagno non da sella (gatto): nessuna velocità (D-07).
Map<String, dynamic> catPetJson() => petJson(
  id: 'pet-cat',
  name: 'Gatto di bottega',
  speedModifier: null,
  buyPrice: coinsJson(silver: 20),
  sellPrice: coinsJson(silver: 10),
);

Map<String, dynamic> equipmentAssetJson({
  String id = 'e-sword',
  String rarity = 'common',
  int quantity = 1,
}) => {
  'quantity': quantity,
  'item': {
    'id': id,
    'name': id,
    'description': 'Equipaggiamento $id',
    'equipType': 'weapon',
    'rarity': rarity,
    'buyPrice': coinsJson(silver: 30),
    'sellPrice': coinsJson(silver: 15),
  },
};

Map<String, dynamic> lootAssetJson({
  String id = 'l-potion',
  int quantity = 1,
}) => {
  'quantity': quantity,
  'item': {
    'id': id,
    'name': id,
    'description': 'Oggetto $id',
    'effect': 'heal',
    'power': 3,
    'buyPrice': coinsJson(silver: 5),
    'sellPrice': coinsJson(silver: 2),
  },
};

Map<String, dynamic> cityShopJson({
  String cityId = 'city-talmvere',
  List<Map<String, dynamic>>? equipment,
  List<Map<String, dynamic>>? loot,
  List<Map<String, dynamic>>? pets,
}) => {
  'city': {'id': cityId},
  'equipment': equipment ?? [equipmentAssetJson()],
  'loot': loot ?? [lootAssetJson()],
  'pets': pets ?? [petJson()],
};
