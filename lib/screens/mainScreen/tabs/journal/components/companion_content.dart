import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/companion_slot.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/owned_companion_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Contenuto della sezione «Compagno» (D-17): lo slot in testa e le pergamene
/// dei posseduti nell'ordine del BE, come il libro delle magie. Sotto lo slot
/// la vita di chi è al fianco (D-04, D-09).
class CompanionContent extends StatelessWidget {
  const CompanionContent({
    super.key,
    required this.owned,
    required this.displayed,
    required this.pendingPetId,
    required this.cardSize,
    required this.onToggle,
    required this.vitalities,
    required this.onShowDetails,
  });

  static const Key slotLifeKey = ValueKey('companion-slot-life');

  final List<OwnedPet> owned;

  /// Compagno nello slot: quello al fianco, o quello in attesa nell'overlay.
  final Pet? displayed;

  /// Compagno dell'operazione in corso; null = nessuna.
  final String? pendingPetId;
  final double cardSize;
  final ValueChanged<String> onToggle;
  final CompanionVitalityState vitalities;
  final ValueChanged<String> onShowDetails;

  @override
  Widget build(BuildContext context) {
    final displayedOwned = _ownedOf(displayed?.id);
    final slotLife = _slotLifeLine();
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompanionSlot(
            pet: displayed,
            name: displayedOwned?.name,
            level: displayedOwned?.level,
            isPending: pendingPetId != null,
            cardSize: cardSize,
            onTap: onToggle,
            onLongPress: onShowDetails,
          ),
          if (slotLife != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                slotLife,
                key: slotLifeKey,
                style: KlimmeckGuideTheme.instance.bodyMedium,
              ),
            ),
          if (owned.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                noOwnedCompanionsLine,
                style: KlimmeckGuideTheme.instance.bodyMedium,
              ),
            ),
          for (final entry in owned)
            OwnedCompanionRow(
              key: ValueKey(entry.pet.id),
              owned: entry,
              vitality: vitalities.vitalityOf(entry.pet.id),
              potionWait: vitalities.potionWaitOf(entry.pet.id),
              isDisplayed: entry.pet.id == displayed?.id,
              isPending: entry.pet.id == pendingPetId,
              cardSize: cardSize,
              onTap: () => onToggle(entry.pet.id),
              onLongPress: () => onShowDetails(entry.pet.id),
            ),
        ],
      ),
    );
  }

  OwnedPet? _ownedOf(String? petId) {
    if (petId == null) return null;
    for (final entry in owned) {
      if (entry.pet.id == petId) return entry;
    }
    return null;
  }

  String? _slotLifeLine() {
    final petId = displayed?.id;
    if (petId == null) return null;
    final vitality = vitalities.vitalityOf(petId);
    if (vitality == null) return null;
    return companionLifeLine(vitality.life, vitality.maxLifePoints);
  }
}
