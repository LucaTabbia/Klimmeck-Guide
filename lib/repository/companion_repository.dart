import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_pet_request.dart';
import 'package:klimmeck_guide/models/request/rename_pet_request.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/repository/pet_rename_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso dello slot «Compagno» ai servizi: ogni errore diventa
/// [PetEquipException] o, per il nome, [PetRenameException] (graphql.md: mai
/// OperationException alla UI). Lo stato arriva solo da `characterUpdated`
/// (D-11).
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

  /// Nome del compagno [petId] (D-19); il nome parte sempre valorizzato (D-31).
  Future<void> rename({
    required String characterId,
    required String petId,
    required String name,
  }) async {
    final successful = await _guardRename(
      () => _graphQl.renamePet(
        RenamePetRequest(id: characterId, petId: petId, name: name),
      ),
    );
    if (!successful) {
      throw const PetRenameException(PetRenameFailure.declined);
    }
  }

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

  Future<bool> _guardRename(Future<bool> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw PetRenameException(petRenameFailureFrom(error));
    } on TimeoutException {
      throw const PetRenameException(PetRenameFailure.timedOut);
    } on Object {
      throw const PetRenameException(PetRenameFailure.unknown);
    }
  }
}
