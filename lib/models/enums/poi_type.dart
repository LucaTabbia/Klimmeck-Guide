enum PoiType {
  battleground('Campo di battaglia'),
  all('Ovunque'),
  vulcano('Vulcano'),
  ruins('Rovine'),
  dungeon('Sotterraneo'),
  city('Città'),
  graveyard('Cimitero'),
  swamp('Palude'),
  oasis('Oasi'),
  harkenIsland('Isola di Harken'),
  hills('Colline'),
  minnelyForest('Foresta di Minnely'),
  farNorth('Estremo Nord'),
  drusteaPlains('Pianure di Drustea'),
  undergroundLamstone('Sottosuolo di Lamstone'),
  mountainLamstone('Monte Lamstone'),
  glounet('Glounet'),
  desert('Deserto'),
  liberiaIsland('Isola di Liberia'),
  valanPlains('Pianure di Valan'),
  belleholmLake('Lago di Belleholm'),
  belleholmIsland('Isola di Belleholm'),
  temistosLake('Lago di Temistos'),
  undergroundTemistos('Sottosuolo di Temistos'),
  ladows('Ladows'),
  delants('Delants'),
  mountainTemistos('Monte Temistos'),
  forest('Foresta'),
  demonicPortal('Portale demoniaco');

  const PoiType(this.label);

  /// Nome del tipo di luogo mostrato all'oste (D-29), copy proposta: l'utente
  /// la rivede alla UAT.
  final String label;
}

/// Lista tollerante di tipi di punto d'interesse: un nome che il client non
/// conosce è scartato, ciò che non è una lista vale `null`.
List<PoiType>? poiTypesFrom(Object? json) {
  if (json is! List) return null;
  final byName = PoiType.values.asNameMap();
  return List<PoiType>.unmodifiable(json.map((name) => byName[name]).nonNulls);
}
