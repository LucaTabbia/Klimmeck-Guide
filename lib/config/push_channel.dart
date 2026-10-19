/// Canale Android delle notifiche di gioco (Phase 5 D-03): creato all'avvio e
/// passato a ogni `show`, anche dall'isolate in background.
class PushChannel {
  PushChannel._();

  static const String id = 'klimmeck_events';
  static const String name = 'Eventi di gioco';
  static const String description =
      'Fine viaggio, fine quest e streamer in live';

  /// Drawable bianco su trasparente in `android/app/src/main/res/drawable/`.
  static const String smallIcon = 'ic_stat_klimmeck';
}
