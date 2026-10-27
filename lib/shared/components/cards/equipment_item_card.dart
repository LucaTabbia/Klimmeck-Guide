import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';

import '../../../theme/kg_theme.dart';

class EquipmentItemCard extends StatefulWidget {
  const EquipmentItemCard({
    super.key,
    required this.equipmentItem,
    required this.size,
    this.isSelected,
    this.onTap,
    this.onLongPress,
    this.quantity,
  });

  final EquipmentItem equipmentItem;
  final double size;
  final bool? isSelected;
  final int? quantity;
  final Function(EquipmentItem)? onTap;
  final Function(EquipmentItem)? onLongPress;

  @override
  State<EquipmentItemCard> createState() => _EquipmentItemCardState();
}

class _EquipmentItemCardState extends State<EquipmentItemCard> {
  static final _cardBackgroundUrl = CloudinaryAssets.url(CloudinaryAssets.emptyCardSheet);
  late bool? _isSelected;

  @override
  void initState() {
    _isSelected = widget.isSelected;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant EquipmentItemCard oldWidget) {
    if (oldWidget.isSelected != widget.isSelected) {
      setState(() {
        _isSelected = widget.isSelected;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSelected != null) {
          setState(() {
            _isSelected = !_isSelected!;
          });
        }
        Future.delayed(
          Duration(milliseconds: 300),
          () => widget.onTap?.call(widget.equipmentItem),
        );
      },
      onLongPress: widget.onLongPress != null
          ? () => widget.onLongPress!(widget.equipmentItem)
          : null,
      child: RepaintBoundary(
        child: Stack(
          children: [
            CachedSvg(
              url: _cardBackgroundUrl,
              width: widget.size,
              height: widget.size,
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: widget.size,
                width: widget.size,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    CachedSvg(
                      url: widget.equipmentItem.equipType!.imagePath,
                      height: widget.size / 1.8,
                      width: widget.size,
                    ),
                    Spacer(),
                    SizedBox(
                      height: (widget.size / 6),
                      child: AutoSizeText(
                        widget.equipmentItem.name ?? "",
                        maxFontSize: 24,
                        minFontSize: 4,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                          color: widget.equipmentItem.rarity!.color,
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
            if (widget.quantity != null && widget.quantity! > 0)
              Positioned(
                right: 7,
                top: 5,
                child: UsagesPencilCounter(value: widget.quantity!),
              ),
            if (_isSelected != null)
              CardBookmark(isMarked: _isSelected!, cardSize: widget.size),
          ],
        ),
      ),
    );
  }
}
