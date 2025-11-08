import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Genera un ObjectId simile a MongoDB
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

/// Rende maiuscola la prima lettera di ogni parola
String capitalizeWords(String input) {
  return input
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase(),
      )
      .join(' ');
}

Future<void> convertGeoJson(
  String inputPath,
  String outputCitiesPath,
  String outputPOIPath,
) async {
  final file = File(inputPath);
  if (!await file.exists()) {
    print('❌ File non trovato: $inputPath');
    return;
  }

  final content = await file.readAsString();
  final data = jsonDecode(content);

  if (data['features'] == null) {
    print('❌ Il file non contiene un array "features".');
    return;
  }

  // Tipi di città casuali (puoi personalizzare)
  final List<String> possibleTypes = ['valanCity', 'valanVillage'];

  final random = Random();

  final List<Map<String, dynamic>> cities = [];
  final List<Map<String, dynamic>> pois = [];

  for (var feature in data['features']) {
    final props = feature['properties'] ?? {};
    final geom = feature['geometry'] ?? {};

    // ID unici
    final cityId = generateObjectId();
    final markerId = generateObjectId();

    // Nome formattato
    final rawName = props['nome_2']?.toString() ?? 'Unknown';
    final name = capitalizeWords(rawName);

    // Marker location
    final puntoX = props['punto_x'];
    final puntoY = props['punto_y'];
    final markerLocation = [puntoY, puntoX]; // [lat, lon]

    // Area (estrai punti dai poligoni)
    List<List<double>> area = [];
    if (geom['type'] == 'MultiPolygon') {
      for (var polygon in geom['coordinates']) {
        for (var ring in polygon) {
          for (var coord in ring) {
            area.add([coord[1].toDouble(), coord[0].toDouble()]);
          }
        }
      }
    } else if (geom['type'] == 'Polygon') {
      for (var ring in geom['coordinates']) {
        for (var coord in ring) {
          area.add([coord[1].toDouble(), coord[0].toDouble()]);
        }
      }
    }

    // Type casuale
    final type = possibleTypes[random.nextInt(possibleTypes.length)];

    // Oggetto City
    final cityObj = {
      "_id": {"\$oid": cityId},
      "type": type,
      "name": name,
      "markerLocation": {"\$oid": markerId},
      "area": area,
      "pointsOfInterest": [
        {"\$oid": markerId},
      ],
    };
    cities.add(cityObj);

    // Oggetto PointOfInterest
    final poiObj = {
      "_id": {"\$oid": markerId},
      "type": "city",
      "location": markerLocation,
      "city": {"\$oid": cityId},
      "questId": null,
    };
    pois.add(poiObj);
  }

  // Scrivi i due file
  await File(
    outputCitiesPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(cities));
  await File(
    outputPOIPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(pois));

  print('✅ Conversione completata!');
  print('🏙  File città salvato in: $outputCitiesPath');
  print('📍 File POI salvato in: $outputPOIPath');
}

void main(List<String> args) async {
  if (args.length < 3) {
    print(
      'Uso: dart convert_geojson.dart input.geojson output_cities.json output_pois.json',
    );
    return;
  }

  final inputPath = args[0];
  final outputCitiesPath = args[1];
  final outputPOIPath = args[2];

  await convertGeoJson(inputPath, outputCitiesPath, outputPOIPath);
}
