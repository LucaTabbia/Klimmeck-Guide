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
}
