class PointOfInterestQueries {
  /// Luoghi del mondo per il teletrasporto dell'oste (D-01, D-29): nessun ruolo richiesto dal BE.
  static const String listPointsOfInterest = r'''
    query ListPointsOfInterest {
      pointOfInterests {
        id
        type
        location
        city {
          id
          name
        }
      }
    }
  ''';
}
