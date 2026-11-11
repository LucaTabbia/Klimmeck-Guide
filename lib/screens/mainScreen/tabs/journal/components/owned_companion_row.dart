import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Riga di un compagno posseduto (D-17): pergamena con il segnalibro e il
/// marcatore «Al tuo fianco» quando è lui nello slot, e la sua esperienza
/// quando il backend ne serve il massimo; il tocco equipaggia, o toglie chi è
/// già al fianco. In attesa la pergamena sbiadisce.
class OwnedCompanionRow extends StatelessWidget {
  const OwnedCompanionRow({
    super.key,
    required this.owned,
    required this.isDisplayed,
    required this.isPending,
    required this.cardSize,
    required this.onTap,
  });

  final OwnedPet owned;
  final bool isDisplayed;
  final bool isPending;
  final double cardSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pet = owned.pet;
    final xpLine = companionXpLine(owned.xp, owned.pet.maxXp);
    final style = KlimmeckGuideTheme.instance.bodyMedium;
    return GestureDetector(
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
            if (isDisplayed || xpLine != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDisplayed)
                        Text(companionEquippedMark, style: style),
                      if (xpLine != null)
                        Text(
                          xpLine,
                          key: ValueKey('companion-xp-${pet.id}'),
                          style: style,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
