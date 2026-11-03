import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/card_label.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Pergamena di un compagno (D-17): nome e velocità da sella, nessuna immagine
/// (D-13); segnalibro quando è al fianco, come le magie attive.
class CompanionCard extends StatelessWidget {
  const CompanionCard({
    super.key,
    required this.pet,
    required this.size,
    this.isMarked,
  });

  static final _cardBackgroundUrl = CloudinaryAssets.url(
    CloudinaryAssets.emptyCardSheet,
  );

  final Pet pet;
  final double size;

  /// Segnalibro rosso del compagno al fianco; `null` = nessun segnalibro.
  final bool? isMarked;

  @override
  Widget build(BuildContext context) {
    final speed = companionSpeedLabel(pet);
    return RepaintBoundary(
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedSvg(url: _cardBackgroundUrl, height: size, width: size),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CardLabel(text: pet.name ?? '', cardSize: size),
                if (speed != null) CardLabel(text: speed, cardSize: size),
              ],
            ),
            if (isMarked != null)
              CardBookmark(isMarked: isMarked!, cardSize: size),
          ],
        ),
      ),
    );
  }
}
