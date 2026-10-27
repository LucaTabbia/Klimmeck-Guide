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

Map<String, dynamic> travelPreviewJson({
  double distance = 15.8,
  double duration = 9600000,
  Map<String, dynamic>? road,
}) => {
  'distance': distance,
  'duration': duration,
  'road': road ?? travelPathJson(),
};

/// Ferito in attesa di soccorso dalle 11:00 UTC (09-CONTEXT D-16).
Map<String, dynamic> awaitingAidJson({
  String quest = 'q-1',
  String aidQuest = 'aid-1',
  String since = '2026-10-27T11:00:00.000Z',
}) => {'quest': quest, 'aidQuest': aidQuest, 'since': since};

/// Personaggio con pedina (infos.sex), posizione sul marker di partenza e,
/// a scelta, un viaggio, una corsia standard e lo stato di ferito.
Map<String, dynamic> travellingCharacterJson({
  String id = 'c-1',
  String locationId = 'city-marker-1',
  List<double> location = departureWire,
  Map<String, dynamic>? activeTravel,
  Map<String, dynamic>? pendingQuest,
  Map<String, dynamic>? awaitingAid,
}) => {
  'id': id,
  'infos': {'name': 'Aldo', 'sex': 'male'},
  'status': {
    'title': 'rookie',
    'location': {'id': locationId, 'location': location},
    'activeTravel': activeTravel,
    if (awaitingAid != null) 'awaitingAid': awaitingAid,
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
    'image': image,
  },
};
