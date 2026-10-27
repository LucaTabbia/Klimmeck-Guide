import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_spell_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';

/// Unico accesso delle magie ai servizi: ogni errore diventa
/// [SpellEquipException] (graphql.md: mai OperationException alla UI). Lo
/// stato non arriva mai da qui: solo da `characterUpdated` (D-16).
class SpellsRepository {
  SpellsRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Come accettazione quest e viaggio (Phase 6 D-03, Phase 7).
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  Future<void> equip({required String characterId, required String spellId}) =>
      _confirm(
        () => _graphQl.equipSpell(
          EquipSpellRequest(id: characterId, spellId: spellId),
        ),
      );

  Future<void> unequip({
    required String characterId,
    required String spellId,
  }) => _confirm(
    () => _graphQl.unequipSpell(
      EquipSpellRequest(id: characterId, spellId: spellId),
    ),
  );

  Future<void> _confirm(Future<bool> Function() call) async {
    final successful = await _guard(call);
    if (!successful) {
      throw const SpellEquipException(SpellEquipFailure.declined);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw SpellEquipException(spellEquipFailureFrom(error));
    } on TimeoutException {
      throw const SpellEquipException(SpellEquipFailure.timedOut);
    } on Object {
      throw const SpellEquipException(SpellEquipFailure.unknown);
    }
  }
}
