import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Cartellino legato al borsello: una riga a matita per ogni taglio che il
/// personaggio possiede, con una moneta piccola accanto. Ogni riga parte un
/// po' più a sinistra di quella sopra, seguendo il bordo del foglietto; il
/// tutto si rimpicciolisce per restare sul foglietto.
class PurseTag extends StatelessWidget {
  const PurseTag({super.key, required this.coins});

  static const double _coinSide = 18;
  static const double _gap = 4;
  static const double _digitsSize = 30;

  /// Rientro di ogni riga rispetto a quella sotto.
  static const double _lineStep = 10;

  final Coins? coins;

  @override
  Widget build(BuildContext context) {
    final lines = shownCoinsOf(coins);
    final style = KlimmeckGuideTheme.instance.signatureText.copyWith(
      fontSize: _digitsSize,
      height: 1,
      color: KlimmeckGuideTheme.deepNight,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, (count, asset)) in lines.indexed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: _lineStep * (lines.length - 1 - index)),
                CachedSvg(
                  url: CloudinaryAssets.url(asset),
                  width: _coinSide,
                  height: _coinSide,
                ),
                const SizedBox(width: _gap),
                Text(count.toString(), style: style),
              ],
            ),
        ],
      ),
    );
  }
}
