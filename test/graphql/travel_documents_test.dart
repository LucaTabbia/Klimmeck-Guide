import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/travel_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/point_of_interest_queries.dart';
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

    test(
      'selects the road, the food, the life lost and arrivesAlive of travelPreview (D-01)',
      () {
        expect(
          _collapsed(TravelQueries.getTravelPreview),
          contains(
            'travelPreview(request: \$request) '
            '{ distance duration road { coordinates distance } '
            'food { quantity item { id name } } hpLost arrivesAlive }',
          ),
        );
      },
    );

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['GetTravelPreview'],
        TravelQueries.getTravelPreview,
      );
    });
  });

  group('GetQuestTravelPreview', () {
    final operation = _operationOf(TravelQueries.getQuestTravelPreview);

    test('is a single query named GetQuestTravelPreview (D-01)', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetQuestTravelPreview');
    });

    test('declares the request variable as AcceptQuestRequest! (D-01)', () {
      final variable = operation.variableDefinitions.single;
      final type = variable.type as NamedTypeNode;
      expect(variable.variable.name.value, 'request');
      expect(type.name.value, 'AcceptQuestRequest');
      expect(type.isNonNull, isTrue);
    });

    test('selects the shared preview fields of questTravelPreview (D-01)', () {
      expect(
        _collapsed(TravelQueries.getQuestTravelPreview),
        contains(
          'questTravelPreview(request: \$request) '
          '{ distance duration road { coordinates distance } '
          'food { quantity item { id name } } hpLost arrivesAlive }',
        ),
      );
    });

    test('is registered in the schema check (D-01)', () {
      expect(
        schemaCheckDocuments['GetQuestTravelPreview'],
        TravelQueries.getQuestTravelPreview,
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

  group('TeleportCharacter', () {
    final operation = _operationOf(TravelMutations.teleportCharacter);

    test('is a single mutation named TeleportCharacter', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'TeleportCharacter');
    });

    test('declares the request variable as TravelRequest!', () {
      _expectTravelRequestVariable(operation);
    });

    test('selects response and successful of teleportCharacter', () {
      expect(
        _collapsed(TravelMutations.teleportCharacter),
        contains(
          'teleportCharacter(request: \$request) { response successful }',
        ),
      );
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['TeleportCharacter'],
        TravelMutations.teleportCharacter,
      );
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
    test('selects the lore imagePath for the confirmation sheet (D-06)', () {
      expect(
        _collapsed(CityQueries.getAllCities),
        contains('relatedLore { id description imagePath }'),
      );
    });
  });

  group('ListPointsOfInterest (Phase 21)', () {
    test('selects id, type, location and the city name for the teleport '
        '(D-29)', () {
      expect(
        _collapsed(PointOfInterestQueries.listPointsOfInterest),
        contains('pointOfInterests { id type location city { id name } }'),
      );
    });

    test('is registered under its operation name (D-29)', () {
      expect(
        schemaCheckDocuments['ListPointsOfInterest'],
        PointOfInterestQueries.listPointsOfInterest,
      );
    });
  });

  test('the schema check registers 47 documents (D-12, D-29)', () {
    expect(schemaCheckDocuments.length, 47);
  });
}
