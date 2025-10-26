import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class CoinsColumn extends StatelessWidget {
  const CoinsColumn({
    super.key,
    required this.coins,
    required this.height,
    this.width,
    this.color,
  });

  final Coins? coins;
  final double height;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final double size = (height / 3) - 5;

    return SizedBox(
      height: height,
      width: width ?? size * 2 + 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              CachedSvg(
                height: size,
                width: size,
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1761328247/goldCoin_newd9b.svg",
              ),
              SizedBox(width: 10),
              Flexible(
                child: AutoSizeText(
                  coins?.gold.toString() ?? "0",
                  minFontSize: 10,
                  style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              CachedSvg(
                height: size,
                width: size,
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1761328260/silverCoin_u1j3xr.svg",
              ),
              SizedBox(width: 10),
              Flexible(
                child: AutoSizeText(
                  coins?.silver.toString() ?? "0",
                  minFontSize: 10,
                  style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              CachedSvg(
                height: size,
                width: size,
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1761328274/copperCoin_hgiilc.svg",
              ),
              SizedBox(width: 10),
              Flexible(
                child: AutoSizeText(
                  coins?.copper.toString() ?? "0",
                  minFontSize: 10,
                  style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
