import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/abandon_quest_request.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso dell'abbandono del gruppo ai servizi: ogni errore diventa
/// [QuestAbandonException] (graphql.md: mai OperationException alla UI).
class QuestAbandonRepository {
  QuestAbandonRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Stesso tetto dell'accettazione: oltre, il foglio si chiude con un avviso.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  Future<void> abandon({
    required String characterId,
    required String questId,
  }) async {
    try {
      await _graphQl
          .abandonQuest(AbandonQuestRequest(id: characterId, questId: questId))
          .timeout(timeout);
    } on OperationException catch (error) {
      throw QuestAbandonException(questAbandonFailureFrom(error));
    } on TimeoutException {
      throw const QuestAbandonException(QuestAbandonFailure.timedOut);
    } on Object {
      throw const QuestAbandonException(QuestAbandonFailure.unknown);
    }
  }
}
