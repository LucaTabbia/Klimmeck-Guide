import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/fragments.dart';
import 'package:klimmeck_guide/graphql/mutations/pending_request_mutations.dart';
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

    test('never selects the gated or private fields', () {
      for (final field in [
        'pendingQuest',
        'user',
        'twitchId',
        'pointsSpent',
        'road',
      ]) {
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

  group('CompletePendingRequest', () {
    final operation = _operationOf(
      PendingRequestMutations.completePendingRequest,
    );
    final document = _collapsed(PendingRequestMutations.completePendingRequest);

    test('is a mutation with a typed input', () {
      expect(operation.type, OperationType.mutation);
      expect(operation.name?.value, 'CompletePendingRequest');
      final variable = operation.variableDefinitions.single;
      final type = variable.type as NamedTypeNode;
      expect(variable.variable.name.value, 'input');
      expect(type.name.value, 'CompletePendingRequestInput');
      expect(type.isNonNull, isTrue);
    });

    test('returns the created results with the quest result fragment', () {
      expect(
        document,
        contains(
          'completePendingRequest(input: \$input) '
          '{ ${_collapsed(QuestResultFragment.fields)} }',
        ),
      );
    });

    test('is registered in the schema check', () {
      expect(
        schemaCheckDocuments['CompletePendingRequest'],
        PendingRequestMutations.completePendingRequest,
      );
    });
  });
}
