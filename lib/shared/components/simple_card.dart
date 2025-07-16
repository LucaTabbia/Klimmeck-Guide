import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

class SimpleCard extends StatelessWidget {
  const SimpleCard({super.key, required this.text, required this.width, required this.onTap});

  final String text;
  final double width;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.11,
        width: width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: KlimmeckGuideTheme.parchment,
            )),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
          child: Center(
              child: AutoSizeText(
                text,
                maxLines: 2,
                minFontSize: 8,
                style: const TextStyle(color: KlimmeckGuideTheme.parchment),
                textAlign: TextAlign.center,
              )),
        ),
      ),
    );
  }
}
