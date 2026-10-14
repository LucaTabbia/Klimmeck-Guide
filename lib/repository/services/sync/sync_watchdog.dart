import 'dart:async';

import 'sync_health.dart';

enum _Condition { healthy, degraded, terminated }

/// Misura il tempo di degrado continuo della sincronizzazione, mai il silenzio:
/// un socket sano e inattivo non emette nulla per ore e non deve far scattare
/// il watchdog. Uno stream terminato dal backend (FORBIDDEN/NOT_FOUND) conta
/// come degrado solo se nessuno stream e' sano, altrimenti l'assenza di retry
/// non produrrebbe un logout spurio. L'orologio e' sospeso in background perche'
/// i timer Dart possono scattare in ritardo al ritorno in foreground; scatta una
/// sola volta (latch) cosi' il teardown della sessione non viene ripetuto.
class SyncWatchdog implements SyncHealth {
  SyncWatchdog({
    required Future<void> Function() onExpired,
    Duration window = defaultWindow,
  }) : _onExpired = onExpired,
       _window = window;

  static const Duration defaultWindow = Duration(minutes: 3);

  final Future<void> Function() _onExpired;
  final Duration _window;
  final Map<SyncSource, _Condition> _conditions = {};
  Timer? _timer;
  bool _isSuspended = false;
  bool _isLatched = false;

  bool get isDegraded =>
      _conditions.containsValue(_Condition.degraded) ||
      (_conditions.containsValue(_Condition.terminated) && !_hasHealthyStream);

  bool get _hasHealthyStream =>
      _conditions[SyncSource.userStream] == _Condition.healthy ||
      _conditions[SyncSource.characterStream] == _Condition.healthy;

  @override
  void markHealthy(SyncSource source) => _set(source, _Condition.healthy);

  @override
  void markDegraded(SyncSource source) => _set(source, _Condition.degraded);

  @override
  void markTerminated(SyncSource source) => _set(source, _Condition.terminated);

  @override
  void release(SyncSource source) {
    _conditions.remove(source);
    _reevaluate();
  }

  @override
  void touch() {
    if (_isLatched || _isSuspended || !isDegraded) return;
    _arm();
  }

  void suspend() {
    if (_isLatched) return;
    _isSuspended = true;
    _cancel();
  }

  void resume() {
    if (_isLatched) return;
    _isSuspended = false;
    if (isDegraded) _arm();
  }

  void dispose() {
    _cancel();
    _isLatched = true;
  }

  void _set(SyncSource source, _Condition condition) {
    _conditions[source] = condition;
    _reevaluate();
  }

  void _reevaluate() {
    if (_isLatched) return;
    if (!isDegraded) {
      _cancel();
      return;
    }
    if (_timer == null && !_isSuspended) _arm();
  }

  void _arm() {
    _cancel();
    _timer = Timer(_window, _expire);
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _expire() {
    _timer = null;
    _isLatched = true;
    unawaited(_onExpired());
  }
}
