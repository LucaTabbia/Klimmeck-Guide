import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/models/loot_item.dart';

import '../../../theme/kg_theme.dart';

class LootItemCard extends StatelessWidget {
  const LootItemCard({super.key, required this.lootItem, required this.size});

  final LootItem lootItem;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset("assets/icons/svg/sheets/emptySheet.svg", height: size, width: size),
        SizedBox(
          height: size / 1.3,
          width: size / 1.5,
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(lootItem.effect!.imagePath, height: size / 2.5, width: size),
                _buildTextSection(
                  text: lootItem.name?.toString() ?? "",
                  color: lootItem.rarity!.color,
                ),
                if (lootItem.power != 0)
                  _buildTextSection(text: lootItem.power?.toString() ?? "", color: null),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection({required String text, Color? color}) {
    return SizedBox(
      height: size / 6,
      child: AutoSizeText(
        text,
        maxFontSize: 24,
        minFontSize: 4,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              offset: const Offset(0, 0),
              blurRadius: 0.7,
              color: KlimmeckGuideTheme.deepNight.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }
}
