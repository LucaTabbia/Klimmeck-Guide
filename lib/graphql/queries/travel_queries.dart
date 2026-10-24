class TravelQueries {
  /// Anteprima del viaggio libero verso il marker di una città: distanza,
  /// durata e rotta, nessuna scrittura (BE Phase 8 §4).
  static const String getTravelPreview = r'''
    query GetTravelPreview($request: TravelRequest!) {
      travelPreview(request: $request) {
        distance
        duration
        road {
          coordinates
          distance
        }
      }
    }''';
}
