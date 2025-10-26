import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../theme/kg_theme.dart';

class Dropdown extends StatefulWidget {
  const Dropdown({
    super.key,
    required this.sectionName,
    required this.data,
    this.isOpen = false,
    this.onToggle,
    this.maxHeight,
  });

  final String sectionName;
  final Widget data;
  final double? maxHeight;
  final bool isOpen;
  final VoidCallback? onToggle;

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _sizeFactor;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.isOpen;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isOpen ? 1.0 : 0.0,
    );
    _sizeFactor = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _toggle() {
    if (!_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() => _isOpen = !_isOpen);
    if (widget.onToggle != null) {
      widget.onToggle!();
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
            SizedBox(
              height: 42,
              child: InkWell(
                onTap: () => _toggle(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: contentWidth,
                        child: AutoSizeText(
                          widget.sectionName,
                          maxFontSize: 20,
                          minFontSize: 12,
                          style: KlimmeckGuideTheme.instance.titleMedium,
                        ),
                      ),
                      RotationTransition(
                        turns: Tween<double>(
                          begin: 0,
                          end: 0.5,
                        ).animate(_sizeFactor),
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
              ),
            ),
            Container(
              width: contentWidth,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: KlimmeckGuideTheme.darkBronze,
                    width: 1,
                  ),
                ),
              ),
            ),
            widget.maxHeight != null
                ? AnimatedContainer(
                    height: _isOpen ? widget.maxHeight! - 43 : 0,
                    duration: Duration(microseconds: 250),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        top: 10,
                        bottom: 10,
                      ),
                      child: SingleChildScrollView(child: widget.data),
                    ),
                  )
                : ClipRect(
                    child: SizeTransition(
                      sizeFactor: _sizeFactor,
                      axisAlignment: -1,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          top: 10,
                          bottom: 10,
                        ),
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
