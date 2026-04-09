import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

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

class _SatchelMenuState extends State<SatchelMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _itemAnimationController;
  late Animation<double> _sizeAnimation;

  final double _itemSize = 100.0;
  final List menuImages = [
    {
      "selectedImagePath": CloudinaryAssets.url(CloudinaryAssets.map),
      "unselectedImagePath": CloudinaryAssets.url(CloudinaryAssets.map),
    },
    {
      "selectedImagePath": CloudinaryAssets.url(CloudinaryAssets.mirror),
      "unselectedImagePath": CloudinaryAssets.url(CloudinaryAssets.mirror),
    },
    {
      "selectedImagePath": CloudinaryAssets.url(CloudinaryAssets.journal),
      "unselectedImagePath": CloudinaryAssets.url(CloudinaryAssets.journal),
    },
    {
      "selectedImagePath": CloudinaryAssets.url(CloudinaryAssets.library),
      "unselectedImagePath": CloudinaryAssets.url(CloudinaryAssets.library),
    },
    {
      "selectedImagePath": CloudinaryAssets.url(CloudinaryAssets.board),
      "unselectedImagePath": CloudinaryAssets.url(CloudinaryAssets.board),
    },
    {
      "selectedImagePath": CloudinaryAssets.url(CloudinaryAssets.shop),
      "unselectedImagePath": CloudinaryAssets.url(CloudinaryAssets.shop),
    },
  ];

  bool _isOpen = false;
  bool _showItems = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _itemAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sizeAnimation = Tween<double>(begin: _itemSize * 2, end: _itemSize)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.addStatusListener(_onMainAnimationStatus);
    _itemAnimationController.addStatusListener(_onItemAnimationStatus);
  }

  void _onMainAnimationStatus(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.completed && _isOpen) {
      _itemAnimationController.forward();
      setState(() {
        _showItems = true;
      });
    } else if (status == AnimationStatus.dismissed && !_isOpen) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _onItemAnimationStatus(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.dismissed && !_isOpen) {
      _animationController.reverse();
      widget.parentAnimationController.reverse();
    } else if (status == AnimationStatus.completed && _isOpen) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  @override
  void didUpdateWidget(SatchelMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage &&
        _isOpen &&
        !_isAnimating) {
      setState(() {
        _isOpen = false;
      });
      _closeMenu();
    }
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_onMainAnimationStatus);
    _itemAnimationController.removeStatusListener(_onItemAnimationStatus);
    _animationController.dispose();
    _itemAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _openMenu();
    } else {
      _closeMenu();
    }
  }

  void _openMenu() {
    _animationController.forward();
    widget.parentAnimationController.forward();
  }

  void _closeMenu() {
    setState(() {
      _showItems = false;
      _isAnimating = true;
    });
    _itemAnimationController.reverse();
  }

  void _selectItem(int index) {
    if (_isAnimating || !_isOpen) return;

    widget.onItemTap(index);

    setState(() {
      _isOpen = false;
      _isAnimating = true;
      _showItems = false;
    });
    _itemAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          _buildPouchButton(),
        ],
      ),
    );
  }

  Widget _buildPouchButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;

        final verticalPositionAnimation =
            Tween<double>(begin: -80, end: (screenHeight / 2) - 50).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutBack,
              ),
            );

        final horizontalPositionAnimation = Tween<double>(begin: -60, end: 25)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutBack,
              ),
            );

        final rotationAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  bottom: verticalPositionAnimation.value,
                  left: horizontalPositionAnimation.value,
                  child: GestureDetector(
                    onTap: _toggleMenu,
                    child: Transform.rotate(
                      angle: rotationAnimation.value,
                      child: SizedBox(
                        width: _sizeAnimation.value,
                        height: _sizeAnimation.value,
                        child: CachedSvg(
                          url: CloudinaryAssets.url(CloudinaryAssets.pouch),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
