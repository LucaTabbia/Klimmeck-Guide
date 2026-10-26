import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/fragments.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/quest_subscriptions.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void main() {
  final sharedSelection = _collapsed(QuestFragment.fields);

  group('quests query', () {
    test('selects the shared quest fragment', () {
      expect(_collapsed(QuestQueries.getAllQuests), contains(sharedSelection));
    });

    test('parses to one query named quests', () {
      final operation = _operationOf(QuestQueries.getAllQuests);
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'quests');
    });
  });

  group('OnQuestUpdated', () {
    final operation = _operationOf(QuestSubscriptions.questUpdated);
    final document = _collapsed(QuestSubscriptions.questUpdated);

    test('is a subscription named OnQuestUpdated with a typed questId', () {
      expect(operation.type, OperationType.subscription);
      expect(operation.name?.value, 'OnQuestUpdated');
      final variable = operation.variableDefinitions.single;
      final type = variable.type as NamedTypeNode;
      expect(variable.variable.name.value, 'questId');
      expect(type.name.value, 'String');
      expect(type.isNonNull, isTrue);
    });

    test('listens to questUpdated with the quest id', () {
      expect(document, contains(r'questUpdated(questId: $questId) {'));
    });

    test('selects the same quest fields as the quests query', () {
      expect(document, contains(sharedSelection));
      expect(document, contains('registeredAdventurers { character title }'));
      expect(
        document,
        contains('requirements { minTitle requiredPoints requiredAdventurers'),
      );
      expect(document, contains('requiredAdventurers { title count }'));
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['OnQuestUpdated'],
        QuestSubscriptions.questUpdated,
      );
    });
  });
}
