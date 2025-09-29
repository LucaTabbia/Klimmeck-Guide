import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../theme/kg_theme.dart';

class Dropdown extends StatefulWidget {
  const Dropdown({
    super.key,
    required this.sectionName,
    required this.data,
    this.initiallyOpen = false,
  });

  final String sectionName;
  final Widget data;
  final bool initiallyOpen;

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _sizeFactor;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initiallyOpen;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isOpen ? 1.0 : 0.0,
    );
    _sizeFactor = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  void _toggleDropdown() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final contentWidth = maxWidth - (maxWidth / 5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DropdownHeader(
              sectionName: widget.sectionName,
              maxWidth: maxWidth,
              contentWidth: contentWidth,
              onTap: _toggleDropdown,
              sizeFactor: _sizeFactor,
            ),
            _DropdownDivider(width: contentWidth),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _sizeFactor,
                axisAlignment: -1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                  child: widget.data,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DropdownHeader extends StatelessWidget {
  final String sectionName;
  final double maxWidth;
  final double contentWidth;
  final VoidCallback onTap;
  final Animation<double> sizeFactor;

  const _DropdownHeader({
    required this.sectionName,
    required this.maxWidth,
    required this.contentWidth,
    required this.onTap,
    required this.sizeFactor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 5.0),
        child: Row(
          children: [
            SizedBox(
              width: contentWidth,
              child: AutoSizeText(
                sectionName,
                maxFontSize: 20,
                minFontSize: 12,
                style: KlimmeckGuideTheme.instance.titleMedium,
              ),
            ),
            RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.5).animate(sizeFactor),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CachedSvg(
                  url:
                      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683903/arrowDown_byudlt.svg",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownDivider extends StatelessWidget {
  final double width;

  const _DropdownDivider({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: KlimmeckGuideTheme.darkBronze, width: 1)),
      ),
    );
  }
}
