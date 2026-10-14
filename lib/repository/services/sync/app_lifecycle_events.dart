import 'dart:async';

/// Transizioni background/foreground dell'app come eventi, senza dipendere da
/// Flutter. Alimentato da un unico `AppLifecycleListener` a livello app con
/// `onPause`/`onRestart`, la vera coppia background-foreground: `onResume`
/// scatta anche per gli stati `inactive` transitori (tendina notifiche) e non
/// va usato. I consumatori sono i cubit di sessione e personaggio.
abstract interface class AppLifecycleEvents {
  Stream<void> get backgrounded;
  Stream<void> get foregrounded;
}

class AppLifecycleEventBus implements AppLifecycleEvents {
  final StreamController<void> _backgrounded =
      StreamController<void>.broadcast();
  final StreamController<void> _foregrounded =
      StreamController<void>.broadcast();

  @override
  Stream<void> get backgrounded => _backgrounded.stream;

  @override
  Stream<void> get foregrounded => _foregrounded.stream;

  void notifyBackgrounded() {
    if (_backgrounded.isClosed) return;
    _backgrounded.add(null);
  }

  void notifyForegrounded() {
    if (_foregrounded.isClosed) return;
    _foregrounded.add(null);
  }

  Future<void> close() =>
      Future.wait([_backgrounded.close(), _foregrounded.close()]);
}
