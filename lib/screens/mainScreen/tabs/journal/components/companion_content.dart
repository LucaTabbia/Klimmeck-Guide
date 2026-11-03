import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/companion_slot.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/owned_companion_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Contenuto della sezione «Compagno» (D-17): lo slot in testa e le pergamene
/// dei posseduti nell'ordine del BE, come il libro delle magie.
class CompanionContent extends StatelessWidget {
  const CompanionContent({
    super.key,
    required this.owned,
    required this.displayed,
    required this.pendingPetId,
    required this.cardSize,
    required this.onToggle,
  });

  final List<Pet> owned;

  /// Compagno nello slot: quello al fianco, o quello in attesa nell'overlay.
  final Pet? displayed;

  /// Compagno dell'operazione in corso; null = nessuna.
  final String? pendingPetId;
  final double cardSize;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanionSlot(
          pet: displayed,
          isPending: pendingPetId != null,
          cardSize: cardSize,
          onTap: onToggle,
        ),
        if (owned.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              noOwnedCompanionsLine,
              style: KlimmeckGuideTheme.instance.bodyMedium,
            ),
          ),
        for (final pet in owned)
          OwnedCompanionRow(
            key: ValueKey(pet.id),
            pet: pet,
            isDisplayed: pet.id == displayed?.id,
            isPending: pet.id == pendingPetId,
            cardSize: cardSize,
            onTap: () => onToggle(pet.id),
          ),
      ],
    ),
  );
}
