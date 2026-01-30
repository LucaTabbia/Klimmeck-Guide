import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../models/enums/column_layout_type.dart';

class CoinsDisplay extends StatelessWidget {
  const CoinsDisplay({
    super.key,
    required this.coins,
    required this.height,
    this.width,
    this.color,
    this.layout = CoinLayoutType.column,
    this.textStyle,
  });

  final Coins? coins;
  final double height;
  final double? width;
  final Color? color;
  final CoinLayoutType layout;
  final TextStyle? textStyle;

  Widget _buildCoinItem(
    BuildContext context,
    String count,
    String svgUrl,
    double iconSize,
    Color? textColor,
    bool isRowLayout,
  ) {
    final effectiveTextStyle =
        textStyle ??
        KlimmeckGuideTheme.instance.bodyMedium.copyWith(
          color: textColor,
          fontWeight: isRowLayout ? FontWeight.bold : FontWeight.normal,
        );

    final coinIcon = CachedSvg(height: iconSize, width: iconSize, url: svgUrl);

    final coinText = AutoSizeText(
      count,
      minFontSize: 10,
      textAlign: isRowLayout ? TextAlign.center : TextAlign.start,
      style: effectiveTextStyle,
    );

    if (isRowLayout) {
      return Expanded(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            coinIcon,
            Expanded(child: coinText),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          coinIcon,
          const SizedBox(width: 10),
          Flexible(child: coinText),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRowLayout = layout == CoinLayoutType.row;

    final double iconSize = isRowLayout ? height : (height / 3) - 5;

    final List<Widget> coinItems = [
      _buildCoinItem(
        context,
        coins?.gold.toString() ?? "0",
        CloudinaryAssets.url(CloudinaryAssets.goldCoin),
        iconSize,
        color,
        isRowLayout,
      ),
      _buildCoinItem(
        context,
        coins?.silver.toString() ?? "0",
        CloudinaryAssets.url(CloudinaryAssets.silverCoin),
        iconSize,
        color,
        isRowLayout,
      ),
      _buildCoinItem(
        context,
        coins?.copper.toString() ?? "0",
        CloudinaryAssets.url(CloudinaryAssets.copperCoin),
        iconSize,
        color,
        isRowLayout,
      ),
    ];

    if (isRowLayout) {  
      return SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: coinItems,
        ),
      );
    } else {
      final double defaultWidth = iconSize * 2 + 10;
      return SizedBox(
        height: height,
        width: width ?? defaultWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: coinItems,
        ),
      );
    }
  }
}
