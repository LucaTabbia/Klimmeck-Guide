/// Categorie di notifica regolabili in Impostazioni (D-09). `storageKey` è
/// esplicita: rinominare un valore non deve orfanare i dati salvati.
enum NotificationCategory {
  travelEnd('travel_end', 'travelEnd'),
  streamerLive('streamer_live', 'streamerLive'),
  questEnd('quest_end', 'questEnd'),
  questCancelled('quest_cancelled', 'questCancelled');

  const NotificationCategory(this.storageKey, this.wireType);

  /// Valore di ogni categoria finché l'utente non la cambia.
  static const bool defaultEnabled = true;

  final String storageKey;

  /// Valore di `PushEventType` del backend (`data.type`, BE Phase 5): esplicito
  /// come `storageKey`, mai il nome del valore (Phase 5 D-04).
  final String wireType;

  /// Eventi del singolo giocatore (con `id`), contro il broadcast `streamerLive`.
  bool get isPersonal => this != streamerLive;

  /// `null` per tipi sconosciuti (es. il futuro `combatResult`): il chiamante
  /// scarta il messaggio.
  static NotificationCategory? fromWireType(Object? value) {
    for (final category in values) {
      if (category.wireType == value) return category;
    }
    return null;
  }
}
