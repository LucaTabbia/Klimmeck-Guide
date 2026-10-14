import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/subscriptions/user_subscriptions.dart';

DocumentNode parse(String document) => parseString(document);

OperationDefinitionNode operationOf(String document) =>
    parse(document).definitions.whereType<OperationDefinitionNode>().single;

int userFieldsDefinitions(String document) => parse(document).definitions
    .whereType<FragmentDefinitionNode>()
    .where((fragment) => fragment.name.value == 'UserFields')
    .length;

void main() {
  group('OnUserChanged', () {
    final document = UserSubscriptions.userUpdated;

    test('is a named subscription without variables', () {
      final operation = operationOf(document);

      expect(operation.type, OperationType.subscription);
      expect(operation.name?.value, 'OnUserChanged');
      expect(operation.variableDefinitions, isEmpty);
    });

    test('subscribes to userUpdated with no arguments', () {
      final field =
          operationOf(document).selectionSet.selections.single as FieldNode;

      expect(field.name.value, 'userUpdated');
      expect(field.arguments, isEmpty);
    });

    test('selects the shared UserFields fragment defined exactly once', () {
      final field =
          operationOf(document).selectionSet.selections.single as FieldNode;
      final spread = field.selectionSet!.selections.single;

      expect((spread as FragmentSpreadNode).name.value, 'UserFields');
      expect(userFieldsDefinitions(document), 1);
    });
  });
}
