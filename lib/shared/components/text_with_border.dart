import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

class TextWithBorder extends StatelessWidget {
  const TextWithBorder({super.key, required this.text, required this.color, required this.style});

  final String text;
  final Color? color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AutoSizeText(
          maxFontSize: 24,
          minFontSize: 8,
          maxLines: 2,
          textAlign: TextAlign.center,
          text,
          style: style.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        AutoSizeText(
          maxFontSize: 24,
          minFontSize: 8,
          maxLines: 2,
          textAlign: TextAlign.center,
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..color = KlimmeckGuideTheme.deepNight,
          ),
        ),
      ],
    );
  }
}
