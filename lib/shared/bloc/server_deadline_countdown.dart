import 'dart:async';

import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';

/// Conto alla rovescia verso un istante del server, condiviso dai Cubit che
/// mostrano un «fra …» (ricarica delle pozioni, prigione): il tempo che manca
/// arrotondato per eccesso al minuto, `null` quando l'istante è passato. Il
/// timer gira solo finché manca qualcosa; un nuovo sync dell'orologio
/// ricalcola. Solo visualizzazione: il giudice resta il backend.
class ServerDeadlineCountdown {
  ServerDeadlineCountdown({
    required ServerClockService clock,
    required Duration tick,
    required void Function(Duration? remaining) onRemaining,
  }) : _clock = clock,
       _tick = tick,
       _onRemaining = onRemaining {
    _offsetSubscription = clock.offsetChanges.listen((_) => _refresh());
  }

  final ServerClockService _clock;
  final Duration _tick;
  final void Function(Duration? remaining) _onRemaining;
  late final StreamSubscription<void> _offsetSubscription;
  Timer? _timer;
  DateTime? _until;

  void follow(DateTime? until) {
    _until = until;
    _refresh();
  }

  void _refresh() {
    final left = _until?.difference(_clock.now());
    if (left == null || left <= Duration.zero) {
      _onRemaining(null);
      return _stopTimer();
    }
    final minutes = (left.inMilliseconds / Duration.millisecondsPerMinute)
        .ceil();
    _onRemaining(Duration(minutes: minutes));
    _timer ??= Timer.periodic(_tick, (_) => _refresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() {
    _stopTimer();
    return _offsetSubscription.cancel();
  }
}
