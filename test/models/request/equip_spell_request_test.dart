import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/request/equip_spell_request.dart';

void main() {
  group('EquipSpellRequest', () {
    test('serialises the character id as id and the spell id as spellId', () {
      const request = EquipSpellRequest(id: 'c-1', spellId: 'spell-1');

      expect(request.toJson(), {'id': 'c-1', 'spellId': 'spell-1'});
    });

    test('never sends the deprecated usages field', () {
      const request = EquipSpellRequest(id: 'c-1', spellId: 'spell-1');

      expect(request.toJson().containsKey('usages'), isFalse);
    });

    test('is equal by id and spellId', () {
      expect(
        const EquipSpellRequest(id: 'c-1', spellId: 'spell-1'),
        const EquipSpellRequest(id: 'c-1', spellId: 'spell-1'),
      );
      expect(
        const EquipSpellRequest(id: 'c-1', spellId: 'spell-1'),
        isNot(const EquipSpellRequest(id: 'c-1', spellId: 'spell-2')),
      );
    });
  });
}
