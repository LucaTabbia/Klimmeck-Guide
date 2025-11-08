import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Genera un ObjectId stile MongoDB
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

/// Conversione del GeoJSON in JSON personalizzato
Future<void> convertRoads(String inputPath, String outputPath) async {
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

  final results = <Map<String, dynamic>>[];

  for (final feature in data['features']) {
    final props = feature['properties'] ?? {};
    final geom = feature['geometry'] ?? {};

    if (geom['type'] != 'LineString') continue;

    final coordinates = (geom['coordinates'] as List)
        .map((coord) => [coord[1].toDouble(), coord[0].toDouble()])
        .toList();

    // La lunghezza fornita da QGIS è in metri
    final lengthMeters = props['length'] ?? 0.0;
    final lengthKm = lengthMeters;

    final speedFactor = props['speedFactor'] ?? 1.0;
    final id = generateObjectId();

    results.add({
      "_id": {"\$oid": id},
      "coordinates": coordinates,
      "speedFactor": speedFactor,
      "lengthKm": lengthKm,
    });
  }

  final outputFile = File(outputPath);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(results),
  );

  print('✅ Conversione completata!');
  print('📁 File salvato in: $outputPath');
}

void main(List<String> args) async {
  if (args.length < 2) {
    print('Uso: dart convert_roads_from_qgis.dart input.geojson output.json');
    return;
  }

  await convertRoads(args[0], args[1]);
}
