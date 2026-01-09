import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';
import '../animated_pencil_text.dart';

class SpellCard extends StatelessWidget {
  static const _cardBackgroundUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1761305419/emptyCardSheet_tva16h.svg";

  final Spell spell;
  final double size;
  final Function(Spell)? onTap;
  final int? usages;

  const SpellCard({
    super.key,
    required this.spell,
    required this.size,
    this.onTap,
    this.usages,
  });

  @override
  Widget build(BuildContext context) {
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
                      CachedSvg(
                        url: spell.useType!.imagePath,
                        height: size / 2.5,
                        width: size / 2.5,
                      ),
                      CachedSvg(
                        url: spell.energyDamage!.type!.imagePath,
                        height: size / 2.5,
                        width: size / 2.5,
                      ),
                    ],
                  ),
                  _buildTextSection(text: spell.name ?? ""),
                  if (spell.energyDamage!.power != 0)
                    _buildTextSection(
                      text: spell.energyDamage!.power.toString(),
                    ),
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
