import 'dart:math' as math;

import 'package:klimmeck_guide/utils/pour_geometry.dart';

/// Lato verso cui si inclina la boccetta: in senso orario la bocca va a
/// destra, dove sta il personaggio; in senso antiorario a sinistra, dove
/// stanno i compagni (Phase 26 D-09).
enum PourSide { character, companion }

/// Il versamento nel tempo (Phase 26 D-05..D-07): l'inclinazione insegue la
/// mira del dito con una molla, il pelo sciaborda quando la boccetta
/// accelera, la prima goccia impegna il lato e da lì la boccetta si svuota
/// fino in fondo, qualunque cosa faccia il dito.
class PourSimulation {
  PourSimulation({
    required PourGeometry geometry,
    required Set<PourSide> sides,
    this.fill = startFill,
  }) : _geometry = geometry,
       _sides = Set.unmodifiable(sides),
       _height = _heightOf(geometry);

  static const double startFill = 0.55;
  static const double maxTilt = 2.4;

  /// Fin dove si piega la boccetta verso un lato senza bevitori.
  static const double refusedTilt = 0.45;

  static const double _stiffness = 60;
  static final double _damping = 2 * math.sqrt(_stiffness);
  static const double _sloshStiffness = 40;
  static const double _sloshDamping = 3;
  static const double _sloshGain = 0.08;
  static const double _sloshLimit = 0.35;
  static const double _drainBase = 0.12;
  static const double _drainByDepth = 1.2;
  static const double _waveSpeed = 6;

  final PourGeometry _geometry;
  final Set<PourSide> _sides;
  final double _height;

  double angle = 0;
  double fill;

  /// Inclinazione in più del pelo mentre sciaborda (radianti).
  double slosh = 0;

  /// Fase dell'onda sul pelo.
  double wavePhase = 0;

  PourSide? committedSide;

  double _aim = 0;
  double _angularVelocity = 0;
  double _sloshVelocity = 0;

  bool get isEmpty => fill <= 0;

  LiquidLevel get level => _geometry.levelOf(angle: angle, fill: fill);

  /// Dove il dito vuole la boccetta; dopo la prima goccia non conta più.
  void aim(double target) {
    if (committedSide != null) return;
    _aim = _allowed(target.clamp(-maxTilt, maxTilt));
  }

  double _allowed(double target) {
    final side = _sideOf(target);
    if (side == null || _sides.contains(side)) return target;
    return target.sign * math.min(target.abs(), refusedTilt);
  }

  /// Un passo di simulazione; restituisce il lato impegnato a questo passo.
  PourSide? step(Duration elapsed) {
    final dt = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final acceleration =
        (_aim - angle) * _stiffness - _angularVelocity * _damping;
    _angularVelocity += acceleration * dt;
    angle += _angularVelocity * dt;
    _stepSlosh(acceleration, dt);
    wavePhase += _waveSpeed * dt;
    if (isEmpty) return null;
    final current = level;
    final committedNow = _commitIfSpilling(current);
    if (committedSide != null) _drain(current, dt);
    return committedNow;
  }

  void _stepSlosh(double acceleration, double dt) {
    _sloshVelocity +=
        (-slosh * _sloshStiffness -
            _sloshVelocity * _sloshDamping -
            acceleration * _sloshGain) *
        dt;
    slosh = (slosh + _sloshVelocity * dt).clamp(-_sloshLimit, _sloshLimit);
  }

  PourSide? _commitIfSpilling(LiquidLevel current) {
    if (committedSide != null || !current.isSpilling) return null;
    final side = _sideOf(angle);
    if (side == null) return null;
    committedSide = side;
    _aim = angle.sign * maxTilt;
    return side;
  }

  void _drain(LiquidLevel current, double dt) {
    final depth = current.isSpilling
        ? (current.mouth.dy - current.surfaceY) / _height
        : 0.0;
    fill = math.max(0, fill - (_drainBase + _drainByDepth * depth) * dt);
  }

  static PourSide? _sideOf(double angle) {
    if (angle > 0) return PourSide.character;
    if (angle < 0) return PourSide.companion;
    return null;
  }

  static double _heightOf(PourGeometry geometry) {
    final ys = geometry.interior.map((point) => point.dy);
    return ys.reduce(math.max) - ys.reduce(math.min);
  }
}
