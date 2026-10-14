import 'backoff.dart';

/// Tentativi massimi: con backoff 1 -> 60 s coprono circa 2 minuti, dentro la
/// finestra di 3 minuti del watchdog.
const int defaultSilentRetryAttempts = 8;

bool _alwaysRetry(Object error) => true;

/// Riprova [attempt] in silenzio (D-14): i fallimenti transitori non devono
/// mai comparire all'utente. Il numero di tentativi e' limitato e il ritardo ha
/// un tetto, cosi' una sincronizzazione che non si riprende viene chiusa dal
/// watchdog e non da un loop infinito (anti-pattern di graphql.md).
/// [isCancelled] e' verificato prima di ogni tentativo e dopo ogni attesa;
/// la cancellazione non invoca [onGiveUp]. Restituisce `null` se rinuncia.
Future<T?> silentRetry<T>(
  Future<T> Function() attempt, {
  required bool Function() isCancelled,
  bool Function(Object error) shouldRetry = _alwaysRetry,
  void Function(Object error)? onGiveUp,
  int maxAttempts = defaultSilentRetryAttempts,
  Duration maxDelay = const Duration(seconds: 60),
}) async {
  for (var n = 0; n < maxAttempts; n++) {
    if (isCancelled()) return null;
    try {
      return await attempt();
    } catch (error) {
      final isLastAttempt = n == maxAttempts - 1;
      if (!shouldRetry(error) || isLastAttempt) {
        if (!isCancelled()) onGiveUp?.call(error);
        return null;
      }
      await Future<void>.delayed(exponentialBackoff(n, max: maxDelay));
    }
  }
  return null;
}
