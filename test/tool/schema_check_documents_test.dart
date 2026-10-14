import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

import '../../tool/schema_check/schema_check_documents.dart';

final _operationName = RegExp(r'\b(?:query|mutation|subscription)\s+(\w+)');

Set<String> _declaredOperationNames() =>
    [
          'lib/graphql/queries',
          'lib/graphql/mutations',
          'lib/graphql/subscriptions',
        ]
        .expand((dir) => Directory(dir).listSync())
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .expand(
          (file) => _operationName
              .allMatches(file.readAsStringSync())
              .map((match) => match.group(1)!),
        )
        .toSet();

void main() {
  test('lists every named operation declared in lib/graphql', () {
    expect(schemaCheckDocuments.keys.toSet(), _declaredOperationNames());
  });

  test('each document holds one operation named like its key', () {
    schemaCheckDocuments.forEach((name, document) {
      final operation = parseString(
        document,
      ).definitions.whereType<OperationDefinitionNode>().single;

      expect(operation.name?.value, name);
    });
  });
}
