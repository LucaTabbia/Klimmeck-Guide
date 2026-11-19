import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entry_ids.dart';

import '../../../helpers/fixtures/potion_fixtures.dart';
import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/fixtures/spell_fixtures.dart';

void main() {
  test('lists what the character owns, category by category', () {
    final character = Character.fromJson({
      'id': 'c-1',
      'infos': {
        'name': 'Aria',
        'background': ['Nata a Drustea.', 'Ha salvato Bosa.'],
      },
      'status': {
        'injuries': ['headConcussion'],
        'spellStates': [
          spellStateJson(spellId: 's-1'),
          spellStateJson(spellId: 's-2'),
        ],
      },
      'assets': {
        'ownedItems': [ownedHealPotionJson()],
        'ownedEquipments': const [],
        'ownedPets': [ownedPetJson()],
      },
    });

    final ids = newEntryIdsOf(character);

    expect(ids.keys, unorderedEquals(NewEntryCategory.values));
    expect(ids[NewEntryCategory.spells], {'s-1', 's-2'});
    expect(ids[NewEntryCategory.injuries], {'headConcussion'});
    expect(ids[NewEntryCategory.items], {'l-herb'});
    expect(ids[NewEntryCategory.equipment], isEmpty);
    expect(ids[NewEntryCategory.companions], hasLength(1));
    expect(ids[NewEntryCategory.background], {
      'Nata a Drustea.',
      'Ha salvato Bosa.',
    });
  });

  test('a character without sheets owns nothing in every category', () {
    final ids = newEntryIdsOf(Character.fromJson({'id': 'c-1'}));

    expect(ids.keys, unorderedEquals(NewEntryCategory.values));
    expect(ids.values.every((entries) => entries.isEmpty), isTrue);
  });
}
