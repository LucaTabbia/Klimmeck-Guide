import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tear_clipper.dart';
import 'tear_geometry.dart';
import 'tear_gesture.dart';

/// Foglio che si strappa con uno swipe a sinistra (D-01/D-06): GestureDetector
/// orizzontale (non un widget di dismissal), due pezzi ritagliati dallo stesso child.
/// Strappo orizzontale al 10% in alto: lo stub resta, il body scivola a sinistra
/// fuori schermo (D-06 emendata 2026-10-22).
class TearablePaper extends StatefulWidget {
  const TearablePaper({
    super.key,
    required this.child,
    required this.onTorn,
    this.canTear = true,
    this.tearSeed = 0,
    this.isEnabled = true,
    this.gesture = const TearGesture(),
    this.semanticLabel = 'Strappa il foglio verso sinistra per accettare',
  });

  final Widget child;
  final VoidCallback onTorn;

  /// false = il foglio resiste e torna intero (quest non accettabile, D-11).
  final bool canTear;

  /// false = ignora ogni trascinamento (mutation in volo).
  final bool isEnabled;

  /// Seme del bordo frastagliato (es. TearClipper.seedOf(questId)).
  final int tearSeed;
  final TearGesture gesture;
  final String semanticLabel;

  static const Key stubKey = ValueKey('tear-stub');
  static const Key bodyKey = ValueKey('tear-body');

  @override
  State<TearablePaper> createState() => TearablePaperState();
}

class TearablePaperState extends State<TearablePaper>
    with TickerProviderStateMixin {
  static const Duration _commitDuration = Duration(milliseconds: 160);
  static const Duration _exitDuration = Duration(milliseconds: 380);
  static const Duration _returnDuration = Duration(milliseconds: 240);
  static const double _restEpsilon = 0.001;
  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.6,
  );

  late final AnimationController _controller = AnimationController(vsync: this);
  late final AnimationController _exitController = AnimationController(
    vsync: this,
  );
  final ThresholdLatch _thresholdLatch = ThresholdLatch();
  final ThresholdLatch _resistLatch = ThresholdLatch();
  double _dragDx = 0;
  double _width = 0;
  double _exitDistance = 0;
  bool _isTorn = false;

  bool get isTorn => _isTorn;

  /// Rollback (D-03): il body torna e il foglio si ricompone.
  void recompose() {
    if (!mounted) return;
    _isTorn = false;
    _exitController.animateTo(
      0,
      duration: _returnDuration,
      curve: Curves.easeOut,
    );
    _springBack(0);
  }

  bool get _ignoresDrag => !widget.isEnabled || _isTorn;

  void _onDragStart(DragStartDetails details) {
    if (_ignoresDrag) return;
    _controller.stop();
    _dragDx = 0;
    _thresholdLatch.reset();
    _resistLatch.reset();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_ignoresDrag) return;
    _dragDx += details.delta.dx;
    final raw = widget.gesture.progress(_dragDx, _width);
    if (!widget.canTear) {
      final value = widget.gesture.resisted(raw);
      if (_resistLatch.cross(value >= widget.gesture.blockedCap)) {
        HapticFeedback.lightImpact();
      }
      _controller.value = value;
      return;
    }
    if (_thresholdLatch.cross(raw >= 1)) HapticFeedback.selectionClick();
    _controller.value = raw;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_ignoresDrag) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (widget.canTear &&
        widget.gesture.shouldTear(_controller.value, velocity)) {
      _commitTear();
      return;
    }
    // Segno invertito: la velocità è negativa verso sinistra, il progresso cresce a sinistra.
    // Un foglio che resiste (D-11) riparte dal cap senza slancio: niente overshoot.
    final keepsMomentum = widget.canTear && _width > 0;
    _springBack(keepsMomentum ? -velocity / _width : 0);
  }

  Future<void> _commitTear() async {
    final box = context.findRenderObject() as RenderBox?;
    _exitDistance = box == null
        ? _width
        : math.max(_width, box.localToGlobal(Offset(box.size.width, 0)).dx);
    _isTorn = true;
    await _controller.animateTo(1, duration: _commitDuration);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    widget.onTorn();
    _exitController.animateTo(1, duration: _exitDuration, curve: Curves.easeIn);
  }

  void _springBack(double velocity) {
    _controller
        .animateWith(SpringSimulation(_spring, _controller.value, 0, velocity))
        .whenComplete(_snapToRest);
  }

  /// La molla si ferma entro tolleranza: azzera il residuo per tornare al child intero.
  void _snapToRest() {
    if (!mounted || _controller.isAnimating || _isTorn) return;
    if (_controller.value < _restEpsilon) _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Widget _piece(TearPiece piece, PiecePose pose, Key key) =>
      Transform.translate(
        offset: Offset(pose.dx, 0),
        child: Transform.rotate(
          angle: pose.angle,
          child: ClipPath(
            key: key,
            clipper: TearClipper(piece: piece, seed: widget.tearSeed),
            clipBehavior: Clip.antiAlias,
            child: widget.child,
          ),
        ),
      );

  Widget _pieces(double progress, double exit) {
    final pose = TearGeometry.at(
      progress,
      _width,
      exit: exit,
      exitDistance: _exitDistance,
    );
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _piece(TearPiece.stub, pose.stub, TearablePaper.stubKey),
          _piece(TearPiece.body, pose.body, TearablePaper.bodyKey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return Semantics(
          label: widget.semanticLabel,
          child: GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _exitController]),
              builder: (context, _) =>
                  _controller.value == 0 && _exitController.value == 0
                  ? RepaintBoundary(child: widget.child)
                  : _pieces(_controller.value, _exitController.value),
            ),
          ),
        );
      },
    );
  }
}
