import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/account/graphql_account_deletion_api.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

String? _operationNameOf(Request request) => request
    .operation
    .document
    .definitions
    .whereType<OperationDefinitionNode>()
    .first
    .name
    ?.value;

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  GraphQlAccountDeletionApi buildApi() => GraphQlAccountDeletionApi(
    KlimmeckGraphQl(
      resolveClient: () => GraphQLClient(
        link: Link.function((request, [forward]) {
          requests.add(request);
          return handler(request);
        }),
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    ),
  );

  setUp(() {
    requests = [];
    handler = (_) => Stream.value(dataResponse({}));
  });

  test('deleteMyAccount calls the own deletion (D-20)', () async {
    handler = (_) => Stream.value(dataResponse({'deleteMyAccount': true}));

    await buildApi().deleteMyAccount();

    expect(_operationNameOf(requests.single), 'DeleteMyAccount');
    expect(requests.single.variables, isEmpty);
  });

  test('deleteAccountByTwitchLogin forwards the login (D-15)', () async {
    handler = (_) => Stream.value(
      dataResponse({
        'deleteAccountByTwitchLogin': {'twitchId': '123'},
      }),
    );

    await buildApi().deleteAccountByTwitchLogin('some_viewer');

    expect(_operationNameOf(requests.single), 'DeleteAccountByTwitchLogin');
    expect(requests.single.variables, {'twitchLogin': 'some_viewer'});
  });

  group('errors pass through unchanged', () {
    Matcher operationExceptionWith(String code) => throwsA(
      isA<OperationException>().having(graphQlErrorCode, 'code', code),
    );

    test('the own deletion keeps the code (D-16)', () async {
      handler = (_) =>
          Stream.value(errorCodeResponse('INNKEEPER_ACCOUNT_PROTECTED'));

      await expectLater(
        buildApi().deleteMyAccount(),
        operationExceptionWith('INNKEEPER_ACCOUNT_PROTECTED'),
      );
    });

    test('the innkeeper deletion keeps the code (D-15)', () async {
      handler = (_) => Stream.value(errorCodeResponse('ACCOUNT_NOT_FOUND'));

      await expectLater(
        buildApi().deleteAccountByTwitchLogin('some_viewer'),
        operationExceptionWith('ACCOUNT_NOT_FOUND'),
      );
    });
  });
}
