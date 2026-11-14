import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/companion/companion_display_name.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/card_label.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Carta del compagno (Phase 22 D-22, D-34): immagine, nome scelto o specie nel
/// colore della rarità, specie sotto quando ha un nome; velocità da sella;
/// attacco e difesa stanno nel foglio di dettaglio.
class CompanionCard extends StatelessWidget {
  const CompanionCard({
    super.key,
    required this.pet,
    required this.size,
    this.name,
    this.level,
    this.isMarked,
  });

  static Key titleKeyOf(String petId) =>
      ValueKey('companion-card-title-$petId');
  static Key speciesKeyOf(String petId) =>
      ValueKey('companion-card-species-$petId');
  static Key imageKeyOf(String petId) =>
      ValueKey('companion-card-image-$petId');

  static const double _imageShare = 0.45;
  static const double _subLabelShare = 0.75;

  static final _cardBackgroundUrl = CloudinaryAssets.url(
    CloudinaryAssets.emptyCardSheet,
  );

  final Pet pet;
  final double size;

  /// Nome scelto (D-18); `null` = la specie fa da titolo.
  final String? name;

  /// Livello del compagno posseduto (D-37); `null` = nascosto (catalogo).
  final int? level;

  /// Segnalibro rosso del compagno al fianco; `null` = nessun segnalibro.
  final bool? isMarked;

  bool get _hasName => name?.trim().isNotEmpty ?? false;

  String? get _subLabel => _hasName
      ? companionSpeciesLevelLine(pet.name ?? '', level)
      : companionLevelLine(level);

  @override
  Widget build(BuildContext context) {
    final speed = companionSpeedLabel(pet);
    final subLabel = _subLabel;
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
                if (EnemyPortrait.canShow(pet.imagePath))
                  EnemyPortrait(
                    key: imageKeyOf(pet.id),
                    imagePath: pet.imagePath,
                    height: size * _imageShare,
                  ),
                CardLabel(
                  key: titleKeyOf(pet.id),
                  text: companionDisplayName(name: name, pet: pet),
                  cardSize: size,
                  color: pet.rarity?.color,
                ),
                if (subLabel != null)
                  CardLabel(
                    key: speciesKeyOf(pet.id),
                    text: subLabel,
                    cardSize: size * _subLabelShare,
                  ),
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
