import 'package:equatable/equatable.dart';

import 'quest.dart';
import 'quest_lane.dart';

/// Riga costo del foglio (D-02): solo story/worldMission, in punti canale.
class QuestCostLine extends Equatable {
  const QuestCostLine({required this.cost, required this.balance});

  final int cost;
  final int? balance;

  bool get isInsufficient => balance != null && balance! < cost;

  String get text => balance == null
      ? 'Punti canale: $cost'
      : 'Punti canale: $balance / $cost';

  @override
  List<Object?> get props => [cost, balance];
}

/// Per tipo, mai per presenza del campo: il catalogo ha `requiredPoints` anche su
/// quest gratuite (handoff BE Phase 7 §6).
QuestCostLine? costLineOf(Quest quest, int? twitchPoints) {
  final type = quest.infos?.type;
  final cost = quest.requirements?.requiredPoints ?? 0;
  if (type == null || laneOf(type) == QuestLane.standard || cost <= 0) {
    return null;
  }
  return QuestCostLine(cost: cost, balance: twitchPoints);
}
