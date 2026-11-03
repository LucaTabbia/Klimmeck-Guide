import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/card_label.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';

class SpellCard extends StatelessWidget {
  static final _cardBackgroundUrl = CloudinaryAssets.url(
    CloudinaryAssets.emptyCardSheet,
  );

  final Spell spell;
  final double size;
  final int? usages;

  /// Segnalibro rosso delle magie attive (D-14); `null` = nessun segnalibro.
  final bool? isMarked;

  const SpellCard({
    super.key,
    required this.spell,
    required this.size,
    this.usages,
    this.isMarked,
  });

  @override
  Widget build(BuildContext context) {
    final useType = spell.useType;
    final energyType = spell.energyDamage?.type;
    final power = spell.energyDamage?.power;
    return RepaintBoundary(
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedSvg(url: _cardBackgroundUrl, height: size, width: size),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (useType != null)
                        CachedSvg(
                          url: useType.imagePath,
                          height: size / 2.5,
                          width: size / 2.5,
                        ),
                      if (energyType != null)
                        CachedSvg(
                          url: energyType.imagePath,
                          height: size / 2.5,
                          width: size / 2.5,
                        ),
                    ],
                  ),
                  CardLabel(text: spell.name ?? "", cardSize: size),
                  if (power != null && power != 0)
                    CardLabel(text: power.toString(), cardSize: size),
                ],
              ),
            ),
            if (usages != null)
              Positioned(
                right: 7,
                bottom: 0,
                child: UsagesPencilCounter(value: usages!),
              ),
            if (isMarked != null)
              CardBookmark(isMarked: isMarked!, cardSize: size),
          ],
        ),
      ),
    );
  }
}
