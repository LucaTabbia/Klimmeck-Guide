import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/character_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/equipment_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/pet_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/spell_fragment.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';

import '../helpers/fixtures/travel_fixtures.dart';

void main() {
  final fields = CharacterFragment.questsFields.replaceAll(RegExp(r'\s+'), ' ');

  test('selects pendingQuest with timing, arrival, points, quest id and '
      'quest type (the pawn names the activity, UAT 2026-11-14)', () {
    expect(
      fields,
      contains(
        'pendingQuest { id startDate arrivedAt waitingTime pointsSpent '
        'quest { id infos { type } } }',
      ),
    );
  });

  for (final lane in ['activeStoryQuest', 'activeWorldMissionQuest']) {
    test('selects $lane with timing, points and the quest id only', () {
      expect(
        fields,
        contains('$lane { id startDate waitingTime pointsSpent quest { id } }'),
      );
    });
  }

  test('selects arrivedAt only on the standard lane', () {
    expect(RegExp(r'\barrivedAt\b').allMatches(fields), hasLength(1));
  });

  test('selects completedQuests ids', () {
    expect(fields, contains('completedQuests { id }'));
  });

  test('statusFields selects activeTravel with road, dates, duration, to', () {
    expect(
      CharacterFragment.statusFields.replaceAll(RegExp(r'\s+'), ' '),
      contains(
        'activeTravel { road { coordinates distance } '
        'startTime endTime duration to }',
      ),
    );
  });

  test('statusFields selects spellStates with usages, recoveries, active and '
      'the full spell (D-05)', () {
    final status = CharacterFragment.statusFields.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final spell = SpellFragment.fields.replaceAll(RegExp(r'\s+'), ' ').trim();

    expect(status.trim(), startsWith('status {'));
    expect(
      status,
      contains('spellStates { usages recoveries active spell { $spell } }'),
    );
  });

  test('statusFields no longer selects a separate list of known spells '
      '(D-05)', () {
    final status = CharacterFragment.statusFields.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    expect(RegExp(r'(^| )spells \{').hasMatch(status), isFalse);
  });

  test('assetsFields no longer selects the equipped spell list (D-05)', () {
    const oldEquippedKey =
        'active'
        'Spells';

    expect(CharacterFragment.assetsFields, isNot(contains(oldEquippedKey)));
  });

  test('a recorded characterUpdated payload parses its spellStates', () {
    final character = Character.fromJson(_recordedCharacterUpdated);
    final states = character.status!.spellStates;

    expect(states.map((state) => state.spellId), ['spell-a', 'spell-b']);
    expect(states.map((state) => state.usages), [1, 1]);
    expect(states.first.recoveries, [
      DateTime.utc(2026, 10, 27, 10, 2),
      DateTime.utc(2026, 10, 27, 10, 30),
    ]);
    expect(states.last.recoveries, [DateTime.utc(2026, 10, 27, 10, 10)]);
    expect(
      states.expand((state) => state.recoveries).every((at) => at.isUtc),
      isTrue,
    );
  });

  test('a recorded characterUpdated payload parses its active states and '
      'owned entries (D-03, D-05)', () {
    final character = Character.fromJson(_recordedCharacterUpdated);
    final owned = character.assets!.ownedPets.single;

    expect(character.status!.spellStates.map((state) => state.active), [
      true,
      false,
    ]);
    expect(owned.pet.id, 'pet-a');
    expect(owned.xp, 40);
    expect(owned.pet.rarity, RarityType.ultrarare);
  });

  test('statusFields selects awaitingAid with quest, aidQuest, since', () {
    expect(
      CharacterFragment.statusFields.replaceAll(RegExp(r'\s+'), ' '),
      contains('awaitingAid { quest aidQuest since }'),
    );
  });

  test('statusFields selects potionRecoveryUntil after awaitingAid (D-12)', () {
    expect(
      CharacterFragment.statusFields.replaceAll(RegExp(r'\s+'), ' '),
      contains('awaitingAid { quest aidQuest since } potionRecoveryUntil'),
    );
  });

  test('statusFields selects imprisonedUntil after potionRecoveryUntil '
      '(quick 261110-cgd)', () {
    expect(
      CharacterFragment.statusFields.replaceAll(RegExp(r'\s+'), ' '),
      contains('potionRecoveryUntil imprisonedUntil'),
    );
  });

  test('statusFields selects the two mission flags after imprisonedUntil '
      '(D-16, Pitfall 2)', () {
    expect(
      CharacterFragment.statusFields.replaceAll(RegExp(r'\s+'), ' '),
      contains('imprisonedUntil missionInProgress guidedMissionInProgress'),
    );
  });

  test('characterUpdated and character carry the mission flags (D-23)', () {
    for (final document in [
      CharacterSubscriptions.characterUpdated,
      CharacterQueries.getCharacter,
    ]) {
      expect(document, contains('missionInProgress'));
      expect(document, contains('guidedMissionInProgress'));
    }
  });

  test('statusFields selects unlockedLore (D-01)', () {
    final spell = SpellFragment.fields.replaceAll(RegExp(r'\s+'), ' ').trim();

    expect(
      CharacterFragment.statusFields.replaceAll(RegExp(r'\s+'), ' '),
      contains('active spell { $spell } } unlockedLore }'),
    );
  });

  test('a recorded characterUpdated payload parses its awaitingAid', () {
    final character = Character.fromJson(
      travellingCharacterJson(awaitingAid: awaitingAidJson()),
    );

    expect(
      character.status!.awaitingAid,
      AwaitingAid(
        questId: 'q-1',
        aidQuestId: 'aid-1',
        since: DateTime.utc(2026, 10, 27, 11),
      ),
    );
    expect(character.status!.awaitingAid!.since.isUtc, isTrue);
  });

  test('selects the equipped pet with PetFragment and the owned pets as '
      'entries (D-03, D-18)', () {
    final assets = CharacterFragment.assetsFields.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final pet = PetFragment.fields.replaceAll(RegExp(r'\s+'), ' ').trim();

    expect(assets, contains('pet { $pet }'));
    expect(assets, contains('ownedPets { xp currentLifePoints pet { $pet } }'));
  });

  group('worn equipment (BE Phase 19)', () {
    final assets = CharacterFragment.assetsFields.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final equipmentQuery = CharacterQueries.getEquipment.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    test('assetsFields selects wornEquipment with the feet slot (D-04)', () {
      expect(assets, contains('wornEquipment {'));
      expect(assets, contains('feet {'));
    });

    test('the equipment query selects the feet slot (D-04)', () {
      expect(equipmentQuery, contains('feet {'));
    });

    test('no document selects the old equipment names (D-04)', () {
      const oldWornKey =
          'weared'
          'Equipment';
      const oldBootsSlot =
          'fo'
          'ots';

      for (final document in [assets, equipmentQuery]) {
        expect(document, isNot(contains(oldWornKey)));
        expect(document, isNot(contains(oldBootsSlot)));
      }
    });
  });

  test('the Journal assets select accessoryUseTypes on equipment (D-15)', () {
    expect(
      EquipmentFragment.fieldsWithFullSpell.replaceAll(RegExp(r'\s+'), ' '),
      contains('equipType accessoryUseTypes'),
    );
    expect(CharacterQueries.getCharacter, contains('accessoryUseTypes'));
  });

  test(
    'quest and result items keep the simple fields without use types (D-15)',
    () {
      expect(
        EquipmentFragment.simpleFields,
        isNot(contains('accessoryUseTypes')),
      );
    },
  );

  test('characterUpdated still parses as a single operation', () {
    final document = parseString(CharacterSubscriptions.characterUpdated);
    expect(
      document.definitions.whereType<OperationDefinitionNode>(),
      hasLength(1),
    );
  });

  test('getCharacter still parses as a single operation', () {
    final document = parseString(CharacterQueries.getCharacter);
    expect(
      document.definitions.whereType<OperationDefinitionNode>(),
      hasLength(1),
    );
  });
}

