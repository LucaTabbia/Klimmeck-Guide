import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

List<double> roundCoord(List<double> coord, [int decimals = 6]) {
  return [
    double.parse(coord[0].toStringAsFixed(decimals)),
    double.parse(coord[1].toStringAsFixed(decimals)),
  ];
}

/** * Verifica se un punto (lon, lat) è all'interno di un poligono i cui vertici sono [lon, lat].
 * Utilizza l'algoritmo Ray Casting (o Point-in-Polygon).
 */
bool pointInPolygon(double lon, double lat, List<List<double>> polygon) {
  bool inside = false;

  // Aggiunge l'ultimo punto se non è chiuso (per sicurezza)
  List<List<double>> closedPolygon = List.from(polygon);
  if (closedPolygon.length > 1 &&
      (closedPolygon.first[0] != closedPolygon.last[0] ||
          closedPolygon.first[1] != closedPolygon.last[1])) {
    closedPolygon.add(closedPolygon.first);
  }

  for (
    int i = 0, j = closedPolygon.length - 1;
    i < closedPolygon.length;
    j = i++
  ) {
    // Poligono è [Lon, Lat]:
    double xi = closedPolygon[i][0]; // Longitudine (X)
    double yi = closedPolygon[i][1]; // Latitudine (Y)
    double xj = closedPolygon[j][0];
    double yj = closedPolygon[j][1];

    bool intersect =
        ((yi > lat) != (yj > lat)) &&
        (lon <
            (xj - xi) *
                    (lat - yi) /
                    ((yj - yi).abs() < 1e-12 ? 1e-12 : (yj - yi)) +
                xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

/**
 * Verifica se un POI (tramite le sue coordinate centrali [punto_x=Lon, punto_y=Lat])
 * cade all'interno dell'Area di una Città.
 */
bool poiInCity(Map<String, dynamic> poi, Map<String, dynamic> city) {
  final properties = poi['properties'] ?? {};

  // Estrai il punto POI. Assumiamo punto_x=Lon e punto_y=Lat (standard GeoJSON)
  final puntoLon = (properties['punto_x'] as num?)?.toDouble();
  final puntoLat = (properties['punto_y'] as num?)?.toDouble();

  // Aggiunta guardia per i nulli (già gestita nel main, ma utile qui)
  if (puntoLon == null || puntoLat == null) return false;

  // Area della Città è in [Lat, Lon] nel file sorgente!
  final cityAreaLatLon = (city['area'] as List);

  // 1. Inverti l'Area della Città in [Lon, Lat] per la compatibilità con pointInPolygon
  final cityAreaLonLat = cityAreaLatLon
      .map<List<double>>(
        (p) => [(p[1] as num).toDouble(), (p[0] as num).toDouble()],
      )
      .toList();

  // 2. Esegui il controllo (puntoLon, puntoLat, Poligono [Lon, Lat])
  return pointInPolygon(puntoLon, puntoLat, cityAreaLonLat);
}

// -----------------------------------------------------------------

void main(List<String> args) async {
  if (args.length < 2) {
    print('❌ Uso: dart assign_poi.dart <citta.json> <poi.geojson>');
    exit(1);
  }

  final cityFile = File(args[0]);
  final poiFile = File(args[1]);

  if (!await cityFile.exists() || !await poiFile.exists()) {
    print('❌ Uno dei file non esiste.');
    exit(1);
  }

  final cities = jsonDecode(await cityFile.readAsString());
  final poiData = jsonDecode(await poiFile.readAsString());

  final poiFeatures =
      poiData['features'] ?? (poiData is List ? poiData : [poiData]);

  final List<Map<String, dynamic>> allNewPois = [];
  int totalAssigned = 0;

  // Lista per tracciare i POI non aggiunti e la ragione
  final List<Map<String, dynamic>> excludedPois = [];

  final int totalFeatures = poiFeatures.length;

  for (final feature in poiFeatures) {
    final props = feature['properties'] ?? {};
    final puntoLon = props['punto_x']?.toDouble();
    final puntoLat = props['punto_y']?.toDouble();

    final poiIdentifier =
        props['nome'] ?? props['id']?.toString() ?? 'Senza ID';

    if (puntoLon == null || puntoLat == null) {
      // 1. POI Scartato: Coordinate Mancanti
      excludedPois.add({
        'identifier': poiIdentifier,
        'reason': 'Coordinate punto_x o punto_y mancanti/nulle',
        'feature': feature,
      });
      continue;
    }

    // Usiamo una lista temporanea per i POI di questa feature, dato che può essere in più città
    final List<Map<String, String>> poiOidsForFeature = [];
    bool addedToAnyCity = false;

    // Itera su TUTTE le città
    for (final city in cities) {
      final cityId = city['_id']['\$oid'];

      city['pointsOfInterest'] ??= [];
      final existingPoiIds = (city['pointsOfInterest'] as List)
          .map((e) => e['\$oid'] as String)
          .toSet();

      // 2. Controllo Geografico
      if (poiInCity(feature, city)) {
        final newId = generateObjectId();

        final newPoi = {
          '_id': {'\$oid': newId},
          'type': [
            props['type'],
            props['type_2'],
            props['type_3'],
          ].where((e) => e != null && e.toString().trim().isNotEmpty).toList(),
          'location': roundCoord([puntoLat, puntoLon]),
          'city': {'\$oid': cityId},
          'questId': null,
        };

        // Aggiunge all'output totale
        allNewPois.add(newPoi);

        // Aggiorna la lista di POI per la città (prevenendo duplicati nel caso di esecuzioni multiple)
        final poiRef = {'\$oid': newId};
        if (!existingPoiIds.contains(newId)) {
          city['pointsOfInterest'].add(poiRef);
        }

        poiOidsForFeature.add(poiRef);
        addedToAnyCity = true;
      }
    }

    // Se la feature non è stata assegnata a NESSUNA città
    if (!addedToAnyCity) {
      excludedPois.add({
        'identifier': poiIdentifier,
        'reason': 'Non interseca l\'area di NESSUNA città',
      });
    } else {
      // Se è stata aggiunta, conta una volta sola la feature originale
      totalAssigned++;
    }
  }

  // --- Scrittura dei File di Output ---

  await File(
    'generated_pois.json',
  ).writeAsString(JsonEncoder.withIndent('  ').convert(allNewPois));

  await File(
    'updated_cities.json',
  ).writeAsString(JsonEncoder.withIndent('  ').convert(cities));

  print('\n--- Risultato Assegnazione POI ---');
  print('Iniziale (File): ${totalFeatures} elementi');
  print('Assegnati ad almeno una città: ${totalAssigned} elementi');
  print('Scartati/Non Assegnati: ${excludedPois.length} elementi');

  if (excludedPois.isNotEmpty) {
    print('\n🚨 I POI esclusi (${excludedPois.length}) sono:');
    for (final excluded in excludedPois) {
      print('   - [${excluded['reason']}]: ${excluded['identifier']}');
    }
    await File(
      'excluded_pois_for_debugging.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(excludedPois));
    print('\nFile "excluded_pois_for_debugging.json" creato per ispezione.');
  } else {
    print(
      '\n✅ Tutti i POI sono stati assegnati ad almeno una città o scartati per coordinate mancanti.',
    );
  }
}
