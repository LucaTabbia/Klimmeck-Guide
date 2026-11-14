import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/fragments.dart';
import 'package:klimmeck_guide/graphql/queries/pending_request_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/pending_request_subscriptions.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void main() {
  final sharedSelection = _collapsed(PendingRequestFragment.fields);

  group('PendingRequestFragment', () {
    test('selects what the request card shows', () {
      expect(sharedSelection, contains('requiredAdventurers { title count }'));
      expect(sharedSelection, contains('activeTravel { endTime to }'));
      expect(sharedSelection, contains('awaitingAid { quest aidQuest since }'));
      expect(sharedSelection, contains('location'));
      expect(sharedSelection, contains('startDate'));
    });

    test('selects the busy standard lane under character (BE-HARD-08)', () {
      final characterSelection = sharedSelection.substring(
        sharedSelection.indexOf('character {'),
      );

      expect(characterSelection, contains('pendingQuest'));
      expect('pendingQuest'.allMatches(sharedSelection), hasLength(1));
    });

    test('the queue entry selects missionDraftStartedAt after startDate '
        '(D-17)', () {
      expect(
        sharedSelection,
        contains('startDate missionDraftStartedAt quest {'),
      );
    });

    test('never selects the private fields', () {
      for (final field in ['user', 'twitchId', 'pointsSpent', 'road']) {
        expect(sharedSelection, isNot(contains(field)), reason: field);
      }
    });
  });

  group('GetPendingRequests', () {
    final operation = _operationOf(PendingRequestQueries.getPendingRequests);
    final document = _collapsed(PendingRequestQueries.getPendingRequests);

    test('is a query without variables', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetPendingRequests');
      expect(operation.variableDefinitions, isEmpty);
    });

    test('reads pendingRequests with the shared fragment', () {
      expect(document, contains('pendingRequests { $sharedSelection }'));
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['GetPendingRequests'],
        PendingRequestQueries.getPendingRequests,
      );
    });
  });

  group('OnPendingRequestsUpdated', () {
    final operation = _operationOf(
      PendingRequestSubscriptions.pendingRequestsUpdated,
    );
    final document = _collapsed(
      PendingRequestSubscriptions.pendingRequestsUpdated,
    );

    test('is a subscription without variables', () {
      expect(operation.type, OperationType.subscription);
      expect(operation.name?.value, 'OnPendingRequestsUpdated');
      expect(operation.variableDefinitions, isEmpty);
    });

    test('listens to pendingRequestsUpdated with the shared fragment', () {
      expect(document, contains('pendingRequestsUpdated { $sharedSelection }'));
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['OnPendingRequestsUpdated'],
        PendingRequestSubscriptions.pendingRequestsUpdated,
      );
    });
  });

  test('the completion form document is gone (D-25)', () {
    expect(
      schemaCheckDocuments,
      isNot(
        contains(
          'Complete'
          'PendingRequest',
        ),
      ),
    );
  });
}
