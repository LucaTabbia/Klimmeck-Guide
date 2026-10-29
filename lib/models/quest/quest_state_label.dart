import '../enums/quest_type.dart';
import '../pending_quest.dart';
import 'quest.dart';
import 'quest_capacity.dart';

/// Etichetta di stato del foglio sulla mappa (D-15): nessun countdown.
String questStateLabel(PendingQuest lane, Quest? quest) {
  if (lane.isTravelling) return 'In viaggio';
  if (lane.isWaitingForParty && !_isSolo(quest)) return _waitingLabel(quest);
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

/// Senza posti di gruppo nessuno da attendere: sul marker la quest parte
/// subito, anche se lo `startDate` del BE arriva un attimo dopo.
bool _isSolo(Quest? quest) => quest != null && _seatsOf(quest) == 0;

int _seatsOf(Quest? quest) =>
    totalSlots(quest?.requirements?.requiredAdventurers ?? const []);

/// La quest registrata parte solo col gruppo al completo sul marker (BE 09-19).
String _waitingLabel(Quest? quest) {
  const label = 'In attesa del gruppo';
  if (quest == null) return label;
  return '$label ${quest.registeredAdventurers.length}/${_seatsOf(quest)}';
}
