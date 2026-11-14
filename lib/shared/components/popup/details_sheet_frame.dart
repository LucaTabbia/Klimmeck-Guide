import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Cornice dei fogli di dettaglio del tocco prolungato (Phase 8 D-09, Phase 22
/// D-22): pergamena, carta, dettagli, segnalibro opzionale.
class DetailsSheetFrame extends StatelessWidget {
  const DetailsSheetFrame({
    super.key,
    required this.cardBuilder,
    required this.body,
    this.isMarked,
    this.isPending = false,
    this.onToggle,
  });

  /// Carta in cima al foglio, larga metà dello spazio interno.
  final Widget Function(double cardSize) cardBuilder;
  final Widget body;

  /// Segnalibro rosso; `null` = nessun segnalibro.
  final bool? isMarked;
  final bool isPending;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final svgWidth = screenHeight * 1.3 * (315 / 375);
    final svgHeight = screenHeight * 1.3;
    final marked = isMarked;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CachedSvg(
          url: CloudinaryAssets.url(CloudinaryAssets.emptySheet),
          height: svgHeight,
          width: svgWidth,
        ),
        SizedBox(
          width: svgWidth,
          height: svgHeight,
          child: Padding(
            padding: EdgeInsets.only(
              top: svgHeight / 6,
              left: svgWidth / 9,
              right: svgWidth / 9,
              bottom: svgHeight / 8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  cardBuilder(constraints.maxWidth / 2),
                  Expanded(child: SingleChildScrollView(child: body)),
                ],
              ),
            ),
          ),
        ),
        if (marked != null)
          BookmarkRibbon(
            isMarked: marked,
            length: screenHeight / 2.5,
            peek: screenHeight / 4,
            left: 20,
            curve: Curves.linear,
            opacity: isPending ? KlimmeckGuideTheme.pendingInkOpacity : 1,
            onTap: onToggle,
          ),
      ],
    );
  }
}
