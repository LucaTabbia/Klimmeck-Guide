import 'dart:math' as math;

import 'package:flutter/material.dart';

class RadialMenu extends StatefulWidget {
  final double radius;
  final double itemSize;
  final Duration animationDuration;
  final Curve animationCurve;

  final int currentPage;
  final Function(int) onItemTap;

  const RadialMenu({
    super.key,
    required this.currentPage,
    this.radius = 100.0,
    required this.onItemTap,
    this.itemSize = 50.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutBack,
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _spinController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _spinAnimation;
  bool _isOpen = false;
  double _currentRotation = 0.0;
  double _lastPanAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: widget.animationDuration, vsync: this);

    _spinController = AnimationController(duration: Duration(seconds: 2), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: widget.animationCurve));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart));

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));

    _spinAnimation.addListener(() {
      setState(() {
        _currentRotation = _spinAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _selectItem(int index) {
    widget.onItemTap(index);
    _toggleMenu();
  }

  double _getAngleFromOffset(Offset offset, Offset center) {
    final dx = offset.dx - center.dx;
    final dy = offset.dy - center.dy;
    return math.atan2(dy, dx);
  }

  void _handlePanStart(DragStartDetails details, Offset center) {
    if (!_isOpen) return;
    _spinController.stop();
    _lastPanAngle = _getAngleFromOffset(details.localPosition, center);
  }

  void _handlePanUpdate(DragUpdateDetails details, Offset center) {
    if (!_isOpen) return;

    final currentAngle = _getAngleFromOffset(details.localPosition, center);
    final deltaAngle = currentAngle - _lastPanAngle;

    // Handle angle wrapping around 2π
    double adjustedDelta = deltaAngle;
    if (deltaAngle > math.pi) {
      adjustedDelta = deltaAngle - 2 * math.pi;
    } else if (deltaAngle < -math.pi) {
      adjustedDelta = deltaAngle + 2 * math.pi;
    }

    setState(() {
      _currentRotation += adjustedDelta;
    });

    _lastPanAngle = currentAngle;
  }

  void _handlePanEnd(DragEndDetails details, Offset center) {
    if (!_isOpen) return;

    // Calculate velocity for momentum spinning
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    if (speed > 100) {
      // Determine spin direction based on velocity
      final velocityAngle = math.atan2(velocity.dy, velocity.dx);
      final centerOffset = center;
      final directionToCenter = math.atan2(-centerOffset.dy, -centerOffset.dx);
      final crossProduct = math.sin(velocityAngle - directionToCenter);

      // Calculate momentum spin
      final spinAmount = (speed / 1000) * (crossProduct > 0 ? 1 : -1);
      final targetRotation = _currentRotation + spinAmount;

      _spinAnimation = Tween<double>(
        begin: _currentRotation,
        end: targetRotation,
      ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));

      _spinController.reset();
      _spinController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset((widget.radius + widget.itemSize), (widget.radius + widget.itemSize));

    return GestureDetector(
      onPanStart: (details) => _handlePanStart(details, center),
      onPanUpdate: (details) => _handlePanUpdate(details, center),
      onPanEnd: (details) => _handlePanEnd(details, center),
      child: SizedBox(
        width: (widget.radius + widget.itemSize) * 2,
        height: (widget.radius + widget.itemSize) * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _currentRotation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildRadialItem('assets/images/menuMap.png', 'assets/images/menuMap.png', 0),
                  _buildRadialItem('assets/images/mirror.png', 'assets/images/mirror.png', 1),
                  _buildRadialItem('assets/images/journal.png', 'assets/images/journal.png', 2),
                  _buildRadialItem('assets/images/library.png', 'assets/images/library.png', 3),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * math.pi / 4,
                    child: Container(
                      width: widget.itemSize,
                      height: widget.itemSize,
                      decoration: BoxDecoration(
                        color: _isOpen ? Colors.red : Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Image.asset("assets/images/pouch.png"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialItem(String selectedSvg, String unselectedSvg, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final angle = (2 * math.pi / 4) * index;
        final radius = widget.radius * _scaleAnimation.value;
        final x = math.cos(angle - math.pi / 2) * radius;
        final y = math.sin(angle - math.pi / 2) * radius;

        final itemSize = _isOpen ? (widget.currentPage == index ? 60.0 : 50.0) : 0.0;
        final halfSize = itemSize / 2;

        return AnimatedPositioned(
          duration: Duration(milliseconds: 100),
          left: (widget.radius + widget.itemSize) + x - halfSize,
          top: (widget.radius + widget.itemSize) + y - halfSize,
          child: GestureDetector(
            onTap: () => _selectItem(index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 100),
              width: itemSize,
              height: itemSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Image.asset(index == widget.currentPage ? selectedSvg : unselectedSvg),
            ),
          ),
        );
      },
    );
  }
}
