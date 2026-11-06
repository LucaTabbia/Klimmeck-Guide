class TravelPreviewFragment {
  /// Campi dell'anteprima condivisi da `GetTravelPreview` e
  /// `GetQuestTravelPreview` (15-CONTEXT D-01): del cibo solo id e nome.
  static const String fields = '''
    distance
    duration
    road {
      coordinates
      distance
    }
    food {
      quantity
      item {
        id
        name
      }
    }
    hpLost
    arrivesAlive
  ''';
}
