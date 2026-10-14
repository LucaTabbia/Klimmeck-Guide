/// Sorgenti il cui stato di salute alimenta il watchdog di sincronizzazione.
enum SyncSource { socket, userStream, characterStream }

/// Contratto con cui socket e stream segnalano la propria salute, senza
/// conoscere la policy che decide quando la sincronizzazione e' persa.
abstract interface class SyncHealth {
  /// Sorgente viva: connessione stabilita, evento o snapshot ricevuto.
  void markHealthy(SyncSource source);

  /// Sorgente in recupero (socket giu', stream fallito/chiuso in re-iscrizione).
  void markDegraded(SyncSource source);

  /// Stream rifiutato dal backend (FORBIDDEN/NOT_FOUND): nessun retry.
  void markTerminated(SyncSource source);

  /// Il proprietario della sorgente e' stato chiuso (shell ri-chiavata, logout).
  void release(SyncSource source);

  /// Un refetch HTTP e' riuscito: prova di vita, riapre la finestra se degradato.
  void touch();
}
