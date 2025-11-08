import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Funzione per generare un ObjectId (simulato)
String generateObjectId() {
  final random = Random();
  final secondsSinceEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final secondsHex = secondsSinceEpoch.toRadixString(16).padLeft(8, '0');
  final randomHex = List.generate(
    16,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return secondsHex + randomHex.substring(0, 16);
}

// Funzione per arrotondare le coordinate
List<double> roundCoord(List<double> coord, [int decimals = 6]) {
  return [
    double.parse(coord[0].toStringAsFixed(decimals)),
    double.parse(coord[1].toStringAsFixed(decimals)),
  ];
}

// -----------------------------------------------------------------

void main(List<String> args) async {
  if (args.length < 2) {
    print('❌ Uso: dart assign_poi_by_name.dart <citta.json> <poi.geojson>');
    exit(1);
  }

  final cityFile = File(args[0]);
  final poiFile = File(args[1]);

  if (!await cityFile.exists() || !await poiFile.exists()) {
    print('❌ Uno dei file non esiste.');
    exit(1);
  }

  // Caricamento Dati
  final List<dynamic> cities = jsonDecode(await cityFile.readAsString());
  final poiData = jsonDecode(await poiFile.readAsString());

  // I POI sono Feature GeoJSON (se GeoJSON FeatureCollection)
  final List<dynamic> poiFeatures =
      poiData['features'] ?? (poiData is List ? poiData : [poiData]);

  // Mappa per cercare rapidamente l'ID della città dal suo nome
  final Map<String, Map<String, dynamic>> cityMap = {};
  for (final city in cities) {
    final cityName = (city['name'] as String).trim();
    cityMap[cityName] = city;
    city['pointsOfInterest'] ??= [];
  }

  final List<Map<String, dynamic>> allNewPois = [];
  int totalAssigned = 0;

  // Lista per tracciare i POI non aggiunti (senza corrispondenza nome città)
  final List<Map<String, dynamic>> excludedPois = [];

  print('Inizio processamento di ${poiFeatures.length} POI...');

  for (final feature in poiFeatures) {
    final props = feature['properties'] ?? {};
    final geometry = feature['geometry'] ?? {};

    // 1. Estrai l'ID del POI e le coordinate
    final poiType = props['type'] as String? ?? 'generic';
    final poiCityName = props['city'] as String?;
    final coordinates = geometry['coordinates'] as List<dynamic>?;

    // Il formato GeoJSON "Point" è [Longitude, Latitude]
    final lon = (coordinates?[0] as num?)?.toDouble();
    final lat = (coordinates?[1] as num?)?.toDouble();

    final poiIdentifier =
        props['nome'] ?? props['fid']?.toString() ?? 'Senza ID';

    if (lon == null ||
        lat == null ||
        poiCityName == null ||
        poiCityName.isEmpty) {
      // POI Scartato: Coordinate o Nome Città mancanti
      excludedPois.add({
        'identifier': poiIdentifier,
        'reason': 'Coordinate o campo "city" mancante/nullo.',
        'feature': feature,
      });
      continue;
    }

    final city = cityMap[poiCityName.trim()];

    if (city == null) {
      // POI Scartato: Nome Città non trovato
      excludedPois.add({
        'identifier': poiIdentifier,
        'reason':
            'Nome città "${poiCityName.trim()}" non trovato nel file delle città.',
      });
      continue;
    }

    // Città trovata
    final cityId = city['_id']['\$oid'];
    final markerId = generateObjectId();

    // 2. Creazione dell'oggetto POI per il DB
    // I tuoi dati POI sono in [Lon, Lat], usiamo lo stesso ordine per il DB.
    final poiObj = {
      "_id": {"\$oid": markerId},
      "type": [poiType], // Usa il campo type del POI
      "location": roundCoord([lat, lon]),
      "city": {"\$oid": cityId},
      "questId": null,
    };

    allNewPois.add(poiObj);
    totalAssigned++;

    // 3. Aggiornamento del campo pointsOfInterest nella città
    final poiRef = {'\$oid': markerId};

    // Aggiungiamo il riferimento solo se non è già presente
    final existingPoiIds = (city['pointsOfInterest'] as List)
        .map((e) => e['\$oid'] as String)
        .toSet();

    if (!existingPoiIds.contains(markerId)) {
      city['pointsOfInterest'].add(poiRef);
    }
  }

  // --- Scrittura dei File di Output ---

  await File(
    'generated_db_pois.json',
  ).writeAsString(JsonEncoder.withIndent('  ').convert(allNewPois));

  await File(
    'updated_cities_sea.json',
  ).writeAsString(JsonEncoder.withIndent('  ').convert(cities));

  print('\n--- Risultato Assegnazione POI per Nome Città ---');
  print('POI totali nel file: ${poiFeatures.length}');
  print('POI assegnati correttamente: ${totalAssigned}');
  print('POI scartati: ${excludedPois.length}');

  if (excludedPois.isNotEmpty) {
    print('\n🚨 I POI esclusi sono:');
    for (final excluded in excludedPois) {
      print('   - [${excluded['reason']}]: ${excluded['identifier']}');
    }
    await File(
      'excluded_pois_for_debugging.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(excludedPois));
    print('\nFile "excluded_pois_for_debugging.json" creato per ispezione.');
  } else {
    print(
      '\n✅ Tutti i POI sono stati assegnati correttamente in base al campo "city".',
    );
  }
}
