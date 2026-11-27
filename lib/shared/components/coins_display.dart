import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../models/enums/column_layout_type.dart';

/// Prezzo o somma in monete: mostra solo i tagli che contiene.
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
      for (final (count, asset) in shownCoinsOf(coins))
        _buildCoinItem(
          context,
          count.toString(),
          CloudinaryAssets.url(asset),
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

/// Tagli da mostrare per [coins], con l'asset di ciascuno: solo quelli
/// presenti; nessuna moneta legge un solo rame a zero.
List<(int, String)> shownCoinsOf(Coins? coins) {
  final shown = [
    if (coins?.gold case final gold? when gold > 0)
      (gold, CloudinaryAssets.goldCoin),
    if (coins?.silver case final silver? when silver > 0)
      (silver, CloudinaryAssets.silverCoin),
    if (coins?.copper case final copper? when copper > 0)
      (copper, CloudinaryAssets.copperCoin),
  ];
  return shown.isEmpty ? [(0, CloudinaryAssets.copperCoin)] : shown;
}
