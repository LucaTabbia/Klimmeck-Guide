import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/utils/initial_letter.dart';

/// Stendardi delle 26 lettere appesi alla linea del titolo, da un margine
/// all'altro della pagina, su due file
/// alternate: i corti davanti (A, C, …), i lunghi dietro (B, D, …). Quello
/// scelto scende di un tratto; la parte alta resta sempre fuori dalla pagina.
/// Ritirati, restano fuori solo le punte dei lunghi e, più lunga, quella dello
/// stendardo scelto.
/// Una lettera senza voci è sbiadita e non si tocca.
class LetterBookmarks extends StatelessWidget {
  const LetterBookmarks({
    super.key,
    required this.available,
    required this.selected,
    required this.onTap,
    required this.isOpen,
  });

  static const Duration slideDuration = Duration(milliseconds: 300);
  static const double _unavailableOpacity = 0.35;
  static const double _maxBannerWidth = 44;

  /// Larghezza dello stendardo in passi fra una lettera e la successiva.
  static const double _bannerWidthInSteps = 1.5;

  // Lo stendardo dentro l'immagine quadrata, in frazioni del lato.
  static const double _artWidth = 0.34;
  static const double _artLeft = 0.33;
  static const double _artBottomMargin = 0.015;

  // Tratto visibile sotto la linea, in frazioni del lato dell'immagine.
  static const double _shortReach = 0.48;
  static const double _longReach = 0.79;
  static const double _selectedExtraReach = 0.08;

  /// Punta dei lunghi che resta fuori quando gli stendardi sono ritirati.
  static const double _foldedPeek = 0.09;

  static double _bannerWidthFor(double width) =>
      math.min(_maxBannerWidth, width / alphabet.length * _bannerWidthInSteps);

  /// Altezza della fascia per una pagina larga [width]: fino alla punta dello
  /// stendardo lungo quando è scelto.
  static double extentFor(double width) =>
      _bannerWidthFor(width) / _artWidth * (_longReach + _selectedExtraReach);

  /// Altezza che resta occupata con gli stendardi ritirati: la punta dei
  /// lunghi.
  static double foldedExtentFor(double width) =>
      _bannerWidthFor(width) / _artWidth * _foldedPeek;

  static Key keyOf(String letter) => ValueKey('library.letterBookmark.$letter');

  static bool isShort(String letter) => alphabet.indexOf(letter).isEven;

  /// Lettere con almeno una voce nel libro.
  final Set<String> available;

  /// Lettera scelta; `null` = nessun filtro.
  final String? selected;
  final ValueChanged<String> onTap;

  /// Calati sotto la linea; altrimenti ritirati sotto il titolo, dove non si
  /// toccano.
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerWidth = _bannerWidthFor(constraints.maxWidth);
        final side = bannerWidth / _artWidth;
        final spread =
            (constraints.maxWidth - bannerWidth) / (alphabet.length - 1);
        final longFirst = [
          ...alphabet.where((letter) => !isShort(letter)),
          ...alphabet.where(isShort),
        ];
        return SizedBox(
          height: extentFor(constraints.maxWidth),
          child: IgnorePointer(
            ignoring: !isOpen,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final letter in longFirst)
                  Positioned(
                    top: 0,
                    left: alphabet.indexOf(letter) * spread,
                    child: _banner(
                      letter,
                      bannerWidth: bannerWidth,
                      side: side,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _reachOf(String letter) {
    final isSelected = letter == selected;
    final extraReach = isSelected ? _selectedExtraReach : 0;
    if (!isOpen) {
      return isShort(letter) && !isSelected ? 0 : _foldedPeek + extraReach;
    }
    return (isShort(letter) ? _shortReach : _longReach) + extraReach;
  }

  Widget _banner(
    String letter, {
    required double bannerWidth,
    required double side,
  }) {
    final isAvailable = available.contains(letter);
    final reach = _reachOf(letter);
    return GestureDetector(
      key: keyOf(letter),
      behavior: HitTestBehavior.opaque,
      onTap: isAvailable ? () => onTap(letter) : null,
      child: Opacity(
        opacity: isAvailable ? 1 : _unavailableOpacity,
        child: AnimatedContainer(
          duration: slideDuration,
          curve: Curves.easeInOut,
          width: bannerWidth,
          height: side * reach,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -side * _artLeft,
                bottom: -side * _artBottomMargin,
                width: side,
                height: side,
                child: CachedSvg(
                  url: CloudinaryAssets.url(
                    CloudinaryAssets.letterBookmarks[letter]!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
