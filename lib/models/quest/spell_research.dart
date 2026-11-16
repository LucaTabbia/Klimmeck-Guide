import '../enums/quest_type.dart';
import 'quest_prizes.dart';

const Set<QuestType> _schoolTypes = {
  QuestType.arcane,
  QuestType.shamanic,
  QuestType.theVoid,
};

/// Una quest avviata è una «Fase di ricerca» (D-26) se è di scuola o se il
/// blocco dei premi servito porta il sorteggio.
bool isSpellResearchQuest(QuestType? type, QuestPrizes? prizes) =>
    _schoolTypes.contains(type) || (prizes?.spellDraw ?? false);
