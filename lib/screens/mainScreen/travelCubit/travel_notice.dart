import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';

const String travelNoticeTitle = 'Viaggio non partito';

/// Copy di dominio del banner (D-14), provvisoria (no UI phase). Nessun banner
/// per UNAUTHENTICATED: il flusso di sessione sta già agendo.
KGNotification? travelNoticeFor(TravelFailure failure) {
  final description = switch (failure) {
    TravelFailure.inProgress => 'Sei già in viaggio',
    TravelFailure.sameLocation => 'Sei già in questa città',
    TravelFailure.destinationNotAllowed =>
      'Puoi viaggiare solo verso una città',
    TravelFailure.noPath => 'Nessuna strada porta a questa meta',
    TravelFailure.questInProgress =>
      'Non puoi partire durante una missione in corso',
    TravelFailure.awaitingAid => 'Sei in attesa di soccorso: non puoi partire',
    TravelFailure.notFound => 'Questa meta non è più raggiungibile',
    TravelFailure.forbidden => 'Questo personaggio non può partire',
    TravelFailure.connection => 'Connessione assente, riprova',
    TravelFailure.timedOut =>
      'Il server non ha risposto in tempo: '
          'controlla la mappa prima di riprovare',
    TravelFailure.declined => 'Il server ha rifiutato la partenza, riprova',
    TravelFailure.unknown => 'Qualcosa è andato storto, riprova',
    TravelFailure.unauthenticated => null,
  };
  if (description == null) return null;
  return KGNotification(title: travelNoticeTitle, description: description);
}
