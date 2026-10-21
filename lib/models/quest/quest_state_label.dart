import '../enums/quest_type.dart';
import '../pending_quest.dart';

/// Etichetta di stato del foglio sulla mappa (D-15): nessun countdown.
String questStateLabel(PendingQuest lane, QuestType? type) {
  if (lane.startDate == null) return 'In viaggio';
  return switch (type) {
    QuestType.enemy || QuestType.boss => 'In combattimento…',
    QuestType.hunt => 'Cacciando…',
    QuestType.dungeon => 'Esplorando…',
    QuestType.job => 'Lavorando…',
    QuestType.heal => 'Guarendo…',
    QuestType.aid => 'Aiutando…',
    QuestType.study => 'Studiando…',
    _ => 'In corso…',
  };
}
