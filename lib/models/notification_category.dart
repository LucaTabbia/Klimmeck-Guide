/// Categorie di notifica regolabili in Impostazioni (D-09). `storageKey` è
/// esplicita: rinominare un valore non deve orfanare i dati salvati.
/// `ambush` (Phase 22 D-14, D-30): ogni imboscata, vinta o persa; accetta anche
/// il vecchio `ambushDefeat`; `storageKey` invariata così la scelta salvata resta.
/// `prisonRelease` (quick 261110-prp): fine della prigionia, titolo e testo dal BE.
/// `missionStart` (Phase 21): l'oste avvia la story o la worldMission in coda,
/// titolo e testo dal BE.
/// `petRecovered` (Phase 22 D-11): un compagno sconfitto è di nuovo in forze,
/// titolo e testo dal BE.
/// `questEnd` accetta anche `spellResearchSucceeded` e `spellResearchFailed`
/// (Phase 23 D-29, D-31): portano l'id di un foglio esiti e si aprono come una
/// fine quest.
enum NotificationCategory {
  travelEnd('travel_end', 'travelEnd'),
  streamerLive('streamer_live', 'streamerLive'),
  questEnd(
    'quest_end',
    'questEnd',
    alsoAcceptedWireTypes: {'spellResearchSucceeded', 'spellResearchFailed'},
  ),
  questCancelled('quest_cancelled', 'questCancelled'),
  ambush('ambush_defeat', 'ambush', alsoAcceptedWireTypes: {'ambushDefeat'}),
  prisonRelease('prison_release', 'prisonRelease'),
  missionStart('mission_start', 'missionStart'),
  petRecovered('pet_recovered', 'petRecovered');

  const NotificationCategory(
    this.storageKey,
    this.wireType, {
    this.alsoAcceptedWireTypes = const {},
  });

  /// Valore di ogni categoria finché l'utente non la cambia.
  static const bool defaultEnabled = true;

  final String storageKey;

  /// Valore di `PushEventType` del backend (`data.type`, BE Phase 5): esplicito
  /// come `storageKey`, mai il nome del valore (Phase 5 D-04).
  final String wireType;

  /// Altri valori di `PushEventType` accettati per questa categoria: nomi
  /// vecchi (`ambushDefeat`) o eventi che si comportano allo stesso modo.
  final Set<String> alsoAcceptedWireTypes;

  /// Eventi del singolo giocatore (con `id`), contro il broadcast `streamerLive`.
  bool get isPersonal => this != streamerLive;

  /// `null` per tipi sconosciuti: il chiamante scarta il messaggio.
  static NotificationCategory? fromWireType(Object? value) {
    for (final category in values) {
      if (category.wireType == value ||
          category.alsoAcceptedWireTypes.contains(value)) {
        return category;
      }
    }
    return null;
  }
}
