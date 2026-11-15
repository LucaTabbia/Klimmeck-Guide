import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/rename_pet_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  const request = RenamePetRequest(
    id: 'c-1',
    petId: 'pet-worg',
    name: 'Fenrir',
  );

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((incoming, [forward]) {
        requests.add(incoming);
        return handler(incoming);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  setUp(() {
    requests = [];
    handler = (_) => Stream.value(
      dataResponse({
        'renamePet': {'response': 'ok', 'successful': true},
      }),
    );
  });

  test('renamePet sends the request and returns successful (D-19)', () async {
    final successful = await buildGraphQl().renamePet(request);

    final operation = requests.single.operation.document.definitions
        .whereType<OperationDefinitionNode>()
        .first;
    expect(operation.name?.value, 'RenamePet');
    expect(requests.single.variables, {
      'request': {'id': 'c-1', 'petId': 'pet-worg', 'name': 'Fenrir'},
    });
    expect(successful, isTrue);
  });

  test('a refusal throws its OperationException (D-19)', () async {
    handler = (_) => Stream.value(errorCodeResponse('PET_NAME_INVALID'));

    await expectLater(
      buildGraphQl().renamePet(request),
      throwsA(
        isA<OperationException>().having(
          graphQlErrorCode,
          'code',
          'PET_NAME_INVALID',
        ),
      ),
    );
  });
}
