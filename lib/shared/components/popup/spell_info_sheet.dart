import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/popup/details_sheet_frame.dart';
import 'package:klimmeck_guide/shared/components/spell_info.dart';

/// Foglio di dettaglio della magia (D-09) sulla cornice condivisa dei fogli di
/// dettaglio: il segnalibro rosso è l'interruttore equip/disequip.
class SpellInfoSheet extends StatelessWidget {
  const SpellInfoSheet({
    super.key,
    required this.spell,
    required this.usages,
    required this.recovery,
    required this.isActive,
    required this.isPending,
    this.onToggle,
  });

  final Spell spell;
  final int? usages;
  final SpellRecoveryStatus recovery;
  final bool isActive;
  final bool isPending;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) => DetailsSheetFrame(
    cardBuilder: (size) => SpellCard(spell: spell, size: size),
    body: SpellInfo(spell: spell, usages: usages, recovery: recovery),
    isMarked: isActive,
    isPending: isPending,
    onToggle: onToggle,
  );
}
