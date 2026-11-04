import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/quest_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

void main() {
  group('AcceptQuest', () {
    final operation = parseString(
      QuestMutations.acceptQuest,
    ).definitions.whereType<OperationDefinitionNode>().single;

    test('is a single mutation named AcceptQuest', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'AcceptQuest');
    });

    test('declares the request variable as AcceptQuestRequest!', () {
      final variable = operation.variableDefinitions.single;
      final type = variable.type as NamedTypeNode;

      expect(variable.variable.name.value, 'request');
      expect(type.name.value, 'AcceptQuestRequest');
      expect(type.isNonNull, isTrue);
    });

    test(
      'selects response and successful of acceptQuest(request: \$request)',
      () {
        final field = operation.selectionSet.selections.single as FieldNode;
        final selected = field.selectionSet!.selections
            .whereType<FieldNode>()
            .map((node) => node.name.value);

        expect(field.name.value, 'acceptQuest');
        expect(field.arguments.single.name.value, 'request');
        expect(selected, ['response', 'successful']);
      },
    );
  });

  group('GenerateQuests', () {
    OperationDefinitionNode operation() => parseString(
      QuestMutations.generateQuests,
    ).definitions.whereType<OperationDefinitionNode>().single;

    test(
      'is a single mutation named GenerateQuests without variables (D-10)',
      () {
        expect(operation().type, OperationType.mutation);
        expect(operation().name?.value, 'GenerateQuests');
        expect(operation().variableDefinitions, isEmpty);
      },
    );

    test('selects created of generateQuests (D-10)', () {
      final collapsed = QuestMutations.generateQuests.replaceAll(
        RegExp(r'\s+'),
        ' ',
      );

      expect(collapsed, contains('generateQuests { created }'));
    });

    test('is registered in the schema check (D-14)', () {
      expect(
        schemaCheckDocuments['GenerateQuests'],
        QuestMutations.generateQuests,
      );
    });
  });
}
