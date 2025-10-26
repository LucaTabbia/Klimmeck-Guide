import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';
import '../animated_pencil_text.dart';

class EquipmentItemCard extends StatelessWidget {
  const EquipmentItemCard({
    super.key,
    required this.equipmentItem,
    required this.size,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.quantity,
  });

  static const _cardBackgroundUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1761305419/emptyCardSheet_tva16h.svg";
  static const _bookmarkUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683920/bookmarkRed_jms0vk.svg";

  final EquipmentItem equipmentItem;
  final double size;
  final bool isSelected;
  final int? quantity;
  final Function(EquipmentItem)? onTap;
  final Function(EquipmentItem)? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(equipmentItem) : null,
      onLongPress: onLongPress != null
          ? () => onLongPress!(equipmentItem)
          : null,
      child: RepaintBoundary(
        child: Stack(
          children: [
            CachedSvg(url: _cardBackgroundUrl, width: size, height: size),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: size,
                width: size,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    CachedSvg(
                      url: equipmentItem.equipType!.imagePath,
                      height: size / 1.8,
                      width: size,
                    ),
                    Spacer(),
                    SizedBox(
                      height: (size / 6),
                      child: AutoSizeText(
                        equipmentItem.name ?? "",
                        maxFontSize: 24,
                        minFontSize: 4,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                          color: equipmentItem.rarity!.color,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              offset: Offset.zero,
                              blurRadius: 0.7,
                              color: KlimmeckGuideTheme.deepNight.withAlpha(
                                150,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(flex: 2),
                  ],
                ),
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
            _BookmarkMarker(isSelected: isSelected, size: size),
          ],
        ),
      ),
    );
  }
}

class _BookmarkMarker extends StatelessWidget {
  final bool isSelected;
  final double size;

  const _BookmarkMarker({required this.isSelected, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: !isSelected ? -(size / 2.5) : 0,
      left: 5,
      child: const RotatedBox(
        quarterTurns: 3,
        child: CachedSvg(url: EquipmentItemCard._bookmarkUrl),
      ),
    );
  }
}
