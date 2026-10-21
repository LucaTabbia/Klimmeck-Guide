import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';

const String questAcceptanceNoticeTitle = 'Missione non accettata';

/// Copy di dominio del banner (D-04), provvisoria (D-19). Nessun banner per
/// UNAUTHENTICATED: il flusso di sessione sta già agendo.
KGNotification? questAcceptanceNoticeFor(
  QuestAcceptanceFailure failure, {
  QuestType? type,
}) {
  final description = switch (failure) {
    QuestAcceptanceFailure.slotBusy => switch (type) {
      QuestType.story => 'Hai già una storia in corso',
      QuestType.worldMission => 'Hai già una missione mondiale in corso',
      _ => 'Hai già una missione in corso',
    },
    QuestAcceptanceFailure.full => 'Non ci sono più posti per il tuo rango',
    QuestAcceptanceFailure.alreadyTaken => 'Hai già affrontato questa missione',
    QuestAcceptanceFailure.titleMismatch =>
      'Il tuo titolo non permette questa missione',
    QuestAcceptanceFailure.notInCity =>
      'Devi trovarti nella città della missione',
    QuestAcceptanceFailure.notAcceptable =>
      'Missione non disponibile, avvisa il locandiere',
    QuestAcceptanceFailure.insufficientPoints => 'Punti canale insufficienti',
    QuestAcceptanceFailure.notFound =>
      'Questa missione non è più sulla bacheca',
    QuestAcceptanceFailure.forbidden =>
      'Questo personaggio non può accettare la missione',
    QuestAcceptanceFailure.travelInProgress =>
      "Sei in viaggio: riprova all'arrivo",
    QuestAcceptanceFailure.connection => 'Connessione assente, riprova',
    QuestAcceptanceFailure.unknown => 'Qualcosa è andato storto, riprova',
    QuestAcceptanceFailure.unauthenticated => null,
  };
  if (description == null) return null;
  return KGNotification(
    title: questAcceptanceNoticeTitle,
    description: description,
  );
}
