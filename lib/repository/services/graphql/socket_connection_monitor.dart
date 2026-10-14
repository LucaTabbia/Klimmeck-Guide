import 'package:graphql_flutter/graphql_flutter.dart';

/// Stato del socket della sessione come `Stream<bool>` (connesso / no) per il
/// watchdog della sync (Phase 3 D-15). Crea il client solo se assente:
/// `connectOrReconnect()` su un client esistente lo dispone e uccide gli
/// stream vivi (Pitfall 5).
class SocketConnectionMonitor {
  SocketConnectionMonitor(this._link);

  final WebSocketLink _link;

  Stream<bool> watch() {
    if (_link.getSocketClient == null) _link.connectOrReconnect();
    return _link.getSocketClient!.connectionState
        .map((state) => state == SocketConnectionState.connected)
        .distinct();
  }
}
