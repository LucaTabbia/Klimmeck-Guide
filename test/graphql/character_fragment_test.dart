import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/character_fragment.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';
import 'package:klimmeck_guide/models/character/character.dart';

void main() {
  final fields = CharacterFragment.questsFields.replaceAll(RegExp(r'\s+'), ' ');

  test('selects pendingQuest with timing, arrival, points and quest id', () {
    expect(
      fields,
      contains(
        'pendingQuest { id startDate arrivedAt waitingTime pointsSpent '
        'quest { id } }',
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

  test(
    'statusFields selects spellStates with usages, recoveries, spell id',
    () {
      final status = CharacterFragment.statusFields.replaceAll(
        RegExp(r'\s+'),
        ' ',
      );

      expect(status.trim(), startsWith('status {'));
      expect(
        status,
        contains('spellStates { usages recoveries spell { id } }'),
      );
    },
  );

  test('a recorded characterUpdated payload parses its spellStates', () {
    final character = Character.fromJson(_recordedCharacterUpdated);
    final states = character.status!.spellStates!;

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

  test('fullFields never selects the pet (BE handoff 11 b)', () {
    expect(RegExp(r'\bpet\b').hasMatch(CharacterFragment.fullFields), isFalse);
  });

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

/// `characterUpdated` registrato dall'handoff BE 9.1 §3 (id sostituiti).
const Map<String, dynamic> _recordedCharacterUpdated = {
  'id': 'character-1',
  'status': {
    'maxActiveSpells': 1,
    'spells': [
      {
        'id': 'spell-a',
        'name': 'Nome A',
        'maxUsages': 3,
        'recoveryTime': 1800000,
      },
      {
        'id': 'spell-b',
        'name': 'Nome B',
        'maxUsages': 2,
        'recoveryTime': 600000,
      },
    ],
    'spellStates': [
      {
        'spell': {'id': 'spell-a'},
        'usages': 1,
        'recoveries': ['2026-10-27T10:02:00.000Z', '2026-10-27T10:30:00.000Z'],
      },
      {
        'spell': {'id': 'spell-b'},
        'usages': 1,
        'recoveries': ['2026-10-27T10:10:00.000Z'],
      },
    ],
  },
  'assets': {
    'activeSpells': [
      {
        'usages': 1,
        'spell': {'id': 'spell-a'},
      },
    ],
  },
};
