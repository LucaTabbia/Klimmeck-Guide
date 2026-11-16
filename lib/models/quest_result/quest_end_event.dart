import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/utils/quest_outcome_lines.dart';

/// Copy dei push `questEnd`, `spellResearchSucceeded` e `spellResearchFailed`
/// (BE Phase 9 §4, Phase 23 D-29, D-31) e dei banner pubblicati dalla
/// subscription (D-12): un solo posto per le stesse stringhe.
const String questEndTitle = 'Missione conclusa';
const String questEndBody = "La tua missione è terminata: scopri com'è andata.";
const String spellResearchSucceededTitle = 'Ricerca riuscita';
const String spellResearchFailedTitle = 'Ricerca conclusa';
const String spellResearchFailedBody =
    "Nessuna magia scoperta: scopri com'è andata la missione.";

/// Evento del banner per un risultato arrivato dalla subscription (D-12): la
/// chiave `questEnd|<id>` coincide con quella del push in foreground (dedup),
/// anche per i due push della ricerca.
PushEvent questEndEventOf(QuestResult result) {
  final copy = _copyOf(result);
  return PushEvent(
    category: NotificationCategory.questEnd,
    title: copy.title,
    body: copy.body,
    sentAt: result.resolvedAt,
    id: result.id,
  );
}

({String title, String body}) _copyOf(QuestResult result) {
  final spell = result.spellFound;
  if (spell != null) {
    return (title: spellResearchSucceededTitle, body: _spellFoundBody(spell));
  }
  if (result.spellResearchFailed) {
    return (title: spellResearchFailedTitle, body: spellResearchFailedBody);
  }
  return (title: questEndTitle, body: questEndBody);
}

/// Nome e durata serviti (D-31): senza nome «una magia», senza durata valida
/// solo la scoperta.
String _spellFoundBody(Spell spell) {
  final name = spell.name?.trim() ?? '';
  final subject = name.isEmpty ? 'una magia' : '«$name»';
  final learnTime = spellLearnTimeOf(spell);
  if (learnTime == null) return 'Hai scoperto $subject.';
  return "Hai scoperto $subject: l'apprendimento dura $learnTime.";
}
