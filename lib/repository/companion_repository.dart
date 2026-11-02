import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_pet_request.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso dello slot «Compagno» ai servizi: ogni errore diventa
/// [PetEquipException] (graphql.md: mai OperationException alla UI). Lo
/// stato arriva solo da `characterUpdated` (D-11).
class CompanionRepository {
  CompanionRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Come le magie (Phase 8) e il viaggio (Phase 7).
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  Future<void> equip({required String characterId, required String petId}) =>
      _confirm(
        () => _graphQl.equipPet(EquipPetRequest(id: characterId, petId: petId)),
      );

  Future<void> unequip({required String characterId}) =>
      _confirm(() => _graphQl.unequipPet(UnequipPetRequest(id: characterId)));

  Future<void> _confirm(Future<bool> Function() call) async {
    final successful = await _guard(call);
    if (!successful) {
      throw const PetEquipException(PetEquipFailure.declined);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw PetEquipException(petEquipFailureFrom(error));
    } on TimeoutException {
      throw const PetEquipException(PetEquipFailure.timedOut);
    } on Object {
      throw const PetEquipException(PetEquipFailure.unknown);
    }
  }
}
