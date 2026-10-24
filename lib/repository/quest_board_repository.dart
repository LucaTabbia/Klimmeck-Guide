import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso della board ai servizi: catalogo quest e POI della città corrente.
class QuestBoardRepository {
  QuestBoardRepository({required KlimmeckGraphQl graphQl}) : _graphQl = graphQl;

  final KlimmeckGraphQl _graphQl;

  Future<List<Quest>> getQuests() => _graphQl.getQuests();

  Future<Set<String>> getCityPointIds(String cityId) =>
      _graphQl.getCityPointIds(cityId);
}
