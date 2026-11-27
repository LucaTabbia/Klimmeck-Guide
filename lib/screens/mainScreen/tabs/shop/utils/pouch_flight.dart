import 'dart:ui';

/// Tragitto della sacchetta di monete dall'angolo del bancone al negoziante:
/// più si avvicina, più rimpicciolisce.
class PouchFlight {
  const PouchFlight({required this.start, required this.target});

  /// Misura della sacchetta tra le mani del negoziante, rispetto a quella a
  /// riposo.
  static const double smallestScale = 0.3;

  /// Parte del tragitto oltre la quale il rilascio consegna la sacchetta.
  static const double deliveryProgress = 0.85;

  final Offset start;
  final Offset target;

  /// Quanto del tragitto è stato percorso, da 0 (a riposo) a 1 (consegnata).
  double progressAt(Offset position) {
    final journey = (target - start).distance;
    if (journey == 0) return 1;
    final remaining = (target - position).distance;
    return (1 - remaining / journey).clamp(0.0, 1.0);
  }

  double scaleAt(Offset position) =>
      1 - progressAt(position) * (1 - smallestScale);

  bool reachesShopkeeper(Offset position) =>
      progressAt(position) >= deliveryProgress;
}
