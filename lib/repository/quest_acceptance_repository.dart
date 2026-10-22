import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/accept_quest_request.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso dell'accettazione quest ai servizi: ogni errore diventa
/// [QuestAcceptanceException] (graphql.md: mai OperationException alla UI).
class QuestAcceptanceRepository {
  QuestAcceptanceRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Oltre questo tempo senza risposta l'accettazione fallisce come
  /// `timedOut`: la UI ricompone il foglio invece di restare appesa
  /// (UAT 2026-10-22: BE bloccato su Redis, risposta HTTP mai partita).
  /// La richiesta non viene annullata: una risposta tardiva del BE accetta
  /// comunque la quest, e la corsia arriva via `characterUpdated`.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  Future<void> accept({
    required String characterId,
    required String questId,
  }) async {
    try {
      await _graphQl
          .acceptQuest(AcceptQuestRequest(id: characterId, questId: questId))
          .timeout(timeout);
    } on OperationException catch (error) {
      throw QuestAcceptanceException(questAcceptanceFailureFrom(error));
    } on TimeoutException {
      throw const QuestAcceptanceException(QuestAcceptanceFailure.timedOut);
    } on Object {
      throw const QuestAcceptanceException(QuestAcceptanceFailure.unknown);
    }
  }
}
