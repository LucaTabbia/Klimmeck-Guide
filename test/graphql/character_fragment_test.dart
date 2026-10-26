import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/character_fragment.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';

void main() {
  final fields = CharacterFragment.questsFields.replaceAll(RegExp(r'\s+'), ' ');

  for (final lane in [
    'pendingQuest',
    'activeStoryQuest',
    'activeWorldMissionQuest',
  ]) {
    test('selects $lane with timing, points and the quest id only', () {
      expect(
        fields,
        contains('$lane { id startDate waitingTime pointsSpent quest { id } }'),
      );
    });
  }

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
