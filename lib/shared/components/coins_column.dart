import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/models/coins.dart';
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
              SvgPicture.asset(height: height / 3 - 5, "assets/icons/svg/coins/goldCoin.svg"),
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
              SvgPicture.asset(height: height / 3 - 5, "assets/icons/svg/coins/silverCoin.svg"),
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
              SvgPicture.asset(height: height / 3 - 5, "assets/icons/svg/coins/copperCoin.svg"),
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
