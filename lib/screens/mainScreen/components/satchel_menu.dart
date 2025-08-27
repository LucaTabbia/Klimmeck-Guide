import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_item.dart';
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
  late AnimationController _animationController;
  late AnimationController _itemAnimationController;
  late Animation<double> _sizeAnimation;

  final double _itemSize = 100.0;
  final List menuImages = [
    {
      "selectedImagePath": "assets/images/menu/menuMap.png",
      "unselectedImagePath": "assets/images/menu/menuMap.png",
    },
    {
      "selectedImagePath": "assets/images/menu/mirror.png",
      "unselectedImagePath": "assets/images/menu/mirror.png",
    },
    {
      "selectedImagePath": "assets/images/menu/journal.png",
      "unselectedImagePath": "assets/images/menu/journal.png",
    },
    {
      "selectedImagePath": "assets/images/menu/library.png",
      "unselectedImagePath": "assets/images/menu/library.png",
    },
    {
      "selectedImagePath": "assets/images/menu/board.png",
      "unselectedImagePath": "assets/images/menu/board.png",
    },
    {
      "selectedImagePath": "assets/images/menu/shop.png",
      "unselectedImagePath": "assets/images/menu/shop.png",
    },
  ];
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
      begin: _itemSize / 2,
      end: _itemSize,
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
            ...List.generate(menuImages.length, (index) {
              final images = menuImages[index];
              return MenuItem(
                imagePath: index == widget.currentPage
                    ? images["selectedImagePath"]
                    : images["unselectedImagePath"],
                index: index,
                onTap: _selectItem,
                itemAnimationController: _itemAnimationController,
                itemSize: _itemSize,
                showItems: _showItems,
              );
            }),
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
                              child: Image.asset("assets/images/menu/pouch.png"),
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
}
