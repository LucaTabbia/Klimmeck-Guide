import 'dart:async';

/// Ora del server stimata per l'interpolazione del viaggio (07-CONTEXT D-07,
/// handoff BE §5): `now()` = ora del device + offset da `serverTime`, misurato
/// alla creazione e a ogni ritorno in foreground, compensando metà del round
/// trip. Silenzioso: un errore o un timeout tengono l'ultimo offset, mai un
/// loading né un'eccezione (CLAUDE.md regola 2). Prima del primo sync l'offset
/// è zero per i pochi istanti del cold start; il tick successivo corregge.
class ServerClockService {
  ServerClockService({
    required Future<DateTime> Function() fetchServerTime,
    required Stream<void> foregrounded,
    DateTime Function() now = DateTime.now,
    Duration timeout = defaultTimeout,
  }) : _fetchServerTime = fetchServerTime,
       _deviceNow = now,
       _timeout = timeout {
    _foregroundSubscription = foregrounded.listen((_) => unawaited(sync()));
  }

  static const Duration defaultTimeout = Duration(seconds: 10);

  final Future<DateTime> Function() _fetchServerTime;
  final DateTime Function() _deviceNow;
  final Duration _timeout;
  late final StreamSubscription<void> _foregroundSubscription;
  final StreamController<void> _offsetChanges =
      StreamController<void>.broadcast();
  Future<void>? _inFlight;
  Duration _offset = Duration.zero;
  bool _isSynced = false;

  DateTime now() => _deviceNow().add(_offset);

  bool get isSynced => _isSynced;

  /// Un evento dopo ogni sync riuscito: chi ha calcolato qualcosa con l'offset
  /// precedente (o prima del primo sync) ricalcola (es. la pedina in viaggio).
  Stream<void> get offsetChanges => _offsetChanges.stream;

  Future<void> sync() =>
      _inFlight ??= _measure().whenComplete(() => _inFlight = null);

  Future<void> _measure() async {
    final sentAt = _deviceNow();
    try {
      final serverNow = await _fetchServerTime().timeout(_timeout);
      final receivedAt = _deviceNow();
      final midpoint = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
      _offset = serverNow.difference(midpoint);
      _isSynced = true;
      if (!_offsetChanges.isClosed) _offsetChanges.add(null);
    } on Object {
      // Offset precedente: il prossimo resume riprova.
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription.cancel();
    await _offsetChanges.close();
  }
}
