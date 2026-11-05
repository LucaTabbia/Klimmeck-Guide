import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/utils/spell_lines.dart';

void main() {
  test('wire names end with heal (quick 251105)', () {
    expect(UseType.values.map((type) => type.name), [
      'defense',
      'attack',
      'control',
      'illusion',
      'charm',
      'confuse',
      'enhance',
      'infuse',
      'heal',
    ]);
  });

  test('heal reads Cura and has an icon (quick 251105)', () {
    expect(UseType.heal.label, 'Cura');
    expect(UseType.heal.imagePath, isNotEmpty);
  });

  test('a heal spell parses and labels its power as a cure (quick 251105)', () {
    final spell = Spell.fromJson({
      'id': 's1',
      'name': 'Tocco Guaritore',
      'useType': 'heal',
      'energyDamage': {'type': 'radiant', 'power': 600},
    });
    expect(spell.useType, UseType.heal);
    expect(
      spellDamageLabel(
        const EnergyDamage(type: EnergyType.radiant, power: 600),
        useType: UseType.heal,
      ),
      'Cura: Radioso 600',
    );
  });

  test('an unknown use type parses as null instead of throwing', () {
    final spell = Spell.fromJson({'id': 's2', 'useType': 'teleport'});
    expect(spell.useType, isNull);
  });
}
