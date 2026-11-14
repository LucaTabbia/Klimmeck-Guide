import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/quest/quest_blocked_reason.dart';
import 'package:klimmeck_guide/models/quest/quest_lane.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/travel/travel_cost_text.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';
import 'package:klimmeck_guide/utils/prison_lines.dart';

const String questAcceptanceNoticeTitle = 'Missione non accettata';
const String questAcceptedNoticeTitle = 'Missione accettata';

/// Story e worldMission non viaggiano: aspettano l'oste (Phase 21, utente
/// 2026-11-14). Nessun banner per le quest che partono verso il marker.
KGNotification? questAwaitingInnkeeperNoticeFor(QuestType? type) {
  if (type == null || laneOf(type) == QuestLane.standard) return null;
  return KGNotification(
    title: questAcceptedNoticeTitle,
    description:
        "L'oste è stato avvisato: la missione comincerà quando la avvia",
  );
}

/// Copy di dominio del banner (D-04), provvisoria (D-19). Nessun banner per
/// UNAUTHENTICATED: il flusso di sessione sta già agendo.
/// [imprisonedFor] è il tempo che manca alla fine della prigione.
KGNotification? questAcceptanceNoticeFor(
  QuestAcceptanceFailure failure, {
  QuestType? type,
  Duration? imprisonedFor,
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
    QuestAcceptanceFailure.awaitingAid =>
      'Sei in attesa di soccorso: non puoi accettare missioni',
    QuestAcceptanceFailure.starving => starvingPhrase,
    QuestAcceptanceFailure.noEffect => questNoEffectLine,
    QuestAcceptanceFailure.imprisoned => prisonReleaseLine(imprisonedFor),
    QuestAcceptanceFailure.missionInProgress => missionInProgressRefusalLine,
    QuestAcceptanceFailure.connection => 'Connessione assente, riprova',
    QuestAcceptanceFailure.timedOut =>
      'Il server non ha risposto in tempo: '
          'controlla la bacheca prima di riprovare',
    QuestAcceptanceFailure.badUserInput ||
    QuestAcceptanceFailure.unknown => 'Qualcosa è andato storto, riprova',
    QuestAcceptanceFailure.unauthenticated => null,
  };
  if (description == null) return null;
  return KGNotification(
    title: questAcceptanceNoticeTitle,
    description: description,
  );
}
