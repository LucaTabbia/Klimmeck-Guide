import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Lo slot del compagno (D-10, D-17): un solo box, vuoto quando nessuno è al
/// fianco; il tocco sulla pergamena lo toglie. In attesa la pergamena sbiadisce.
class CompanionSlot extends StatelessWidget {
  const CompanionSlot({
    super.key,
    required this.pet,
    required this.isPending,
    required this.cardSize,
    required this.onTap,
  });

  final Pet? pet;
  final bool isPending;
  final double cardSize;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final displayed = pet;
    return Container(
      key: const ValueKey('companion-slot-box'),
      height: cardSize,
      width: cardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(KlimmeckGuideTheme.radius),
        ),
        border: Border.all(color: KlimmeckGuideTheme.deepNight, width: 2),
      ),
      child: displayed == null ? null : _buildFilled(displayed),
    );
  }

  Widget _buildFilled(Pet pet) => GestureDetector(
    key: ValueKey('companion-slot-${pet.id}'),
    behavior: HitTestBehavior.opaque,
    onTap: () => onTap(pet.id),
    child: AnimatedOpacity(
      opacity: isPending ? KlimmeckGuideTheme.pendingInkOpacity : 1,
      duration: KlimmeckGuideTheme.pendingInkDuration,
      child: CompanionCard(pet: pet, size: cardSize),
    ),
  );
}
