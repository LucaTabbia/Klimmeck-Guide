import 'package:flutter/material.dart';

import '../../../../../theme/kg_theme.dart';

/// Segnalino in cima alla Mappa in teletrasporto (UAT 2026-11-01): dice al GM
/// che sta guardando la Mappa della Locanda, non la propria. Niente chrome.
class TeleportModeBadge extends StatelessWidget {
  const TeleportModeBadge({super.key});

  static const Key badgeKey = ValueKey('map.teleportBadge');
  static const String label = 'Modalità Locanda';

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: KlimmeckGuideTheme.parchment);
    return DecoratedBox(
      key: badgeKey,
      decoration: BoxDecoration(
        color: KlimmeckGuideTheme.darkWood,
        borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KlimmeckGuideTheme.spacingMd,
          vertical: KlimmeckGuideTheme.spacingXs,
        ),
        child: Text(label, style: labelStyle),
      ),
    );
  }
}
