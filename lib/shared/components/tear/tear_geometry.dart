class HalfPose {
  const HalfPose({required this.dx, required this.angle});

  final double dx;
  final double angle;
}

/// Pose pure delle due metà del foglio strappato (numeri provvisori, D-19).
class TearGeometry {
  const TearGeometry({required this.left, required this.right});

  factory TearGeometry.at(double progress, double width) => TearGeometry(
    left: HalfPose(dx: -progress * width * 0.35, angle: -0.06 * progress),
    right: HalfPose(dx: progress * width * 0.15, angle: 0.04 * progress),
  );

  final HalfPose left;
  final HalfPose right;
}
