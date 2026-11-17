import 'quest_availability.dart';

/// Copy fissata dall'utente (D-20): riga del foglio e banner del rifiuto.
const String questNoEffectLine = 'Il tempio non può fare nulla per te adesso';

/// Copy dell'orchestratore (quick 261113-aql, IN-03): la quest da cui è nato
/// un soccorso aperto; vale per ogni chiusura del soccorso.
const String questAwaitingRescueLine =
    'Soccorso in corso: la missione riapre quando il soccorso si conclude.';

/// Copy provvisoria della prigione (quick 261110-cgd): riga del foglio e dei
/// banner, completata dal tempo che manca dove è noto.
const String questImprisonedLine = 'Sei in prigione';

/// Copy D-30: riga della Bacheca durante ogni missione in corso (D-13).
const String questMissionInProgressLine = "Missione in corso: aspetta l'esito";

/// Riga di rifiuto mostrata al giocatore: testo di dominio fisso, mai testo del
/// server (copy provvisoria, D-19). Il titolo che serve non è mai scritto: lo
/// dice il badge sul foglio.
String? questBlockedReasonOf(QuestAvailability availability) =>
    switch (availability) {
      QuestAvailability.available => null,
      QuestAvailability.tornForOwner => 'Missione già accettata',
      QuestAvailability.notAcceptable => 'Missione non disponibile',
      QuestAvailability.alreadyDone => 'Hai già affrontato questa missione',
      QuestAvailability.titleMismatch =>
        'Il tuo titolo non permette questa missione',
      QuestAvailability.laneBusy =>
        'Hai già una missione di questo tipo in corso',
      QuestAvailability.full => 'Non ci sono più posti per il tuo rango',
      QuestAvailability.notInCity => 'Devi trovarti nella città della missione',
      QuestAvailability.insufficientPoints => 'Punti canale insufficienti',
      QuestAvailability.noEffect => questNoEffectLine,
      QuestAvailability.imprisoned => questImprisonedLine,
      QuestAvailability.awaitingRescue => questAwaitingRescueLine,
      QuestAvailability.missionInProgress => questMissionInProgressLine,
    };
