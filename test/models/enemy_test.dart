import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enemy.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/enums/poi_type.dart';
import 'package:klimmeck_guide/models/weaknesses.dart';

void main() {
  const weaknessesJson = {
    'base': ['pierce'],
    'energy': ['cold'],
  };

  Enemy enemyWith(Map<String, dynamic> fields) =>
      Enemy.fromJson({'id': 'e', ...fields});

  test('parses the weaknesses object (D-01)', () {
    final enemy = enemyWith({'weaknesses': weaknessesJson});

    expect(
      enemy.weaknesses,
      const Weaknesses(base: [DamageType.pierce], energy: [EnergyType.cold]),
    );
  });

  test('an enemy without weaknesses has the empty value (D-01)', () {
    expect(enemyWith({}).weaknesses, const Weaknesses());
  });

  test('toJson writes the weaknesses object (D-01)', () {
    final enemy = enemyWith({'weaknesses': weaknessesJson});

    expect(enemy.toJson()['weaknesses'], weaknessesJson);
  });

  test('weaknesses are part of the props (D-01)', () {
    final weak = enemyWith({'weaknesses': weaknessesJson});
    final sturdy = enemyWith({});

    expect(weak, isNot(sturdy));
  });

  test('parses a locations list and drops an unknown name (D-16)', () {
    final enemy = enemyWith({
      'locations': ['city', 'moon'],
    });

    expect(enemy.locations, isA<List<PoiType>>());
    expect(enemy.locations, [PoiType.city]);
    expect(enemyWith({}).locations, isNull);
    expect(enemyWith({'locations': 'city'}).locations, isNull);
  });

  test('the board selection { id name imagePath xp } still parses (D-02)', () {
    final enemy = Enemy.fromJson(const {
      'id': 'e1',
      'name': 'Lupo',
      'imagePath': 'enemies/wolf',
      'xp': 50,
    });

    expect(enemy.id, 'e1');
    expect(enemy.name, 'Lupo');
    expect(enemy.imagePath, 'enemies/wolf');
    expect(enemy.xp, 50);
    expect(enemy.weaknesses, const Weaknesses());
    expect(enemy.locations, isNull);
  });
}
