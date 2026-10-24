import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/quest_mutations.dart';

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
}
