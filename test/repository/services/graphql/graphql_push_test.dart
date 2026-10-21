import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

String? operationNameOf(Request request) => request
    .operation
    .document
    .definitions
    .whereType<OperationDefinitionNode>()
    .first
    .name
    ?.value;

Matcher _operationExceptionWithCode(String code) =>
    throwsA(isA<OperationException>().having(graphQlErrorCode, 'code', code));

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((request, [forward]) {
        requests.add(request);
        return handler(request);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  setUp(() {
    requests = [];
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('registerPushDevice', () {
    Future<void> register(KlimmeckGraphQl graphQl) => graphQl
        .registerPushDevice(deviceId: 'd-1', token: 't-1', platform: 'android');

    test('sends RegisterPushDevice with the nested input', () async {
      handler = (_) => Stream.value(dataResponse({'registerPushDevice': true}));

      await register(buildGraphQl());

      expect(operationNameOf(requests.single), 'RegisterPushDevice');
      expect(requests.single.variables, {
        'input': {'deviceId': 'd-1', 'token': 't-1', 'platform': 'android'},
      });
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('PUSH_INVALID_TOKEN'));

      await expectLater(
        register(buildGraphQl()),
        _operationExceptionWithCode('PUSH_INVALID_TOKEN'),
      );
    });
  });

  group('unregisterPushDevice', () {
    test('sends UnregisterPushDevice with the device id', () async {
      handler = (_) =>
          Stream.value(dataResponse({'unregisterPushDevice': true}));

      await buildGraphQl().unregisterPushDevice('d-1');

      expect(operationNameOf(requests.single), 'UnregisterPushDevice');
      expect(requests.single.variables, {'deviceId': 'd-1'});
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('UNAUTHENTICATED'));

      await expectLater(
        buildGraphQl().unregisterPushDevice('d-1'),
        _operationExceptionWithCode('UNAUTHENTICATED'),
      );
    });
  });
}
