import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

void main() {
  group('GetCity', () {
    final operation = parseString(
      CityQueries.getCity,
    ).definitions.whereType<OperationDefinitionNode>().single;

    test('is a single query named GetCity with a typed id variable', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetCity');
      final variable = operation.variableDefinitions.single;
      final type = variable.type as NamedTypeNode;
      expect(variable.variable.name.value, 'id');
      expect(type.name.value, 'String');
      expect(type.isNonNull, isTrue);
    });

    test('selects the city POIs and the marker by id only', () {
      expect(
        _collapsed(CityQueries.getCity),
        contains(
          'city(id: \$id) { id markerLocation { id } pointsOfInterest { id } }',
        ),
      );
    });

    test('is registered in the schema check', () {
      expect(schemaCheckDocuments['GetCity'], CityQueries.getCity);
    });
  });

  group('quests document', () {
    final document = _collapsed(QuestQueries.getAllQuests);

    test('selects the interim registrations and requirements', () {
      expect(document, contains('registeredAdventurers'));
      expect(
        document,
        contains(
          'requirements { minTitle requiredPoints requiredAdventurers }',
        ),
      );
    });

    test('leaves the Phase 8 shapes and unpopulated refs out', () {
      for (final forbidden in [
        'enemy',
        'relatedLore',
        'recommendedLoot',
        'party',
        'character title',
        'title count',
      ]) {
        expect(document, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });
}
