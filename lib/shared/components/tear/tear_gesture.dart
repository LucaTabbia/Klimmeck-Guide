/// Modello puro dello strappo (D-06): numeri provvisori, rivisti dall'utente (D-19).
class TearGesture {
  const TearGesture({
    this.travelFraction = 0.45,
    this.flingProgress = 0.35,
    this.flingVelocity = -900,
    this.blockedCap = 0.12,
  });

  /// Frazione della larghezza da trascinare per lo strappo pieno.
  final double travelFraction;
  final double flingProgress;

  /// Velocità orizzontale (px/s, negativa = sinistra) oltre cui un lancio strappa.
  final double flingVelocity;

  /// Massimo avanzamento di un foglio che resiste (swipe bloccato).
  final double blockedCap;

  double progress(double dragDx, double width) =>
      width <= 0 ? 0 : (-dragDx / (width * travelFraction)).clamp(0.0, 1.0);

  bool shouldTear(double progress, double velocityX) =>
      progress >= 1 ||
      (progress >= flingProgress && velocityX <= flingVelocity);

  double resisted(double progress) =>
      progress < blockedCap ? progress : blockedCap;
}

/// Scatta una sola volta per trascinamento (haptic della soglia).
class ThresholdLatch {
  bool _hasFired = false;

  bool cross(bool isReached) {
    if (!isReached || _hasFired) return false;
    _hasFired = true;
    return true;
  }

  void reset() => _hasFired = false;
}
