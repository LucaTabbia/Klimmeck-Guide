import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  final request = TransactionRequest(
    id: 'c-1',
    boughtItems: TransactionItems(equipAssets: [], lootAssets: []),
    soldItems: TransactionItems(equipAssets: [], lootAssets: []),
    isTotalPositive: false,
    total: const Coins(copper: 3),
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
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('doTransaction', () {
    test('sends the request and returns the response text', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'doTransaction': {'response': 'ok', 'successful': true},
        }),
      );

      final response = await buildGraphQl().doTransaction(request);

      final operation = requests.single.operation.document.definitions
          .whereType<OperationDefinitionNode>()
          .first;
      expect(operation.name?.value, 'doTransaction');
      expect(requests.single.variables['request'], same(request));
      expect(response, 'ok');
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('SHOP_NOT_IN_CITY'));

      await expectLater(
        buildGraphQl().doTransaction(request),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'SHOP_NOT_IN_CITY',
          ),
        ),
      );
    });

    test('throws FormatException when the payload is missing', () async {
      handler = (_) => Stream.value(dataResponse({'doTransaction': null}));

      await expectLater(
        buildGraphQl().doTransaction(request),
        throwsFormatException,
      );
    });

    test('throws FormatException when the response is not a text', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'doTransaction': {'response': 3, 'successful': true},
        }),
      );

      await expectLater(
        buildGraphQl().doTransaction(request),
        throwsFormatException,
      );
    });
  });

  group('equipItem', () {
    final equipRequest = EquipItemRequest(
      id: 'c-1',
      itemId: 'e-1',
      slotType: SlotType.values.first,
    );

    test('sends equipItem with the request and returns successful', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'equipItem': {'response': 'ok', 'successful': true},
        }),
      );

      final successful = await buildGraphQl().equipItem(equipRequest);

      final operation = requests.single.operation.document.definitions
          .whereType<OperationDefinitionNode>()
          .first;
      expect(operation.name?.value, 'equipItem');
      expect(requests.single.variables['request'], equipRequest.toJson());
      expect(successful, isTrue);
    });

    test('keeps the OperationException code (LB-1)', () async {
      handler = (_) => Stream.value(errorCodeResponse('MISSION_IN_PROGRESS'));

      await expectLater(
        buildGraphQl().equipItem(equipRequest),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'MISSION_IN_PROGRESS',
          ),
        ),
      );
    });
  });
}
