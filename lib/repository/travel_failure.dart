import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_imprisoned.dart';
import 'package:klimmeck_guide/repository/mission_in_progress.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String travelInProgressCode = 'TRAVEL_IN_PROGRESS';
const String travelSameLocationCode = 'TRAVEL_SAME_LOCATION';
const String travelDestinationNotAllowedCode = 'TRAVEL_DESTINATION_NOT_ALLOWED';
const String travelNoPathCode = 'TRAVEL_NO_PATH';
const String questInProgressCode = 'QUEST_IN_PROGRESS';
const String awaitingAidCode = 'AWAITING_AID';
const String travelStarvingCode = 'TRAVEL_STARVING';

/// Esiti di dominio del rifiuto di `travelPreview`/`startTravel` (BE Phase 8 §2);
/// la UI li traduce in copy (07-CONTEXT D-14).
enum TravelFailure {
  inProgress,
  sameLocation,

  /// Difetto di dati (meta non città): solo banner, il BE logga un WARN per il GM.
  destinationNotAllowed,

  /// Difetto di dati stradali: solo banner, il BE logga un WARN per il GM.
  noPath,
  questInProgress,

  /// BE Phase 9 §2: il personaggio è ferito in attesa di soccorso (D-16).
  awaitingAid,

  /// BE Phase 14 D-11: il personaggio non arriverebbe vivo (cibo
  /// insufficiente); stesso codice su `startTravel` e `acceptQuest`.
  starving,

  /// Il personaggio è in prigione (quick 261110-cgd): la fine viaggia
  /// sull'eccezione.
  imprisoned,

  /// Missione in corso (BE Phase 22, D-11/D-12): il personaggio aspetta l'esito.
  missionInProgress,
  notFound,
  forbidden,

  /// BAD_USER_INPUT (BE Phase 10): richiesta rifiutata dalla validazione del
  /// server (Phase 12 D-13a).
  badUserInput,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout client: la richiesta non è annullata,
  /// un viaggio partito comunque arriva via `characterUpdated`.
  timedOut,

  /// `startTravel` ha risposto `successful: false` senza codice: un rifiuto del
  /// BE, distinto da una risposta malformata (`unknown`).
  declined,
  unknown,
}

class TravelException implements Exception {
  const TravelException(this.failure, {this.imprisonedUntil});

  final TravelFailure failure;

  /// Fine della prigione detta dal server, solo per [TravelFailure.imprisoned].
  final DateTime? imprisonedUntil;

  @override
  String toString() => 'TravelException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
TravelFailure travelFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return TravelFailure.connection;
  }
  return switch (code) {
    travelInProgressCode => TravelFailure.inProgress,
    travelSameLocationCode => TravelFailure.sameLocation,
    travelDestinationNotAllowedCode => TravelFailure.destinationNotAllowed,
    travelNoPathCode => TravelFailure.noPath,
    questInProgressCode => TravelFailure.questInProgress,
    awaitingAidCode => TravelFailure.awaitingAid,
    travelStarvingCode => TravelFailure.starving,
    characterImprisonedCode => TravelFailure.imprisoned,
    missionInProgressCode => TravelFailure.missionInProgress,
    notFoundCode => TravelFailure.notFound,
    forbiddenCode => TravelFailure.forbidden,
    badUserInputCode => TravelFailure.badUserInput,
    unauthenticatedCode => TravelFailure.unauthenticated,
    _ => TravelFailure.unknown,
  };
}

/// Il rifiuto con la fine della prigione quando il personaggio è in prigione.
TravelException travelExceptionFrom(OperationException exception) =>
    TravelException(
      travelFailureFrom(exception),
      imprisonedUntil: imprisonedUntilFrom(exception),
    );
