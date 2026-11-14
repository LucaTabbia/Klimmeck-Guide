import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Riga di un compagno posseduto (D-17): pergamena con il segnalibro e il
/// marcatore «Al tuo fianco» quando è lui nello slot, la sua esperienza, la
/// vita che sale mentre riposa, lo stato e l'attesa della pozione (D-09). Il
/// tocco equipaggia, o toglie chi è già al fianco; la pressione lunga apre i
/// dettagli (D-22). Sconfitto o in attesa la pergamena sbiadisce; sconfitto
/// il tocco non fa nulla (D-02).
class OwnedCompanionRow extends StatelessWidget {
  const OwnedCompanionRow({
    super.key,
    required this.owned,
    required this.isDisplayed,
    required this.isPending,
    required this.cardSize,
    required this.onTap,
    required this.onLongPress,
    this.vitality,
    this.potionWait,
  });

  final OwnedPet owned;
  final bool isDisplayed;
  final bool isPending;
  final double cardSize;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final CompanionVitality? vitality;
  final Duration? potionWait;

  @override
  Widget build(BuildContext context) {
    final pet = owned.pet;
    final isDefeated = isCompanionDefeated(owned, vitality);
    final lines = _linesOf(pet.id);
    return GestureDetector(
      key: ValueKey('owned-pet-${pet.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: isDefeated ? null : onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            AnimatedOpacity(
              opacity: isPending || isDefeated
                  ? KlimmeckGuideTheme.pendingInkOpacity
                  : 1,
              duration: KlimmeckGuideTheme.pendingInkDuration,
              child: CompanionCard(
                pet: pet,
                size: cardSize,
                name: owned.name,
                level: owned.level,
                isMarked: isDisplayed,
              ),
            ),
            if (lines.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: lines,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Nell'ordine: marcatore, esperienza, vita, stato, pozione (D-09).
  List<Widget> _linesOf(String petId) {
    final current = vitality;
    final wait = potionWait;
    final style = KlimmeckGuideTheme.instance.bodyMedium;
    final entries = <(Key?, String?)>[
      (null, isDisplayed ? companionEquippedMark : null),
      (
        ValueKey('companion-xp-$petId'),
        companionXpLine(owned.xp, owned.pet.maxXp),
      ),
      (
        ValueKey('companion-life-$petId'),
        current == null
            ? null
            : companionLifeLine(current.life, current.maxLifePoints),
      ),
      (
        ValueKey('companion-status-$petId'),
        current == null ? null : companionStatusLine(current),
      ),
      (
        ValueKey('companion-potion-$petId'),
        wait == null ? null : companionPotionWaitLine(wait),
      ),
    ];
    return [
      for (final (key, line) in entries)
        if (line != null) Text(line, key: key, style: style),
    ];
  }
}
