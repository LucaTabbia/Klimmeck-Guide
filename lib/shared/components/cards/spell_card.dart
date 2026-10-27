import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';
import '../animated_pencil_text.dart';

class SpellCard extends StatelessWidget {
  static final _cardBackgroundUrl = CloudinaryAssets.url(CloudinaryAssets.emptyCardSheet);

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
                  _buildTextSection(text: spell.name ?? ""),
                  if (power != null && power != 0)
                    _buildTextSection(text: power.toString()),
                ],
              ),
            ),
            if (usages != null)
              Positioned(
                right: 7,
                bottom: 0,
                child: SizedBox(
                  height: 50,
                  width: 25,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            final fadeIn = CurvedAnimation(
                              parent: animation,
                              curve: const Interval(
                                0.3,
                                1.0,
                                curve: Curves.easeOut,
                              ),
                            );

                            final scaleIn = Tween<double>(
                              begin: 1.2,
                              end: 1.0,
                            ).animate(fadeIn);

                            return FadeTransition(
                              opacity: fadeIn,
                              child: ScaleTransition(
                                scale: scaleIn,
                                child: child,
                              ),
                            );
                          },
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: AnimatedPencilText(
                        key: ValueKey<int>(usages!),
                        text: usages.toString(),
                      ),
                    ),
                  ),
                ),
              ),
            if (isMarked != null)
              CardBookmark(isMarked: isMarked!, cardSize: size),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection({required String text}) {
    return SizedBox(
      height: size / 6,
      child: AutoSizeText(
        text,
        maxFontSize: 24,
        minFontSize: 4,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              offset: Offset.zero,
              blurRadius: 0.7,
              color: KlimmeckGuideTheme.deepNight.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }
}
