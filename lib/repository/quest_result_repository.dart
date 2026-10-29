import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_delivery_ports.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso ai risultati: ogni errore diventa [QuestResultException]
/// (graphql.md); lo stato del personaggio non arriva mai da qui (regola 4).
/// Implementa le porte di consegna della BE 9.2 (D-09, D-10).
class QuestResultRepository
    implements PendingQuestResults, QuestResultAcknowledger {
  QuestResultRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Come accettazione quest, viaggio e magie.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  /// Esiti in foreground: errori tipizzati dal servizio, senza chiudere lo
  /// stream su un evento malformato.
  Stream<QuestResult> watch(String characterId) =>
      _graphQl.subscribeToQuestResults(characterId);

  Future<QuestResult> fetch(String resultId) =>
      _guard(() => _graphQl.getQuestResult(resultId));

  @override
  Future<List<QuestResult>> fetchUnacknowledged() =>
      _guard(_graphQl.getUnacknowledgedQuestResults);

  @override
  Future<void> acknowledge(String resultId) =>
      _guard(() => _graphQl.acknowledgeQuestResult(resultId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw QuestResultException(questResultFailureFrom(error));
    } on TimeoutException {
      throw const QuestResultException(QuestResultFailure.timedOut);
    } on FormatException {
      throw const QuestResultException(QuestResultFailure.malformed);
    } on Object {
      throw const QuestResultException(QuestResultFailure.unknown);
    }
  }
}