/// `characterUpdated` nella forma della BE Phase 19 (id sostituiti): stati
/// con la magia intera e `active`, compagni posseduti come voci.
const Map<String, dynamic> _recordedCharacterUpdated = {
  'id': 'character-1',
  'status': {
    'maxActiveSpells': 1,
    'spellStates': [
      {
        'spell': {
          'id': 'spell-a',
          'name': 'Nome A',
          'description': 'Descrizione A',
          'useType': 'attack',
          'maxUsages': 3,
          'minXpToLearn': 100,
          'recoveryTime': 1800000,
          'requiredLearnTime': 3600000,
          'energyDamage': {'type': 'fire', 'power': 12},
        },
        'usages': 1,
        'recoveries': ['2026-10-27T10:02:00.000Z', '2026-10-27T10:30:00.000Z'],
        'active': true,
      },
      {
        'spell': {
          'id': 'spell-b',
          'name': 'Nome B',
          'description': 'Descrizione B',
          'useType': 'defense',
          'maxUsages': 2,
          'minXpToLearn': 200,
          'recoveryTime': 600000,
          'requiredLearnTime': 3600000,
          'energyDamage': null,
        },
        'usages': 1,
        'recoveries': ['2026-10-27T10:10:00.000Z'],
        'active': false,
      },
    ],
  },
  'assets': {
    'wornEquipment': <String, dynamic>{},
    'ownedEquipments': <Object?>[],
    'ownedItems': <Object?>[],
    'pet': null,
    'ownedPets': [
      {
        'xp': 40,
        'currentLifePoints': 7,
        'pet': {
          'id': 'pet-a',
          'name': 'Compagno A',
          'speedModifier': 2,
          'sellable': true,
          'buyPrice': {'gold': 1, 'silver': 0, 'copper': 0},
          'sellPrice': {'gold': 0, 'silver': 50, 'copper': 0},
          'maxXp': 300,
          'attack': {
            'base': [
              {'type': 'blunt', 'power': 4},
            ],
            'energy': <Object?>[],
          },
          'defense': {
            'base': [
              {'type': 'blunt', 'power': 2},
            ],
            'energy': <Object?>[],
          },
          'rarity': 'ultrarare',
        },
      },
    ],
  },
};
