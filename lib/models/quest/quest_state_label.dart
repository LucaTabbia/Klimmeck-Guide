import '../enums/quest_type.dart';
import '../pending_quest.dart';
import 'quest.dart';
import 'quest_capacity.dart';

/// Etichetta di stato del foglio sulla mappa (D-15): nessun countdown.
String questStateLabel(PendingQuest lane, Quest? quest) {
  if (lane.isTravelling) return 'In viaggio';
  if (lane.isWaitingForParty) return _waitingLabel(quest);
  return switch (quest?.infos?.type) {
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

/// La quest registrata parte solo col gruppo al completo sul marker (BE 09-19).
String _waitingLabel(Quest? quest) {
  const label = 'In attesa del gruppo';
  final seats = totalSlots(
    quest?.requirements?.requiredAdventurers ?? const [],
  );
  if (quest == null || seats == 0) return label;
  return '$label ${quest.registeredAdventurers.length}/$seats';
}
