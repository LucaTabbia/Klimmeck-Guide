import 'dart:async';

import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';

/// Ora del server scriptata per i test di cubit e mappa.
class FakeServerClockService implements ServerClockService {
  FakeServerClockService(this.current, {this.isSynced = true});

  DateTime current;
  int syncCalls = 0;
  final StreamController<void> _offsetChanges =
      StreamController<void>.broadcast();

  @override
  bool isSynced;

  void advance(Duration delta) => current = current.add(delta);

  /// Simula un sync riuscito che corregge l'offset (es. dopo un cambio d'orologio).
  void resync(DateTime serverNow) {
    current = serverNow;
    isSynced = true;
    _offsetChanges.add(null);
  }

  @override
  DateTime now() => current;

  @override
  Stream<void> get offsetChanges => _offsetChanges.stream;

  @override
  Future<void> sync() async => syncCalls++;

  @override
  Future<void> dispose() => _offsetChanges.close();
}
