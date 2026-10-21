import '../enums/quest_type.dart';
import '../enums/title_type.dart';
import 'quest_availability.dart';

/// Riga di rifiuto mostrata al giocatore: testo di dominio fisso, mai testo del
/// server (copy provvisoria, D-19).
String? questBlockedReasonOf(
  QuestAvailability availability, {
  required TitleType? minTitle,
  required QuestType? type,
}) => switch (availability) {
  QuestAvailability.available => null,
  QuestAvailability.tornForOwner => 'Missione già accettata',
  QuestAvailability.notAcceptable => 'Missione non disponibile',
  QuestAvailability.alreadyDone => 'Hai già affrontato questa missione',
  QuestAvailability.titleMismatch =>
    minTitle == null
        ? 'Il tuo titolo non permette questa missione'
        : (type == QuestType.story
              ? 'Serve il titolo ${minTitle.label}'
              : 'Serve almeno il titolo ${minTitle.label}'),
  QuestAvailability.laneBusy => 'Hai già una missione di questo tipo in corso',
  QuestAvailability.full => 'Non ci sono più posti per il tuo rango',
  QuestAvailability.notInCity => 'Devi trovarti nella città della missione',
  QuestAvailability.insufficientPoints => 'Punti canale insufficienti',
};
