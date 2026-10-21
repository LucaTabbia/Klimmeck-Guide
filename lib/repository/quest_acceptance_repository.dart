import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/accept_quest_request.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso dell'accettazione quest ai servizi: ogni errore diventa
/// [QuestAcceptanceException] (graphql.md: mai OperationException alla UI).
class QuestAcceptanceRepository {
  QuestAcceptanceRepository({required KlimmeckGraphQl graphQl})
    : _graphQl = graphQl;

  final KlimmeckGraphQl _graphQl;

  Future<void> accept({
    required String characterId,
    required String questId,
  }) async {
    try {
      await _graphQl.acceptQuest(
        AcceptQuestRequest(id: characterId, questId: questId),
      );
    } on OperationException catch (error) {
      throw QuestAcceptanceException(questAcceptanceFailureFrom(error));
    } on FormatException {
      throw const QuestAcceptanceException(QuestAcceptanceFailure.unknown);
    }
  }
}
