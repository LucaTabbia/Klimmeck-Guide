import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/character_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/equipment_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/pet_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/quest_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/quest_result_fragment.dart';
import 'package:klimmeck_guide/graphql/fragments/spell_fragment.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/enums/spell_origin.dart';

import '../../tool/schema_check/schema_check_documents.dart';
import '../helpers/fixtures/travel_fixtures.dart';

void main() {
  final fields = CharacterFragment.questsFields.replaceAll(RegExp(r'\s+'), ' ');

  test('the standard lane selects the spell being learned (D-26)', () {
    expect(
      fields,
      contains(
        'pendingQuest { id startDate arrivedAt waitingTime pointsSpent '
        'learningSpell { id name origin requiredLearnTime } '
        'quest { id infos { type } } }',
      ),
    );
  });

  test('the GM lanes select no learning spell (D-30)', () {
    expect(
      fields.split('activeStoryQuest {').last,
      isNot(contains('learningSpell')),
    );
  });

  test('character and characterUpdated carry the learning spell (D-26)', () {
    for (final document in [
      CharacterQueries.getCharacter,
      CharacterSubscriptions.characterUpdated,
    ]) {
      expect(
        document.replaceAll(RegExp(r'\s+'), ' '),
        contains('learningSpell { id name origin requiredLearnTime }'),
      );
    }
  });

  test('a recorded characterUpdated payload parses the learning part '
      '(D-26)', () {
    final character = Character.fromJson(
      travellingCharacterJson(pendingQuest: _recordedLearningLane),
    );
    final lane = character.quests!.pendingQuest!;

    expect(lane.isLearning, isTrue);
    expect(lane.learningSpell!.name, 'Nome A');
    expect(lane.learningSpell!.origin, SpellOrigin.arcane);
    expect(lane.learningSpell!.requiredLearnTime, 1800000);
    expect(lane.learningEndsAt, DateTime.utc(2026, 11, 16, 11, 30));
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

  test('SpellFragment.fields no longer selects minXpToLearn (D-07, '
      'Pitfall 2)', () {
    for (final selection in [
      SpellFragment.fields,
      CharacterFragment.statusFields,
      CharacterFragment.assetsFields,
      CharacterQueries.getCharacter,
      CharacterSubscriptions.characterUpdated,
    ]) {
      expect(selection, isNot(contains('minXpToLearn')));
    }
  });

  test('SpellFragment.fields selects origin after description and '
      'minLevelToLearn after maxUsages (D-01, D-07)', () {
    expect(
      SpellFragment.fields.replaceAll(RegExp(r'\s+'), ' '),
      contains(
        'description origin useType maxUsages minLevelToLearn '
        'recoveryTime',
      ),
    );
  });

  test('character and characterUpdated carry origin and minLevelToLearn '
      '(D-01, D-07)', () {
    for (final document in [
      CharacterQueries.getCharacter,
      CharacterSubscriptions.characterUpdated,
    ]) {
      expect(document, contains(RegExp(r'\borigin\b')));
      expect(document, contains('minLevelToLearn'));
    }
  });

  test('a recorded characterUpdated payload parses the origin and the '
      'minimum level of its spells (D-01, D-07)', () {
    final character = Character.fromJson(_recordedCharacterUpdated);
    final spells = character.status!.spellStates.map((state) => state.spell);

    expect(spells.map((spell) => spell.origin), [
      SpellOrigin.theVoid,
      SpellOrigin.shamanic,
    ]);
    expect(spells.map((spell) => spell.minLevelToLearn), [6, 1]);
  });

  test("no document selects minXpToLearn or the spell's relatedLore "
      '(D-07, D-24)', () {
    for (final selection in [
      SpellFragment.fields,
      SpellFragment.simpleFields,
      EquipmentFragment.fields,
    ]) {
      expect(selection, isNot(contains('minXpToLearn')));
      expect(selection, isNot(contains('relatedLore')));
    }
  });

  test('the research and learning fields are selected only where the gate '
      'put them (D-26, D-31)', () {
    final homes = {
      'learningSpell': CharacterFragment.fullFields,
      'spellDraw': QuestFragment.fields,
      'spellFound': QuestResultFragment.fields,
      'spellResearchFailed': QuestResultFragment.fields,
    };
    final expectedDocuments = {
      'learningSpell': {'character', 'characterUpdated'},
      'spellDraw': {'quests', 'OnQuestUpdated'},
      'spellFound': _resultDocuments,
      'spellResearchFailed': _resultDocuments,
    };
    homes.forEach((field, home) {
      final selecting = {
        for (final MapEntry(key: name, value: document)
            in schemaCheckDocuments.entries)
          if (document.contains(field)) name,
      };
      final embedding = {
        for (final MapEntry(key: name, value: document)
            in schemaCheckDocuments.entries)
          if (document.contains(home)) name,
      };

      expect(selecting, expectedDocuments[field], reason: field);
      expect(selecting, embedding, reason: field);
    });
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
    expect(
      assets,
      contains(
        'ownedPets { xp currentLifePoints name defeated lifeAsOf fullLifeAt '
        'potionRecoveryUntil level maxLifePoints pet { $pet } }',
      ),
    );
  });

  test('ownedPets selects the companion state, level and own max after '
      'currentLifePoints (D-09, D-24, D-37, Pitfall 1)', () {
    final ownedPets = CharacterFragment.assetsFields
        .replaceAll(RegExp(r'\s+'), ' ')
        .split('ownedPets {')
        .last;

    expect(
      ownedPets,
      startsWith(
        ' xp currentLifePoints name defeated lifeAsOf fullLifeAt '
        'potionRecoveryUntil level maxLifePoints pet {',
      ),
    );
  });

  test('character and characterUpdated carry lifeAsOf (D-24)', () {
    for (final document in [
      CharacterQueries.getCharacter,
      CharacterSubscriptions.characterUpdated,
    ]) {
      expect(
        RegExp(r'\blifeAsOf\b').allMatches(document),
        hasLength(1),
        reason: document,
      );
    }
  });

  test('ownedPets and the equipped pet carry maxLifePoints and imagePath '
      '(D-09, D-34)', () {
    final assets = CharacterFragment.assetsFields.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final ownedPets = assets.split('ownedPets {').last;
    final equippedPet = assets.split(' pet { ')[1];

    expect(ownedPets, contains('maxLifePoints'));
    expect(ownedPets, contains('imagePath'));
    expect(equippedPet, contains('maxLifePoints'));
    expect(equippedPet, contains('imagePath'));
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

/// Documenti che incorporano `QuestResultFragment.fields`.
const Set<String> _resultDocuments = {
  'GetQuestResult',
  'ListUnacknowledgedQuestResults',
  'OnQuestResultReceived',
  'CompleteGuidedMission',
};

/// Corsia standard nella parte di apprendimento, forma del handoff BE §8.6
/// (id sostituiti): stessa `id`, `startDate` = fine della ricerca.
const Map<String, dynamic> _recordedLearningLane = {
  'id': 'pending-quest-1',
  'startDate': '2026-11-16T11:00:00.000Z',
  'arrivedAt': '2026-11-16T09:55:00.000Z',
  'waitingTime': 1800000,
  'pointsSpent': 0,
  'learningSpell': {
    'id': 'spell-a',
    'name': 'Nome A',
    'origin': 'arcane',
    'requiredLearnTime': 1800000,
  },
  'quest': {
    'id': 'quest-1',
    'infos': {'type': 'arcane'},
  },
};

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
          'origin': 'void',
          'useType': 'attack',
          'maxUsages': 3,
          'minLevelToLearn': 6,
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
          'origin': 'shamanic',
          'useType': 'defense',
          'maxUsages': 2,
          'minLevelToLearn': 1,
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
