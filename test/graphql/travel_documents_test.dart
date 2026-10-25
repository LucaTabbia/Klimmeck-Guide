import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/travel_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/server_time_queries.dart';
import 'package:klimmeck_guide/graphql/queries/travel_queries.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void _expectTravelRequestVariable(OperationDefinitionNode operation) {
  final variable = operation.variableDefinitions.single;
  final type = variable.type as NamedTypeNode;
  expect(variable.variable.name.value, 'request');
  expect(type.name.value, 'TravelRequest');
  expect(type.isNonNull, isTrue);
}

void main() {
  group('GetTravelPreview', () {
    final operation = _operationOf(TravelQueries.getTravelPreview);

    test('is a single query named GetTravelPreview', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetTravelPreview');
    });

    test('declares the request variable as TravelRequest!', () {
      _expectTravelRequestVariable(operation);
    });

    test('selects distance, duration and the road of travelPreview', () {
      expect(
        _collapsed(TravelQueries.getTravelPreview),
        contains(
          'travelPreview(request: \$request) '
          '{ distance duration road { coordinates distance } }',
        ),
      );
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['GetTravelPreview'],
        TravelQueries.getTravelPreview,
      );
    });
  });

  group('StartTravel', () {
    final operation = _operationOf(TravelMutations.startTravel);

    test('is a single mutation named StartTravel', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'StartTravel');
    });

    test('declares the request variable as TravelRequest!', () {
      _expectTravelRequestVariable(operation);
    });

    test('selects response and successful of startTravel', () {
      expect(
        _collapsed(TravelMutations.startTravel),
        contains('startTravel(request: \$request) { response successful }'),
      );
    });

    test('is registered in the schema check', () {
      expect(schemaCheckDocuments['StartTravel'], TravelMutations.startTravel);
    });
  });

  group('GetServerTime', () {
    final operation = _operationOf(ServerTimeQueries.getServerTime);

    test('is a single query named GetServerTime selecting serverTime', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetServerTime');
      expect(operation.variableDefinitions, isEmpty);
      final selected = operation.selectionSet.selections
          .whereType<FieldNode>()
          .map((node) => node.name.value);
      expect(selected, ['serverTime']);
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['GetServerTime'],
        ServerTimeQueries.getServerTime,
      );
    });
  });

  group('cities', () {
    test('selects the lore image for the confirmation sheet', () {
      expect(
        _collapsed(CityQueries.getAllCities),
        contains('relatedLore { id description image }'),
      );
    });
  });

  test('the schema check registers 33 documents', () {
    expect(schemaCheckDocuments.length, 33);
  });
}
