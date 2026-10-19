import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/push_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

String _typeOf(VariableDefinitionNode variable) {
  final type = variable.type as NamedTypeNode;
  return '${type.name.value}${type.isNonNull ? '!' : ''}';
}

void main() {
  group('RegisterPushDevice', () {
    final document = PushMutations.registerPushDevice;
    final operation = _operationOf(document);

    test('is a single mutation named RegisterPushDevice', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'RegisterPushDevice');
    });

    test('declares only the input variable as RegisterPushDeviceInput!', () {
      final variable = operation.variableDefinitions.single;

      expect(variable.variable.name.value, 'input');
      expect(_typeOf(variable), 'RegisterPushDeviceInput!');
    });

    test('calls registerPushDevice without a selection set', () {
      final field = operation.selectionSet.selections.single as FieldNode;

      expect(field.name.value, 'registerPushDevice');
      expect(field.arguments.single.name.value, 'input');
      expect(field.selectionSet, isNull);
    });

    test('is listed for the schema check', () {
      expect(schemaCheckDocuments['RegisterPushDevice'], document);
    });
  });

  group('UnregisterPushDevice', () {
    final document = PushMutations.unregisterPushDevice;
    final operation = _operationOf(document);

    test('is a single mutation named UnregisterPushDevice', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'UnregisterPushDevice');
    });

    test('declares only the deviceId variable as String!', () {
      final variable = operation.variableDefinitions.single;

      expect(variable.variable.name.value, 'deviceId');
      expect(_typeOf(variable), 'String!');
    });

    test('calls unregisterPushDevice without a selection set', () {
      final field = operation.selectionSet.selections.single as FieldNode;

      expect(field.name.value, 'unregisterPushDevice');
      expect(field.arguments.single.name.value, 'deviceId');
      expect(field.selectionSet, isNull);
    });

    test('is listed for the schema check', () {
      expect(schemaCheckDocuments['UnregisterPushDevice'], document);
    });
  });
}
