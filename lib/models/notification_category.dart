/// Categorie di notifica regolabili in Impostazioni (D-09). `storageKey` è
/// esplicita: rinominare un valore non deve orfanare i dati salvati.
/// `ambush` (Phase 22 D-14, D-30): ogni imboscata, vinta o persa; accetta anche
/// il vecchio `ambushDefeat`; `storageKey` invariata così la scelta salvata resta.
/// `prisonRelease` (quick 261110-prp): fine della prigionia, titolo e testo dal BE.
/// `missionStart` (Phase 21): l'oste avvia la story o la worldMission in coda,
/// titolo e testo dal BE.
/// `petRecovered` (Phase 22 D-11): un compagno sconfitto è di nuovo in forze,
/// titolo e testo dal BE.
enum NotificationCategory {
  travelEnd('travel_end', 'travelEnd'),
  streamerLive('streamer_live', 'streamerLive'),
  questEnd('quest_end', 'questEnd'),
  questCancelled('quest_cancelled', 'questCancelled'),
  ambush('ambush_defeat', 'ambush', legacyWireTypes: {'ambushDefeat'}),
  prisonRelease('prison_release', 'prisonRelease'),
  missionStart('mission_start', 'missionStart'),
  petRecovered('pet_recovered', 'petRecovered');

  const NotificationCategory(
    this.storageKey,
    this.wireType, {
    this.legacyWireTypes = const {},
  });

  /// Valore di ogni categoria finché l'utente non la cambia.
  static const bool defaultEnabled = true;

  final String storageKey;

  /// Valore di `PushEventType` del backend (`data.type`, BE Phase 5): esplicito
  /// come `storageKey`, mai il nome del valore (Phase 5 D-04).
  final String wireType;

  /// Vecchi valori di `PushEventType` ancora accettati per questa categoria.
  final Set<String> legacyWireTypes;

  /// Eventi del singolo giocatore (con `id`), contro il broadcast `streamerLive`.
  bool get isPersonal => this != streamerLive;

  /// `null` per tipi sconosciuti: il chiamante scarta il messaggio.
  static NotificationCategory? fromWireType(Object? value) {
    for (final category in values) {
      if (category.wireType == value ||
          category.legacyWireTypes.contains(value)) {
        return category;
      }
    }
    return null;
  }
}
