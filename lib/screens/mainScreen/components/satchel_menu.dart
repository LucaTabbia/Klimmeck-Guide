import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class SatchelMenu extends StatefulWidget {
  final AnimationController parentAnimationController;
  final int currentPage;
  final Function(int) onItemTap;

  const SatchelMenu({
    super.key,
    required this.currentPage,
    required this.onItemTap,
    required this.parentAnimationController,
  });

  @override
  State<SatchelMenu> createState() => _SatchelMenuState();
}

class _SatchelMenuState extends State<SatchelMenu> with TickerProviderStateMixin {
  final double radius = 150.0;
  double itemSize = 100.0;
  late AnimationController _animationController;
  late AnimationController _itemAnimationController;

  late Animation<double> _sizeAnimation;

  bool _isOpen = false;
  bool _showItems = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _itemAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _sizeAnimation = Tween<double>(
      begin: itemSize / 2,
      end: itemSize,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isOpen) {
        _itemAnimationController.forward();
        setState(() {
          _showItems = true;
        });
      }
    });
    _itemAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_isOpen) {
        _animationController.reverse();
        widget.parentAnimationController.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(SatchelMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage &&
        !_itemAnimationController.isAnimating &&
        !_animationController.isAnimating) {
      _toggleMenu();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _itemAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (!_isOpen) {
      setState(() {
        _showItems = false;
      });
      _itemAnimationController.reverse();
    } else {
      _animationController.forward();
      widget.parentAnimationController.forward();
    }
  }

  void _selectItem(int index) {
    widget.onItemTap(index);
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            _buildRadialItem('assets/images/menuMap.png', 'assets/images/menuMap.png', 0),
            _buildRadialItem('assets/images/mirror.png', 'assets/images/mirror.png', 1),
            _buildRadialItem('assets/images/journal.png', 'assets/images/journal.png', 2),
            _buildRadialItem('assets/images/library.png', 'assets/images/library.png', 3),
            _buildRadialItem('assets/images/board.png', 'assets/images/board.png', 4),
            _buildRadialItem('assets/images/shop.png', 'assets/images/shop.png', 5),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;

                final positionAnimation = Tween<double>(
                  begin: 25,
                  end: (screenHeight / 2) - 50,
                ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          bottom: positionAnimation.value,
                          left: 25,
                          child: GestureDetector(
                            onTap: _toggleMenu,
                            child: Container(
                              width: _sizeAnimation.value,
                              height: _sizeAnimation.value,
                              decoration: BoxDecoration(
                                color: !_isOpen ? KlimmeckGuideTheme.primaryGold : null,
                                shape: BoxShape.circle,
                                border: !_isOpen
                                    ? Border.all(color: KlimmeckGuideTheme.darkBronze)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 7,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset("assets/images/pouch.png"),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<double> _parabolaCoefficients(Offset start, Offset end, double apexHeight) {
    double x0 = start.dx, y0 = start.dy;
    double x2 = end.dx, y2 = end.dy;
    double xm = (x0 + x2) / 2;
    double ym = apexHeight;

    double a =
        ((y2 - y0) * (x0 - xm) - (ym - y0) * (x0 - x2)) /
        ((x2 * x2 - x0 * x0) * (x0 - xm) - (xm * xm - x0 * x0) * (x0 - x2));
    double b = (ym - y0 - a * (xm * xm - x0 * x0)) / (xm - x0);
    double c = y0 - a * x0 * x0 - b * x0;

    return [a, b, c];
  }

  Offset _pointOnParabola(double x, List<double> coeffs) {
    double a = coeffs[0], b = coeffs[1], c = coeffs[2];
    double y = a * x * x + b * x + c;
    return Offset(x, y);
  }

  Widget _buildRadialItem(String selectedSvg, String unselectedSvg, int index) {
    return AnimatedBuilder(
      animation: _itemAnimationController,
      builder: (context, child) {
        final start = Offset(25, -(MediaQuery.of(context).size.height / 2) + 50);
        double distance;
        Offset end;
        if (index <= 2) {
          distance = 150.0 + 25 + (50 * (index)) + (itemSize * (index));
          end = Offset(distance, -((MediaQuery.of(context).size.height / 4 * 3)) + 50);
        } else {
          distance = 150.0 + 25 + (50 * (index - 3)) + (itemSize * (index - 3));
          end = Offset(distance, -((MediaQuery.of(context).size.height / 4)) + 50);
        }

        final coefficients = _parabolaCoefficients(
          start,
          end,
          -(MediaQuery.of(context).size.height / 2 + 100),
        );
        double progress = _itemAnimationController.value;
        double x = start.dx + (end.dx - start.dx) * progress;
        Offset pos = _pointOnParabola(x, coefficients);

        return Transform.translate(
          offset: pos,
          child: GestureDetector(
            onTap: () => _selectItem(index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: _showItems ? itemSize : 0,
              height: _showItems ? itemSize : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 7, offset: Offset(0, 2))],
              ),
              child: Image.asset(index == widget.currentPage ? selectedSvg : unselectedSvg),
            ),
          ),
        );
      },
    );
  }
}
