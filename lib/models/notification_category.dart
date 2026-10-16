/// Categorie di notifica regolabili in Impostazioni (D-09). `storageKey` è
/// esplicita: rinominare un valore non deve orfanare i dati salvati.
enum NotificationCategory {
  travelEnd('travel_end'),
  streamerLive('streamer_live'),
  questEnd('quest_end');

  const NotificationCategory(this.storageKey);

  final String storageKey;
}
