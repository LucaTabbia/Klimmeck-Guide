import 'dart:async';

/// Socket di nuovo connesso dopo una caduta (09-CONTEXT D-09, F11): i risultati
/// senza snapshot si rileggono qui. Non scatta alla prima connessione.
abstract interface class ConnectionRestoredEvents {
  Stream<void> get restored;
}

/// Alimentato da `SessionSyncCubit`, unico osservatore del socket.
class ConnectionRestoredBus implements ConnectionRestoredEvents {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get restored => _controller.stream;

  void notifyRestored() {
    if (_controller.isClosed) return;
    _controller.add(null);
  }

  Future<void> close() => _controller.close();
}
