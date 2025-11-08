import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
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

  // Widget helper per la singola moneta e il suo valore
  Widget _buildCoinItem(
    BuildContext context,
    String count,
    String svgUrl,
    double iconSize,
    Color? textColor,
    bool isRowLayout,
  ) {
    // Stile del testo di default o personalizzato
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
      // Formato Riga (occupa spazio uguale in una Row genitore)
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
      // Formato Colonna (Originale: Icona e Testo affiancati)
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

    // In modalità Row, l'altezza definisce la dimensione di icona e testo.
    // In modalità Column, l'altezza è divisa per 3 (circa)
    final double iconSize = isRowLayout ? height : (height / 3) - 5;

    // Lista dei singoli elementi moneta
    final List<Widget> coinItems = [
      _buildCoinItem(
        context,
        coins?.gold.toString() ?? "0",
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1761328247/goldCoin_newd9b.svg",
        iconSize,
        color,
        isRowLayout,
      ),
      _buildCoinItem(
        context,
        coins?.silver.toString() ?? "0",
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1761328260/silverCoin_u1j3xr.svg",
        iconSize,
        color,
        isRowLayout,
      ),
      _buildCoinItem(
        context,
        coins?.copper.toString() ?? "0",
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1761328274/copperCoin_hgiilc.svg",
        iconSize,
        color,
        isRowLayout,
      ),
    ];

    if (isRowLayout) {
      // --- Layout Orizzontale (ROW) ---
      // L'altezza è fissa (es. 50), la larghezza è implicita data dagli Expanded.
      return SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: coinItems,
        ),
      );
    } else {
      // --- Layout Verticale (COLUMN - Originale) ---
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
