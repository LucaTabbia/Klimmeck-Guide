import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void _expectSpellSlotMutation({
  required String document,
  required String operationName,
  required String field,
}) {
  final operation = _operationOf(document);

  test('is a single mutation named $operationName', () {
    expect(operation.type, OperationType.mutation);
    expect(operation.name?.value, operationName);
  });

  test('declares the request variable as EquipSpellRequest!', () {
    final variable = operation.variableDefinitions.single;
    final type = variable.type as NamedTypeNode;
    expect(variable.variable.name.value, 'request');
    expect(type.name.value, 'EquipSpellRequest');
    expect(type.isNonNull, isTrue);
  });

  test('selects response and successful of $field', () {
    expect(
      _collapsed(document),
      contains('$field(request: \$request) { response successful }'),
    );
  });

  test('is registered in the schema check', () {
    expect(schemaCheckDocuments[operationName], document);
  });
}

void main() {
  group('EquipSpell', () {
    _expectSpellSlotMutation(
      document: CharacterMutations.equipSpell,
      operationName: 'EquipSpell',
      field: 'equipSpell',
    );
  });

  group('UnequipSpell', () {
    _expectSpellSlotMutation(
      document: CharacterMutations.unequipSpell,
      operationName: 'UnequipSpell',
      field: 'unequipSpell',
    );
  });

  test('the lowercase operation names are no longer registered', () {
    expect(schemaCheckDocuments.containsKey('equipSpell'), isFalse);
    expect(schemaCheckDocuments.containsKey('unequipSpell'), isFalse);
  });
}
