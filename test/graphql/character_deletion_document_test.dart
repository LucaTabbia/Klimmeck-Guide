import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

void main() {
  group('DeleteCharacter', () {
    final document = CharacterMutations.deleteCharacter;
    final parsed = parseString(document);
    final operation = parsed.definitions
        .whereType<OperationDefinitionNode>()
        .single;

    test('is a single named mutation without variables', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'DeleteCharacter');
      expect(operation.variableDefinitions, isEmpty);
    });

    test('calls deleteCharacter with no arguments', () {
      final field = operation.selectionSet.selections.single as FieldNode;

      expect(field.name.value, 'deleteCharacter');
      expect(field.arguments, isEmpty);
    });

    test('selects the shared UserFields fragment defined exactly once', () {
      expect(document, contains('...UserFields'));
      final definitions = parsed.definitions
          .whereType<FragmentDefinitionNode>()
          .where((fragment) => fragment.name.value == 'UserFields');
      expect(definitions, hasLength(1));
    });

    test('is listed for the schema check', () {
      expect(schemaCheckDocuments['DeleteCharacter'], document);
    });
  });
}
