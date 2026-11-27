import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';

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
    this.badge,
  });

  final String sectionName;
  final double turns;
  final VoidCallback onTap;

  /// Segnale a destra, accanto alla freccia: la sezione contiene una novità.
  final Widget? badge;

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
                        child: Row(
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                sectionName,
                                maxFontSize: 20,
                                minFontSize: 12,
                                style: KlimmeckGuideTheme.instance.titleMedium,
                              ),
                            ),
                            if (badge != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: KlimmeckGuideTheme.spacingSm,
                                ),
                                child: badge,
                              ),
                          ],
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
    this.badge,
    this.pinned,
  });

  final String sectionName;
  final Widget data;
  final double? maxHeight;
  final bool isOpen;
  final VoidCallback? onToggle;

  /// Segnale accanto al nome: la sezione contiene una novità.
  final Widget? badge;

  /// Riga fissa sotto la testata (per esempio i filtri): resta ferma mentre
  /// il contenuto scorre.
  final Widget? pinned;

  /// Rientro del contenuto sotto la testata: chi sta fuori dalla tendina lo
  /// usa per allinearsi.
  static const EdgeInsets contentPadding = EdgeInsets.only(
    left: 10,
    top: 10,
    bottom: 10,
  );

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
            badge: widget.badge,
          ),
        ),
        if (widget.maxHeight case final maxHeight?)
          _buildScrollingContent(maxHeight)
        else
          ClipRect(
            child: SizeTransition(
              sizeFactor: _sizeFactor,
              axisAlignment: -1,
              child: _buildContent(),
            ),
          ),
      ],
    );
  }

  static const double _headerHeight = 43;

  Widget _buildContent() {
    final pinned = widget.pinned;
    return Padding(
      padding: Dropdown.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?pinned, widget.data],
      ),
    );
  }

  /// La riga fissa resta sotto la testata; solo il contenuto scorre, fino
  /// alla riga. Aprendosi e richiudendosi il contenuto resta alla sua altezza
  /// piena e viene ritagliato: niente sbordi a metà animazione.
  Widget _buildScrollingContent(double maxHeight) {
    final pinned = widget.pinned;
    final height = maxHeight - _headerHeight;
    return AnimatedContainer(
      height: _isOpen ? height : 0,
      duration: const Duration(milliseconds: 250),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: height,
        maxHeight: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pinned != null)
              Padding(
                padding: EdgeInsets.only(left: Dropdown.contentPadding.left),
                child: pinned,
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: PaperSheetScope.listPhysicsOf(context),
                padding: Dropdown.contentPadding,
                child: widget.data,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
