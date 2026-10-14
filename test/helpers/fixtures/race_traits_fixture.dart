import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';

/// Specchio della tabella età/razza del lore (D-10). Solo nei test: in lib/ la
/// tabella arriva dal backend (D-11).
const List<Map<String, Object>> raceTraitsJson = [
  {'race': 'human', 'minAge': 16, 'maxAge': 200},
  {'race': 'elf', 'minAge': 100, 'maxAge': 9999},
  {'race': 'halfelf', 'minAge': 16, 'maxAge': 130},
  {'race': 'dwarf', 'minAge': 40, 'maxAge': 140},
  {'race': 'gnome', 'minAge': 16, 'maxAge': 60},
  {'race': 'halfling', 'minAge': 16, 'maxAge': 70},
  {'race': 'dragonborn', 'minAge': 16, 'maxAge': 180},
  {'race': 'tiefling', 'minAge': 16, 'maxAge': 120},
  {'race': 'aarakocra', 'minAge': 3, 'maxAge': 40},
];

final Map<RaceType, RaceTraits> testRaceTraits = Map.unmodifiable({
  for (final json in raceTraitsJson)
    RaceType.values.byName(json['race']! as String): RaceTraits.fromJson(json),
});
