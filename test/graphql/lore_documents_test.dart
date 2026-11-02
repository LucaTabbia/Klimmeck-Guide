import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/queries/lore_queries.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

const _loreFields = 'id image type name description relatedLore { id name }';

void _expectLoreQuery({
  required String document,
  required String operationName,
  required String selection,
}) {
  final operation = _operationOf(document);

  test('is a single query named $operationName', () {
    expect(operation.type, OperationType.query);
    expect(operation.name?.value, operationName);
  });

  test('selects the lore fields without unlocked (BE Phase 11, D-25)', () {
    expect(_collapsed(document), contains('$selection { $_loreFields }'));
    expect(document, isNot(contains('unlocked')));
  });

  test('is registered in the schema check', () {
    expect(schemaCheckDocuments[operationName], document);
  });
}

void main() {
  group('lores', () {
    _expectLoreQuery(
      document: LoreQueries.getAllLores,
      operationName: 'lores',
      selection: 'lores',
    );
  });

  group('lore', () {
    _expectLoreQuery(
      document: LoreQueries.getLoreById,
      operationName: 'lore',
      selection: r'lore(id: $id)',
    );

    test('declares the id variable as String!', () {
      final variable = _operationOf(
        LoreQueries.getLoreById,
      ).variableDefinitions.single;
      final type = variable.type as NamedTypeNode;
      expect(variable.variable.name.value, 'id');
      expect(type.name.value, 'String');
      expect(type.isNonNull, isTrue);
    });
  });
}
