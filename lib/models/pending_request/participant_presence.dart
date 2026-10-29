import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';

/// Stato di un partecipante della coda sull'ora del server (10-CONTEXT D-06/D-08, C6).
sealed class ParticipantPresence extends Equatable {
  const ParticipantPresence();

  /// Un viaggio in corso (o illeggibile, C4) tiene «Completa» disabilitato.
  bool get blocksCompletion => false;

  @override
  List<Object?> get props => [];
}

final class ParticipantPresent extends ParticipantPresence {
  const ParticipantPresent();
}

final class ParticipantTravelling extends ParticipantPresence {
  const ParticipantTravelling({required this.remaining});

  final Duration remaining;

  @override
  bool get blocksCompletion => true;

  @override
  List<Object?> get props => [remaining];
}

final class ParticipantTravellingUnknown extends ParticipantPresence {
  const ParticipantTravellingUnknown();

  @override
  bool get blocksCompletion => true;
}

final class ParticipantArrived extends ParticipantPresence {
  const ParticipantArrived();
}

final class ParticipantAwaitingAid extends ParticipantPresence {
  const ParticipantAwaitingAid();
}

ParticipantPresence presenceOf(
  PendingRequestCharacter character,
  DateTime serverNow,
) {
  if (character.awaitingAid != null) return const ParticipantAwaitingAid();
  if (character.hasUnreadableTravel) {
    return const ParticipantTravellingUnknown();
  }
  final travel = character.travel;
  if (travel == null) return const ParticipantPresent();
  if (!serverNow.isBefore(travel.endTime)) return const ParticipantArrived();
  return ParticipantTravelling(remaining: travel.endTime.difference(serverNow));
}
