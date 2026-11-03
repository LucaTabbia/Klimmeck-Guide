import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_pet_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  const equipRequest = EquipPetRequest(id: 'c-1', petId: 'pet-travel-horse');
  const unequipRequest = UnequipPetRequest(id: 'c-1');

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((incoming, [forward]) {
        requests.add(incoming);
        return handler(incoming);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  String? operationNameOf(Request sent) => sent.operation.document.definitions
      .whereType<OperationDefinitionNode>()
      .first
      .name
      ?.value;

  Matcher throwsOperationCoded(String code) =>
      throwsA(isA<OperationException>().having(graphQlErrorCode, 'code', code));

  Response successfulResponse(String field) => dataResponse({
    field: {'response': 'ok', 'successful': true},
  });

  setUp(() {
    requests = [];
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('getCityShop', () {
    test(
      'getCityShop sends GetCityShop with the cityId and parses the pool (D-01)',
      () async {
        handler = (_) => Stream.value(
          dataResponse({
            'cityShop': cityShopJson(
              equipment: [equipmentAssetJson()],
              loot: [lootAssetJson()],
              pets: [petJson()],
            ),
          }),
        );

        final pool = await buildGraphQl().getCityShop('city-talmvere');

        expect(operationNameOf(requests.single), 'GetCityShop');
        expect(requests.single.variables, {'cityId': 'city-talmvere'});
        expect(pool.cityId, 'city-talmvere');
        expect(pool.equipment, hasLength(1));
        expect(pool.loot, hasLength(1));
        expect(pool.pets.single.id, 'pet-travel-horse');
      },
    );

    test('getCityShop rethrows the coded OperationException', () async {
      handler = (_) => Stream.value(errorCodeResponse('NOT_FOUND'));

      await expectLater(
        buildGraphQl().getCityShop('city-talmvere'),
        throwsOperationCoded('NOT_FOUND'),
      );
    });

    test('getCityShop throws FormatException on a malformed pool', () async {
      handler = (_) => Stream.value(dataResponse({'cityShop': null}));

      await expectLater(
        buildGraphQl().getCityShop('city-talmvere'),
        throwsFormatException,
      );
    });
  });

  group('equipPet / unequipPet', () {
    test(
      'equipPet sends EquipPet with the character and pet ids (D-16)',
      () async {
        handler = (_) => Stream.value(successfulResponse('equipPet'));

        final successful = await buildGraphQl().equipPet(equipRequest);

        expect(operationNameOf(requests.single), 'EquipPet');
        expect(requests.single.variables, {
          'request': {'id': 'c-1', 'petId': 'pet-travel-horse'},
        });
        expect(successful, isTrue);
      },
    );

    test(
      'unequipPet sends UnequipPet with the character id only (D-16)',
      () async {
        handler = (_) => Stream.value(successfulResponse('unequipPet'));

        final successful = await buildGraphQl().unequipPet(unequipRequest);

        expect(operationNameOf(requests.single), 'UnequipPet');
        expect(requests.single.variables, {
          'request': {'id': 'c-1'},
        });
        expect(successful, isTrue);
      },
    );

    test(
      'equipPet throws FormatException when successful is missing',
      () async {
        handler = (_) => Stream.value(
          dataResponse({
            'equipPet': {'response': 'ok'},
          }),
        );

        await expectLater(
          buildGraphQl().equipPet(equipRequest),
          throwsFormatException,
        );
      },
    );

    test(
      'equipPet rethrows PET_NOT_OWNED as an OperationException (D-06)',
      () async {
        handler = (_) => Stream.value(errorCodeResponse('PET_NOT_OWNED'));

        await expectLater(
          buildGraphQl().equipPet(equipRequest),
          throwsOperationCoded('PET_NOT_OWNED'),
        );
      },
    );
  });
}
