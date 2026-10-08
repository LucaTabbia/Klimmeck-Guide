/// Attesa prima del tentativo [attempt] (0-based): [initial] raddoppiato a ogni
/// tentativo, mai oltre [max]. Nessun jitter: un solo device per sessione.
Duration exponentialBackoff(
  int attempt, {
  Duration initial = const Duration(seconds: 1),
  Duration max = const Duration(seconds: 30),
}) {
  final multiplier = 1 << attempt.clamp(0, _maxShift);
  final delay = initial * multiplier;
  return delay > max ? max : delay;
}

/// Oltre 2^20 il ritardo supera qualunque cap ragionevole: limita lo shift
/// per evitare overflow.
const int _maxShift = 20;
