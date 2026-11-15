import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info.dart';
import 'package:klimmeck_guide/shared/components/popup/details_sheet_frame.dart';

/// Foglio di dettaglio del compagno (D-22) sulla cornice condivisa: il
/// segnalibro rosso è l'interruttore equip/disequip solo quando [isEquipped]
/// è dato; il cambio nome solo con [onRename] (D-19).
class CompanionInfoSheet extends StatelessWidget {
  const CompanionInfoSheet({
    super.key,
    required this.pet,
    this.name,
    this.level,
    this.xp,
    this.vitality,
    this.potionWait,
    this.isEquipped,
    this.isPending = false,
    this.onToggle,
    this.onRename,
  });

  final Pet pet;
  final String? name;
  final int? level;
  final int? xp;
  final CompanionVitality? vitality;
  final Duration? potionWait;
  final bool? isEquipped;
  final bool isPending;
  final VoidCallback? onToggle;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) => DetailsSheetFrame(
    cardBuilder: (size) =>
        CompanionCard(pet: pet, size: size, name: name, level: level),
    body: CompanionInfo(
      pet: pet,
      name: name,
      level: level,
      xp: xp,
      vitality: vitality,
      potionWait: potionWait,
      onRename: onRename,
    ),
    isMarked: isEquipped,
    isPending: isPending,
    onToggle: onToggle,
  );
}
