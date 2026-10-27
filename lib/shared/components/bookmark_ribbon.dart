import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Segnalibro rosso degli oggetti equipaggiati e delle magie attive (D-14):
/// `AnimatedPositioned` da mettere direttamente in uno `Stack`. Segnato: tutto
/// visibile; non segnato: sporge di [peek]. Con [onTap] fa da interruttore.
class BookmarkRibbon extends StatelessWidget {
  const BookmarkRibbon({
    super.key,
    required this.isMarked,
    required this.length,
    required this.peek,
    this.width,
    this.left = 5,
    this.curve = Curves.easeInOut,
    this.opacity = 1,
    this.onTap,
  });

  static const Duration slideDuration = Duration(milliseconds: 300);
  static final String _url = CloudinaryAssets.url(CloudinaryAssets.bookmarkRed);

  final bool isMarked;

  /// Altezza dello SVG prima della rotazione; senza [width] lo SVG tiene le
  /// sue proporzioni naturali.
  final double length;
  final double? width;
  final double peek;
  final double left;
  final Curve curve;

  /// Inchiostro del segnalibro: `pendingInkOpacity` mentre l'operazione che
  /// rappresenta è in corso (D-16).
  final double opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ribbon = AnimatedOpacity(
      opacity: opacity,
      duration: KlimmeckGuideTheme.pendingInkDuration,
      child: RotatedBox(quarterTurns: 3, child: _svg()),
    );
    return AnimatedPositioned(
      duration: slideDuration,
      curve: curve,
      top: isMarked ? 0 : -length + peek,
      left: left,
      child: onTap == null
          ? ribbon
          : GestureDetector(onTap: onTap, child: ribbon),
    );
  }

  Widget _svg() {
    if (width == null) return CachedSvg(url: _url, height: length);
    return SizedBox(
      height: length,
      width: width,
      child: CachedSvg(url: _url),
    );
  }
}

/// Segnalibro dimensionato su una carta quadrata (oggetti e magie): un solo
/// posto per il wrapper di [BookmarkRibbon] (zero duplicazione, D-14).
class CardBookmark extends StatelessWidget {
  const CardBookmark({
    super.key,
    required this.isMarked,
    required this.cardSize,
  });

  static const double _peek = 20;

  final bool isMarked;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: cardSize / 25),
      child: SizedBox(
        height: cardSize - cardSize / 25,
        width: cardSize,
        child: Stack(
          children: [
            BookmarkRibbon(
              isMarked: isMarked,
              length: cardSize / 2.5,
              width: cardSize / 2.5,
              peek: _peek,
            ),
          ],
        ),
      ),
    );
  }
}
