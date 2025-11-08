import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/animated_pencil_text.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';

class LootItemCard extends StatelessWidget {
  const LootItemCard({
    super.key,
    required this.lootItem,
    required this.size,
    this.onTap,
    this.quantity,
  });

  static const _cardBackgroundUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1761305419/emptyCardSheet_tva16h.svg";

  final Function(LootItem)? onTap;
  final LootItem lootItem;
  final double size;
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(lootItem) : null,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedSvg(url: _cardBackgroundUrl, height: size, width: size),
            SizedBox(
              width: size,
              height: size,
              child: Column(
                children: [
                  Spacer(flex: 3),
                  CachedSvg(
                    url: lootItem.effect!.imagePath,
                    height: (size / 6) * 2.5,
                    width: size,
                  ),
                  Spacer(),
                  _buildTextSection(
                    text: lootItem.name ?? "",
                    color: lootItem.rarity!.color,
                  ),
                  Spacer(),
                  if (lootItem.power != 0)
                    _buildTextSection(text: lootItem.power.toString()),
                  Spacer(flex: 3),
                ],
              ),
            ),
            if (quantity != null && quantity! > 0)
              Positioned(
                right: 7,
                top: 5,
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
                        key: ValueKey<int>(quantity!),
                        text: quantity!.toString(),
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

  Widget _buildTextSection({required String text, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: SizedBox(
        height: (size / 6),
        child: AutoSizeText(
          text,
          maxFontSize: 24,
          minFontSize: 4,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
            color: color,
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
      ),
    );
  }
}
