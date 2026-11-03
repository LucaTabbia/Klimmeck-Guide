import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riga di testo di una carta (nome, potenza, velocità): un sesto dell'altezza
/// della carta, una sola riga, ombra d'inchiostro.
class CardLabel extends StatelessWidget {
  const CardLabel({super.key, required this.text, required this.cardSize});

  final String text;
  final double cardSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: cardSize / 6,
    child: AutoSizeText(
      text,
      maxFontSize: 24,
      minFontSize: 4,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(
            offset: Offset.zero,
            blurRadius: 0.7,
            color: KlimmeckGuideTheme.deepNight.withAlpha(150),
          ),
        ],
      ),
    ),
  );
}
