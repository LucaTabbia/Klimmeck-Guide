/// Posizione del marker di partenza sul filo (stesso ordine di `PointOfInterest.location`).
const List<double> departureWire = [10.0, 20.0];

/// Posizione del marker di arrivo sul filo.
const List<double> destinationWire = [12.0, 23.0];

Map<String, dynamic> travelPathJson({
  List<List<double>> coordinates = const [
    departureWire,
    [11.0, 21.0],
    destinationWire,
  ],
  double distance = 15.8,
}) => {'coordinates': coordinates, 'distance': distance};

/// Viaggio di 2 h 40 min (9 600 000 ms) partito alle 10:00 UTC.
Map<String, dynamic> activeTravelJson({
  String startTime = '2026-10-24T10:00:00.000Z',
  String endTime = '2026-10-24T12:40:00.000Z',
  double duration = 9600000,
  String to = 'city-marker-2',
  Map<String, dynamic>? road,
}) => {
  'road': road ?? travelPathJson(),
  'startTime': startTime,
  'endTime': endTime,
  'duration': duration,
  'to': to,
};

/// Voce `TravelFoodItem` sul filo (BE Phase 14 D-09): selezione `food { quantity item { id name } }`.
Map<String, dynamic> travelFoodItemJson({
  String id = 'loot-ration',
  String? name = 'Razione da viaggio',
  int quantity = 1,
}) => {
  'quantity': quantity,
  'item': {'id': id, 'name': name},
};

/// Senza `food`/`hpLost`/`arrivesAlive` è la forma di un BE più vecchio.
Map<String, dynamic> travelPreviewJson({
  double distance = 15.8,
  double duration = 9600000,
  Map<String, dynamic>? road,
  List<Map<String, dynamic>>? food,
  int? hpLost,
  bool? arrivesAlive,
}) => {
  'distance': distance,
  'duration': duration,
  'road': road ?? travelPathJson(),
  if (food != null) 'food': food,
  if (hpLost != null) 'hpLost': hpLost,
  if (arrivesAlive != null) 'arrivesAlive': arrivesAlive,
};

/// Ferito in attesa di soccorso dalle 11:00 UTC (09-CONTEXT D-16).
Map<String, dynamic> awaitingAidJson({
  String quest = 'q-1',
  String aidQuest = 'aid-1',
  String since = '2026-10-27T11:00:00.000Z',
}) => {'quest': quest, 'aidQuest': aidQuest, 'since': since};

/// Personaggio con pedina (infos.sex), posizione sul marker di partenza e,
/// a scelta, un viaggio, una corsia standard, lo stato di ferito e i due flag
/// della missione in corso (FE Phase 21 D-16).
Map<String, dynamic> travellingCharacterJson({
  String id = 'c-1',
  String locationId = 'city-marker-1',
  List<double> location = departureWire,
  Map<String, dynamic>? activeTravel,
  Map<String, dynamic>? pendingQuest,
  Map<String, dynamic>? awaitingAid,
  String? imprisonedUntil,
  bool? missionInProgress,
  bool? guidedMissionInProgress,
}) => {
  'id': id,
  'infos': {'name': 'Aldo', 'sex': 'male'},
  'status': {
    'title': 'rookie',
    'location': {'id': locationId, 'location': location},
    'activeTravel': activeTravel,
    if (awaitingAid != null) 'awaitingAid': awaitingAid,
    if (imprisonedUntil != null) 'imprisonedUntil': imprisonedUntil,
    if (missionInProgress != null) 'missionInProgress': missionInProgress,
    if (guidedMissionInProgress != null)
      'guidedMissionInProgress': guidedMissionInProgress,
  },
  'quests': {
    'completedQuests': const [],
    'pendingQuest': pendingQuest,
    'activeStoryQuest': null,
    'activeWorldMissionQuest': null,
  },
};

/// Città con marker e lore (immagine per il foglio di conferma, D-03).
Map<String, dynamic> travelCityJson({
  String id = 'city-2',
  String name = 'Valdoria',
  String markerId = 'city-marker-2',
  List<double> marker = destinationWire,
  String? image = 'https://res.cloudinary.com/demo/valdoria.svg',
}) => {
  'id': id,
  'name': name,
  'markerLocation': {'id': markerId, 'location': marker},
  'relatedLore': {
    'id': 'lore-$id',
    'description': 'Lore di $name',
    'imagePath': image,
  },
};

/// Luogo del mondo come lo serve `pointOfInterests` (D-29): rovine presso
/// Talmvere; `latitude: null` toglie il punto, `cityId: null` la città.
Map<String, dynamic> pointOfInterestJson({
  String id = 'poi-ruins-1',
  List<String> types = const ['ruins'],
  double? latitude = 12,
  double? longitude = 22,
  String? cityId = 'city-talmvere',
  String? cityName = 'Talmvere',
}) => {
  'id': id,
  'type': types,
  'location': latitude == null || longitude == null
      ? null
      : [latitude, longitude],
  'city': cityId == null ? null : {'id': cityId, 'name': cityName},
};
