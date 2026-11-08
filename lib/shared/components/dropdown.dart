import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../theme/kg_theme.dart';

/// Intestazione di una sezione a tendina: nome, freccia ruotata di [turns]
/// (0 chiusa, 0.5 aperta) e filo di bronzo sotto. Condivisa da [Dropdown] e
/// dalle sezioni della Libreria (Phase 17 D-20).
class DropdownHeader extends StatelessWidget {
  const DropdownHeader({
    super.key,
    required this.sectionName,
    required this.turns,
    required this.onTap,
  });

  final String sectionName;
  final double turns;
  final VoidCallback onTap;

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
                        turns: AlwaysStoppedAnimation(turns),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CachedSvg(
                            url: CloudinaryAssets.url(
                              CloudinaryAssets.arrowDown,
                            ),
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
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: KlimmeckGuideTheme.darkBronze,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _sizeFactor,
          builder: (context, _) => DropdownHeader(
            sectionName: widget.sectionName,
            turns: _sizeFactor.value * 0.5,
            onTap: _toggle,
          ),
        ),
        widget.maxHeight != null
            ? AnimatedContainer(
                height: _isOpen ? widget.maxHeight! - 43 : 0,
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
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
  }
}
