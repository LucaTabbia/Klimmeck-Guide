import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/repository/equipment_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

Matcher _failsWith(EquipmentFailure failure) => throwsA(
  isA<EquipmentException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late EquipmentRepository repository;
  final request = EquipItemRequest(
    id: 'c-1',
    itemId: 'e-1',
    slotType: SlotType.values.first,
  );

  setUpAll(() {
    registerFallbackValue(
      EquipItemRequest(
        id: 'c-1',
        itemId: 'e-1',
        slotType: SlotType.values.first,
      ),
    );
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = EquipmentRepository(graphQl: graphQl);
  });

  test('times out after 15 seconds by default', () {
    expect(EquipmentRepository.defaultTimeout, const Duration(seconds: 15));
  });

  test('equip sends the request and resolves on successful true', () async {
    when(() => graphQl.equipItem(any())).thenAnswer((_) async => true);

    await repository.equip(request);

    verify(() => graphQl.equipItem(request)).called(1);
  });

  test('successful false is declined (LB-1)', () async {
    when(() => graphQl.equipItem(any())).thenAnswer((_) async => false);

    await expectLater(
      repository.equip(request),
      _failsWith(EquipmentFailure.declined),
    );
  });

  test('an OperationException with MISSION_IN_PROGRESS becomes '
      'EquipmentException(missionInProgress) (D-11, LB-1)', () async {
    when(
      () => graphQl.equipItem(any()),
    ).thenThrow(_coded('MISSION_IN_PROGRESS'));

    await expectLater(
      repository.equip(request),
      _failsWith(EquipmentFailure.missionInProgress),
    );
  });

  test('a timeout becomes timedOut', () {
    fakeAsync((async) {
      when(
        () => graphQl.equipItem(any()),
      ).thenAnswer((_) => Completer<bool>().future);
      Object? failure;

      repository
          .equip(request)
          .then<void>((_) {}, onError: (Object error) => failure = error);
      async.elapse(const Duration(seconds: 14));
      expect(failure, isNull);
      async.elapse(const Duration(seconds: 1));

      expect(
        failure,
        isA<EquipmentException>().having(
          (e) => e.failure,
          'failure',
          EquipmentFailure.timedOut,
        ),
      );
    });
  });

  test('any other error becomes unknown', () async {
    when(
      () => graphQl.equipItem(any()),
    ).thenThrow(const FormatException('equipItem malformed'));

    await expectLater(
      repository.equip(request),
      _failsWith(EquipmentFailure.unknown),
    );
  });
}
