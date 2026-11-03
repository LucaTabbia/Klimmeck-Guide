import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_pet_request.dart';
import 'package:klimmeck_guide/repository/companion_repository.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

Matcher _failsWith(PetEquipFailure failure) => throwsA(
  isA<PetEquipException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late CompanionRepository repository;

  setUpAll(() {
    registerFallbackValue(const EquipPetRequest(id: '', petId: ''));
    registerFallbackValue(const UnequipPetRequest(id: ''));
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = CompanionRepository(graphQl: graphQl);
  });

  Future<void> equipHorse() =>
      repository.equip(characterId: 'c-1', petId: 'pet-travel-horse');

  test('times out after 15 seconds by default (D-15)', () {
    expect(CompanionRepository.defaultTimeout, const Duration(seconds: 15));
  });

  test(
    'equip sends EquipPetRequest with the character and the pet ids (D-10)',
    () async {
      when(() => graphQl.equipPet(any())).thenAnswer((_) async => true);

      await equipHorse();

      verify(
        () => graphQl.equipPet(
          const EquipPetRequest(id: 'c-1', petId: 'pet-travel-horse'),
        ),
      ).called(1);
    },
  );

  test(
    'unequip sends UnequipPetRequest with the character id only (D-10)',
    () async {
      when(() => graphQl.unequipPet(any())).thenAnswer((_) async => true);

      await repository.unequip(characterId: 'c-1');

      verify(
        () => graphQl.unequipPet(const UnequipPetRequest(id: 'c-1')),
      ).called(1);
    },
  );

  test('successful false becomes declined', () async {
    when(() => graphQl.equipPet(any())).thenAnswer((_) async => false);
    when(() => graphQl.unequipPet(any())).thenAnswer((_) async => false);

    await expectLater(equipHorse(), _failsWith(PetEquipFailure.declined));
    await expectLater(
      repository.unequip(characterId: 'c-1'),
      _failsWith(PetEquipFailure.declined),
    );
  });

  test('a coded refusal becomes its PetEquipFailure (D-06)', () async {
    when(() => graphQl.equipPet(any())).thenThrow(_coded('PET_NOT_OWNED'));
    when(() => graphQl.unequipPet(any())).thenThrow(_coded('FORBIDDEN'));

    await expectLater(equipHorse(), _failsWith(PetEquipFailure.notOwned));
    await expectLater(
      repository.unequip(characterId: 'c-1'),
      _failsWith(PetEquipFailure.forbidden),
    );
  });

  test('no answer within the timeout becomes timedOut', () {
    fakeAsync((async) {
      when(
        () => graphQl.equipPet(any()),
      ).thenAnswer((_) => Completer<bool>().future);
      Object? failure;

      equipHorse().then<void>(
        (_) {},
        onError: (Object error) => failure = error,
      );
      async.elapse(const Duration(seconds: 14));
      expect(failure, isNull);
      async.elapse(const Duration(seconds: 1));

      expect(
        failure,
        isA<PetEquipException>().having(
          (e) => e.failure,
          'failure',
          PetEquipFailure.timedOut,
        ),
      );
    });
  });

  test('any other error becomes unknown', () async {
    when(
      () => graphQl.equipPet(any()),
    ).thenThrow(const FormatException('equipPet malformed'));
    when(() => graphQl.unequipPet(any())).thenThrow(StateError('boom'));

    await expectLater(equipHorse(), _failsWith(PetEquipFailure.unknown));
    await expectLater(
      repository.unequip(characterId: 'c-1'),
      _failsWith(PetEquipFailure.unknown),
    );
  });
}
