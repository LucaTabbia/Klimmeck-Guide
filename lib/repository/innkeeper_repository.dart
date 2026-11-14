import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
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

  /// Luoghi del mondo per il teletrasporto dell'oste (D-01, D-29).
  Future<List<PointOfInterest>> listPointsOfInterest() =>
      _guard(_graphQl.getPointsOfInterest);

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

  /// Una corsa del generatore (QGEN-03): quante quest ha creato. `FORBIDDEN`
  /// chiude il pannello come le altre azioni del GM (D-09, Phase 10 D-04).
  Future<int> generateQuests() => _guard(_graphQl.generateQuests);

  /// Bozza servita della richiesta (D-09): null se non è ancora iniziata.
  Future<MissionDraft?> readMissionDraft(String pendingQuestId) =>
      _guard(() => _graphQl.getMissionDraft(pendingQuestId));

  /// Crea la bozza dalla pagina «Inizia la missione» (D-28).
  Future<MissionDraft> startMissionDraft(String pendingQuestId) =>
      _guard(() => _graphQl.startMissionDraft(pendingQuestId));

  Future<MissionDraft> saveMissionDraft(SaveMissionDraftInput input) =>
      _guard(() => _graphQl.saveMissionDraft(input));

  /// Azione esplicita dell'oste (D-04): l'esito si legge dalla bozza.
  Future<MissionDraft> simulateMissionFight(SimulateMissionFightInput input) =>
      _guard(() => _graphQl.simulateMissionFight(input));

  Future<void> discardMissionDraft(String pendingQuestId) async {
    final discarded = await _guard(
      () => _graphQl.discardMissionDraft(pendingQuestId),
    );
    if (!discarded) throw const InnkeeperException(InnkeeperFailure.declined);
  }

  /// Completa la missione leggendo la bozza (D-08, D-25).
  Future<List<QuestResult>> completeGuidedMission(String pendingQuestId) =>
      _guard(() => _graphQl.completeGuidedMission(pendingQuestId));

  /// Nemici già scelti dal BE per la missione (D-03); `showAll` è «Mostra
  /// tutti».
  Future<List<MissionEnemy>> listMissionEnemies(
    String pendingQuestId, {
    bool showAll = false,
  }) => _guard(
    () => _graphQl.getMissionEnemies(pendingQuestId, showAll: showAll),
  );

  /// Blocco del rango e catalogo del personaggio (D-07): mai filtrati qui.
  Future<MissionPrizeOptions> readMissionPrizeOptions({
    required String pendingQuestId,
    required String characterId,
  }) => _guard(
    () => _graphQl.getMissionPrizeOptions(
      pendingQuestId: pendingQuestId,
      characterId: characterId,
    ),
  );

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
