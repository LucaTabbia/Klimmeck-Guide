import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';

const String _unnamedItem = 'Oggetto';
const String _unnamedSpell = 'Magia sconosciuta';
const String _unknownTitle = 'Sconosciuto';
const String _fallbackParticipantName = 'Personaggio';

/// Riepilogo della conferma (10-CONTEXT D-11): quest, numero di partecipanti
/// e solo le modifiche rispetto ai default. Copy provvisoria (D-22).
String confirmationRecapOf({
  required RequestCard card,
  required List<ParticipantDraft> drafts,
}) {
  final changes = [
    for (final draft in drafts)
      if (_changesOf(draft) case final changes when changes.isNotEmpty)
        '${draft.name}: ${changes.join(', ')}',
  ];
  return [
    card.questTitle,
    'Partecipanti: ${drafts.length}',
    if (changes.isEmpty)
      'Nessuna modifica: i partecipanti restano come sono'
    else
      ...changes,
  ].join('\n');
}

List<String> _changesOf(ParticipantDraft draft) => [
  if (draft.hpAfter != draft.currentLifePoints)
    'PV ${draft.currentLifePoints} → ${draft.hpAfter}',
  for (final injury in draft.addedInjuries) injury.label,
  for (final line in draft.consumables)
    if (line.used > 0) '${line.name ?? _unnamedItem} ×${line.used}',
  for (final line in draft.spells)
    if (line.used > 0) '${line.name ?? _unnamedSpell} ×${line.used}',
];

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
    'Magia appresa: ${spell.name ?? _unnamedSpell}',
];

/// Nome del partecipante dell'esito, dalla carta completata.
String recapNameOf(QuestResult result, RequestCard card) {
  for (final participant in card.participants) {
    if (participant.id == result.characterId) return participant.name;
  }
  return _fallbackParticipantName;
}
