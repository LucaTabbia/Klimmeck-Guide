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

  /// Una o due icone: la misura di sempre.
  static const double _iconDivisor = 2.5;

  /// Tre icone — origine, uso, energia — stanno sulla carta solo più piccole (D-05).
  static const double _crowdedIconDivisor = 3.2;

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
    final iconUrls = [
      spell.origin?.imagePath,
      spell.useType?.imagePath,
      spell.energyDamage?.type?.imagePath,
    ].whereType<String>().toList();
    final iconSize =
        size / (iconUrls.length > 2 ? _crowdedIconDivisor : _iconDivisor);
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
                      for (final url in iconUrls)
                        CachedSvg(url: url, height: iconSize, width: iconSize),
                    ],
                  ),
                  CardLabel(text: spell.name ?? "", cardSize: size),
                  if (power != null && power != 0)
                    CardLabel(text: power.toString(), cardSize: size),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: UsagesPencilCounter(value: usages),
            ),
            if (isMarked != null)
              CardBookmark(isMarked: isMarked!, cardSize: size),
          ],
        ),
      ),
    );
  }
}
