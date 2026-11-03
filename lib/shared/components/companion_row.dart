import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../theme/kg_theme.dart';
import '../../utils/item_lines.dart';
import 'coins_display.dart';

/// Riga di un compagno (negozio e Diario): nome, prezzo, velocità solo per
/// un compagno da sella, marcatore se equipaggiato. Solo testo, nessuna
/// immagine (D-13). Visual provvisorio.
class CompanionRow extends StatelessWidget {
  const CompanionRow({
    super.key,
    required this.pet,
    required this.size,
    this.isBuy = true,
    this.showCoins = true,
    this.isEquipped = false,
    this.isSelected = false,
    this.onTap,
  });

  final Pet pet;
  final double size;
  final bool isBuy;
  final bool showCoins;
  final bool isEquipped;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: isSelected
            ? KlimmeckGuideTheme.primaryGold.withAlpha(100)
            : null,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            if (showCoins)
              CoinsDisplay(
                coins: isBuy ? pet.buyPrice : pet.sellPrice,
                height: size,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildTexts(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTexts() {
    final speed = companionSpeedLabel(pet);
    final style = KlimmeckGuideTheme.instance.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(pet.name ?? '', style: style),
        if (speed != null)
          Text(speed, key: ValueKey('companion-speed-${pet.id}'), style: style),
        if (isEquipped)
          Text(
            companionEquippedMark,
            key: ValueKey('companion-equipped-${pet.id}'),
            style: style,
          ),
      ],
    );
  }
}
