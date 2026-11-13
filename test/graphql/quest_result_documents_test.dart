import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/fragments.dart';
import 'package:klimmeck_guide/graphql/mutations/quest_result_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/quest_result_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/quest_result_subscriptions.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void _expectSingleNonNullString(
  OperationDefinitionNode operation,
  String name,
) {
  final variable = operation.variableDefinitions.single;
  final type = variable.type as NamedTypeNode;
  expect(variable.variable.name.value, name);
  expect(type.name.value, 'String');
  expect(type.isNonNull, isTrue);
}

void main() {
  final sharedSelection = _collapsed(QuestResultFragment.fields);

  group('QuestResultFragment', () {
    test('selects equipType on equipment and the loot details', () {
      expect(
        sharedSelection,
        contains(
          '... on EquipmentItem { id name itemType equipType rarity '
          'description }',
        ),
      );
      expect(
        sharedSelection,
        contains(
          '... on LootItem { id name itemType rarity description effect '
          'power }',
        ),
      );
    });

    test('selects the enemies fought with known, the spells used and the '
        'rescued (D-07, D-03)', () {
      expect(
        sharedSelection,
        contains(
          'enemies { quantity known enemy { id name imagePath xp } } '
          'stagesCleared stagesTotal',
        ),
      );
      expect(
        sharedSelection,
        contains('spellsUsed { usages spell { id name } }'),
      );
      expect(sharedSelection, contains('rescuedCharacters'));
    });

    test('carries no single enemy selection besides the nested one (D-01)', () {
      final enemyBlocks = RegExp(
        r'\benemy \{',
      ).allMatches(sharedSelection).length;
      final enemiesBlocks = RegExp(
        r'\benemies \{',
      ).allMatches(sharedSelection).length;
      expect(enemyBlocks, enemiesBlocks);
      expect(enemiesBlocks, 1);
    });

    test('selects the companion reward inside rewards (D-07)', () {
      expect(
        RegExp(
          r'rewards \{[\s\S]*?pet \{ id name \} \}',
        ).hasMatch(sharedSelection),
        isTrue,
      );
    });

    test('never selects enemy locations', () {
      expect(sharedSelection, isNot(contains('locations')));
    });

    test('selects injuriesHealed after injuriesAdded (D-02)', () {
      expect(sharedSelection, contains('injuriesAdded injuriesHealed'));
    });

    test('selects arrested, coinsLost and guardEncounter after '
        'injuriesHealed (quick 261110-cgd)', () {
      expect(
        sharedSelection,
        contains(
          'injuriesHealed arrested coinsLost { gold silver copper } '
          'guardEncounter',
        ),
      );
    });

    test('selects the BE 9.2 acknowledgedAt right after resolvedAt', () {
      expect(sharedSelection, contains('resolvedAt acknowledgedAt'));
    });

    test('selects the result kind right after the outcome (D-01)', () {
      expect(
        sharedSelection,
        contains('outcome kind resolvedAt acknowledgedAt'),
      );
    });

    test('selects the ambush report with its two cities (D-01)', () {
      expect(
        sharedSelection,
        contains('ambush { at nearCity { id name } reachedCity { id name } }'),
      );
    });

    test('selects petXpGained after xpAfter (D-03)', () {
      expect(sharedSelection, contains('xpAfter petXpGained'));
    });

    test('selects the lore unlocked by the outcome (D-04)', () {
      expect(
        sharedSelection,
        contains('spellLearned { id name } loreUnlocked { id name type }'),
      );
    });

    test('selects the four turn fields right after the stages (D-22)', () {
      expect(
        sharedSelection,
        contains(
          'stagesCleared stagesTotal turnsTotal turnsCompleted lastTurn '
          'lastTurnKind rescuedCharacters',
        ),
      );
    });

    test('every result document carries the turn fields (D-22)', () {
      for (final document in [
        QuestResultSubscriptions.questResultReceived,
        QuestResultQueries.getQuestResult,
        QuestResultQueries.listUnacknowledgedQuestResults,
      ]) {
        expect(_collapsed(document), contains('lastTurnKind'));
      }
    });
  });

  group('OnQuestResultReceived', () {
    final operation = _operationOf(
      QuestResultSubscriptions.questResultReceived,
    );
    final document = _collapsed(QuestResultSubscriptions.questResultReceived);

    test('is a subscription with a typed characterId', () {
      expect(operation.type, OperationType.subscription);
      expect(operation.name?.value, 'OnQuestResultReceived');
      _expectSingleNonNullString(operation, 'characterId');
    });

    test('listens to questResultReceived with the shared fragment', () {
      expect(
        document,
        contains(r'questResultReceived(characterId: $characterId) {'),
      );
      expect(document, contains(sharedSelection));
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['OnQuestResultReceived'],
        QuestResultSubscriptions.questResultReceived,
      );
    });
  });

  group('GetQuestResult', () {
    final operation = _operationOf(QuestResultQueries.getQuestResult);
    final document = _collapsed(QuestResultQueries.getQuestResult);

    test('is a query with a typed id', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetQuestResult');
      _expectSingleNonNullString(operation, 'id');
    });

    test('reads questResult by id with the shared fragment', () {
      expect(document, contains(r'questResult(id: $id) {'));
      expect(document, contains(sharedSelection));
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['GetQuestResult'],
        QuestResultQueries.getQuestResult,
      );
    });
  });

  group('ListUnacknowledgedQuestResults', () {
    final operation = _operationOf(
      QuestResultQueries.listUnacknowledgedQuestResults,
    );
    final document = _collapsed(
      QuestResultQueries.listUnacknowledgedQuestResults,
    );

    test('is a query without variables', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'ListUnacknowledgedQuestResults');
      expect(operation.variableDefinitions, isEmpty);
    });

    test('reads unacknowledgedQuestResults with the shared fragment', () {
      expect(document, contains('unacknowledgedQuestResults {'));
      expect(document, contains(sharedSelection));
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['ListUnacknowledgedQuestResults'],
        QuestResultQueries.listUnacknowledgedQuestResults,
      );
    });
  });

  group('AcknowledgeQuestResult', () {
    final operation = _operationOf(QuestResultMutations.acknowledgeQuestResult);
    final document = _collapsed(QuestResultMutations.acknowledgeQuestResult);

    test('is a mutation with a typed id', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'AcknowledgeQuestResult');
      _expectSingleNonNullString(operation, 'id');
    });

    test('selects the CommonResponse of acknowledgeQuestResult', () {
      expect(
        document,
        contains(r'acknowledgeQuestResult(id: $id) { successful response }'),
      );
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['AcknowledgeQuestResult'],
        QuestResultMutations.acknowledgeQuestResult,
      );
    });
  });
}
