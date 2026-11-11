enum PoiType {
  battleground,
  all,
  vulcano,
  ruins,
  dungeon,
  city,
  graveyard,
  swamp,
  oasis,
  harkenIsland,
  hills,
  minnelyForest,
  farNorth,
  drusteaPlains,
  undergroundLamstone,
  mountainLamstone,
  glounet,
  desert,
  liberiaIsland,
  valanPlains,
  belleholmLake,
  belleholmIsland,
  temistosLake,
  undergroundTemistos,
  ladows,
  delants,
  mountainTemistos,
  forest,
}

/// Lista tollerante di tipi di punto d'interesse: un nome che il client non
/// conosce è scartato, ciò che non è una lista vale `null`.
List<PoiType>? poiTypesFrom(Object? json) {
  if (json is! List) return null;
  final byName = PoiType.values.asNameMap();
  return List<PoiType>.unmodifiable(json.map((name) => byName[name]).nonNulls);
}
