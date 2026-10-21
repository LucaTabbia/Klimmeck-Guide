import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tear_clipper.dart';
import 'tear_geometry.dart';
import 'tear_gesture.dart';

/// Foglio che si strappa con uno swipe a sinistra (D-01/D-06): GestureDetector
/// orizzontale (non un widget di dismissal), due metà ritagliate dallo stesso child.
class TearablePaper extends StatefulWidget {
  const TearablePaper({
    super.key,
    required this.child,
    required this.onTorn,
    this.canTear = true,
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
  final TearGesture gesture;
  final String semanticLabel;

  @override
  State<TearablePaper> createState() => TearablePaperState();
}

class TearablePaperState extends State<TearablePaper>
    with SingleTickerProviderStateMixin {
  static const Duration _commitDuration = Duration(milliseconds: 160);
  static const double _restEpsilon = 0.001;
  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.6,
  );

  late final AnimationController _controller = AnimationController(vsync: this);
  final ThresholdLatch _thresholdLatch = ThresholdLatch();
  final ThresholdLatch _resistLatch = ThresholdLatch();
  double _dragDx = 0;
  double _width = 0;
  bool _isTorn = false;

  bool get isTorn => _isTorn;

  /// Rollback (D-03): le due metà si ricompongono.
  void recompose() {
    if (!mounted) return;
    _isTorn = false;
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
    _springBack(_width <= 0 ? 0 : -velocity / _width);
  }

  Future<void> _commitTear() async {
    _isTorn = true;
    await _controller.animateTo(1, duration: _commitDuration);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    widget.onTorn();
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
    super.dispose();
  }

  Widget _half(TearSide side, HalfPose pose) => Transform.translate(
    offset: Offset(pose.dx, 0),
    child: Transform.rotate(
      angle: pose.angle,
      child: ClipPath(
        clipper: TearClipper(side: side),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    ),
  );

  Widget _halves(double progress) {
    final pose = TearGeometry.at(progress, _width);
    return RepaintBoundary(
      child: Stack(
        children: [
          _half(TearSide.left, pose.left),
          _half(TearSide.right, pose.right),
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
              animation: _controller,
              builder: (context, _) => _controller.value == 0
                  ? RepaintBoundary(child: widget.child)
                  : _halves(_controller.value),
            ),
          ),
        );
      },
    );
  }
}
