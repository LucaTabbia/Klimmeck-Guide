/// Messaggistica push (FCM su Android, D-19). Nessun callback "opened" di FCM: per i
/// messaggi data-only non scattano mai, l'unica sorgente di tap è la notifica locale
/// costruita dal FE (05-RESEARCH C3).
abstract interface class PushMessagingPort {
  /// `null` se il token non è (ancora) disponibile; lancia sugli errori transitori.
  Future<String?> token();

  Stream<String> get tokenRefreshes;

  /// Messaggi ricevuti con l'app in foreground (`onMessage`), valori già stringhe.
  Stream<Map<String, String>> get foregroundMessages;
}
