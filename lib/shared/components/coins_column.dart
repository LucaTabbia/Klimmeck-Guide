import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class CoinsColumn extends StatelessWidget {
  const CoinsColumn({super.key, required this.coins, required this.height, required this.width});

  final Coins? coins;
  final double height;
  final double width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CachedSvg(
                height: height / 3 - 5,
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757595152/goldCoin_newd9b.svg",
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: AutoSizeText(
                  coins?.gold?.toString() ?? "0",
                  minFontSize: 10,
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
              ),
            ],
          ),
          Row(
            children: [
              CachedSvg(
                height: height / 3 - 5,
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757595153/silverCoin_u1j3xr.svg",
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: AutoSizeText(
                  coins?.silver?.toString() ?? "0",
                  minFontSize: 10,
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
              ),
            ],
          ),
          Row(
            children: [
              CachedSvg(
                height: height / 3 - 5,
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757595153/copperCoin_hgiilc.svg",
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: AutoSizeText(
                  coins?.copper?.toString() ?? "0",
                  minFontSize: 10,
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
