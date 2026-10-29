class TravelMutations {
  /// Avvia il viaggio libero verso il marker di una città (BE Phase 8): il
  /// viaggio arriva su `characterUpdated`, mai da questa risposta.
  static const String startTravel = r'''
    mutation StartTravel($request: TravelRequest!) {
      startTravel(request: $request) {
        response
        successful
      }
    }''';

  /// Teletrasporto del GM (BE Phase 8 §7): qualsiasi POI, nessuna conferma
  /// (10-CONTEXT D-16); la posizione arriva dalla coda o da `characterUpdated`.
  static const String teleportCharacter = r'''
    mutation TeleportCharacter($request: TravelRequest!) {
      teleportCharacter(request: $request) {
        response
        successful
      }
    }''';
}
