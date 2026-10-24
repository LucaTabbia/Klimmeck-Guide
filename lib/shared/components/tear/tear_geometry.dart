class PiecePose {
  const PiecePose({required this.dx, required this.angle});

  static const PiecePose rest = PiecePose(dx: 0, angle: 0);

  final double dx;
  final double angle;
}

/// Pose pure dei due pezzi del foglio strappato (numeri provvisori, D-19):
/// lo stub resta fermo, il body segue il dito e poi esce dallo schermo.
class TearGeometry {
  const TearGeometry({required this.stub, required this.body});

  static const double dragShift = 0.35;
  static const double exitMargin = 0.15;
  static const double maxAngle = -0.04;

  factory TearGeometry.at(
    double progress,
    double width, {
    double exit = 0,
    double? exitDistance,
  }) {
    final dragTravel = progress * dragShift * width;
    final exitTravel = (exitDistance ?? width) * (1 + exitMargin);
    final travel = dragTravel + exit * (exitTravel - dragTravel);
    return TearGeometry(
      stub: PiecePose.rest,
      body: PiecePose(dx: -travel, angle: maxAngle * progress),
    );
  }

  final PiecePose stub;
  final PiecePose body;
}
