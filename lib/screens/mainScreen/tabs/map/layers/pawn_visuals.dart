import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../../../theme/kg_theme.dart';
import '../utils/map_constants.dart';

/// Scala della pedina allo zoom corrente, uguale per ogni pedina della mappa.
double pawnScaleForZoom(double zoom) =>
    (zoom * 0.05 + 0.4) * 0.08 * MapConstants.characterMarkerSize;

/// Etichetta sopra la pedina: solo testo, non intercetta i gesti della mappa.
class PawnLabel extends StatelessWidget {
  const PawnLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KlimmeckGuideTheme.parchment,
          borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KlimmeckGuideTheme.spacingSm,
            vertical: KlimmeckGuideTheme.spacingXs,
          ),
          child: AutoSizeText(
            text,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: KlimmeckGuideTheme.darkWood,
            ),
          ),
        ),
      ),
    );
  }
}
