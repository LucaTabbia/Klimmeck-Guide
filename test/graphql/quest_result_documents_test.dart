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

    test('selects the enemy, the spells used and the rescued', () {
      expect(sharedSelection, contains('enemy { id name imagePath }'));
      expect(
        sharedSelection,
        contains('spellsUsed { usages spell { id name } }'),
      );
      expect(sharedSelection, contains('rescuedCharacters'));
    });

    test('never selects enemy locations', () {
      expect(sharedSelection, isNot(contains('locations')));
    });

    test('selects the BE 9.2 acknowledgedAt right after resolvedAt', () {
      expect(sharedSelection, contains('resolvedAt acknowledgedAt'));
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
