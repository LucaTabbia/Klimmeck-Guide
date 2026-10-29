import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

/// Stato minimo di una riga (10-CONTEXT D-08), copy provvisoria (D-22).
String presenceLabelOf(ParticipantPresence presence) => switch (presence) {
  ParticipantPresent() => 'Presente',
  ParticipantTravelling(:final remaining) =>
    'In viaggio · ${formatGameDuration(remaining)}',
  ParticipantTravellingUnknown() => 'In viaggio',
  ParticipantArrived() => 'Arrivato',
  ParticipantAwaitingAid() => 'In attesa di soccorso',
};
