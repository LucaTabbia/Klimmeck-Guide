import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';

/// Unico accesso del pannello del GM ai servizi (graphql.md: mai
/// OperationException alla UI). Il ruolo è verificato dal BE (`@Roles(innkeeper)`,
/// ADMIN-07): qui `FORBIDDEN` è solo un esito da mostrare.
class InnkeeperRepository {
  InnkeeperRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Come accettazione quest, viaggio, magie e risultati.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  /// Snapshot alla sottoscrizione, poi la coda intera a ogni cambio; gli
  /// errori dello stream restano quelli tipizzati del servizio.
  Stream<List<PendingRequest>> watchQueue() =>
      _graphQl.subscribeToPendingRequests();

  Future<List<PendingRequest>> fetchQueue() =>
      _guard(_graphQl.getPendingRequests);

  /// Lettura del GM di un personaggio qualsiasi (BE Phase 3): form e
  /// teletrasporto.
  Future<Character> readCharacter(String characterId) =>
      _guard(() => _graphQl.getCharacter(characterId));

  Future<List<QuestResult>> complete(CompletePendingRequestInput input) =>
      _guard(() => _graphQl.completePendingRequest(input));

  /// La nuova posizione arriva dalla coda o da `characterUpdated`, mai da qui.
  Future<void> teleport({
    required String characterId,
    required String poiId,
  }) async {
    final teleported = await _guard(
      () => _graphQl.teleportCharacter(
        TravelRequest(id: characterId, poiId: poiId),
      ),
    );
    if (!teleported) throw const InnkeeperException(InnkeeperFailure.declined);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw InnkeeperException(innkeeperFailureFrom(error));
    } on GraphQlAccessDeniedException catch (error) {
      throw InnkeeperException(
        error.code == forbiddenCode
            ? InnkeeperFailure.forbidden
            : InnkeeperFailure.notFound,
      );
    } on TimeoutException {
      throw const InnkeeperException(InnkeeperFailure.timedOut);
    } on FormatException {
      throw const InnkeeperException(InnkeeperFailure.malformed);
    } on Object {
      throw const InnkeeperException(InnkeeperFailure.unknown);
    }
  }
}
