import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Nomi di riserva condivisi dai riepiloghi e dai passi della missione guidata
/// (copy provvisoria, D-22).
const String unnamedItemLabel = 'Oggetto';
const String unnamedSpellLabel = 'Magia sconosciuta';

const String _unknownTitle = 'Sconosciuto';
const String _fallbackParticipantName = 'Personaggio';

/// Righe dell'esito di un personaggio per il riepilogo del GM (10-CONTEXT
/// D-13): livello, titolo e magia solo quando cambiano.
List<String> resultRecapLinesOf(QuestResult result) => [
  result.outcome.label,
  'PV ${result.hpBefore} → ${result.hpAfter}',
  if (result.injuriesAdded.isNotEmpty)
    'Ferite: ${result.injuriesAdded.map((injury) => injury.label).join(', ')}',
  '+${result.xpGained} XP',
  if (result.hasLevelChanged)
    'Livello ${result.levelBefore} → ${result.levelAfter}',
  if (result.hasTitleChanged)
    'Titolo: ${result.titleBefore?.label ?? _unknownTitle} → '
        '${result.titleAfter?.label ?? _unknownTitle}',
  if (result.spellLearned case final spell?)
    'Magia appresa: ${spell.name ?? unnamedSpellLabel}',
];

/// Nome del partecipante dell'esito, dalla carta completata.
String recapNameOf(QuestResult result, RequestCard card) {
  for (final participant in card.participants) {
    if (participant.id == result.characterId) return participant.name;
  }
  return _fallbackParticipantName;
}
