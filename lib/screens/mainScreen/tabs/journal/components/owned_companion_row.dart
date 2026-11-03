import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Riga di un compagno posseduto (D-17): pergamena con il segnalibro e il
/// marcatore «Al tuo fianco» quando è lui nello slot; il tocco equipaggia, o
/// toglie chi è già al fianco. In attesa la pergamena sbiadisce.
class OwnedCompanionRow extends StatelessWidget {
  const OwnedCompanionRow({
    super.key,
    required this.pet,
    required this.isDisplayed,
    required this.isPending,
    required this.cardSize,
    required this.onTap,
  });

  final Pet pet;
  final bool isDisplayed;
  final bool isPending;
  final double cardSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: ValueKey('owned-pet-${pet.id}'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: isPending ? KlimmeckGuideTheme.pendingInkOpacity : 1,
            duration: KlimmeckGuideTheme.pendingInkDuration,
            child: CompanionCard(
              pet: pet,
              size: cardSize,
              isMarked: isDisplayed,
            ),
          ),
          if (isDisplayed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  companionEquippedMark,
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
