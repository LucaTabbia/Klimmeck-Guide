/// Tocchi di fila sul negoziante: al decimo, senza pause più lunghe di
/// [maxGap], perde la pazienza e il conto riparte da zero.
class PokeStreak {
  PokeStreak({this.target = 10, this.maxGap = const Duration(seconds: 1)});

  final int target;
  final Duration maxGap;

  int _count = 0;
  DateTime? _lastPoke;

  /// Vero sul tocco che fa sbottare il negoziante.
  bool poke(DateTime now) {
    final last = _lastPoke;
    if (last == null || now.difference(last) > maxGap) _count = 0;
    _count++;
    _lastPoke = now;
    if (_count < target) return false;
    _count = 0;
    _lastPoke = null;
    return true;
  }
}
