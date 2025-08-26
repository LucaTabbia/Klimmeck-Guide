import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../theme/kg_theme.dart';

class MenuSection extends StatelessWidget {
  const MenuSection(this.title, {super.key, required this.onTap, required this.index});

  final String title;
  final Function(int) onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onTap(index),
          child: SizedBox(
            width: 150,
            height: (MediaQuery.of(context).size.height / 2) - 1,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 15.0),
                child: AutoSizeText(
                  title,
                  maxFontSize: 20,
                  minFontSize: 12,
                  style: KlimmeckGuideTheme.instance.titleMedium.copyWith(
                    color: KlimmeckGuideTheme.paleSilver,
                    shadows: KlimmeckGuideTheme.bordersForText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        Container(
          height: (MediaQuery.of(context).size.height / 2) - 1,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: KlimmeckGuideTheme.primaryGold, width: 2)),
          ),
        ),
      ],
    );
  }
}
