import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_resist.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/spell_lines.dart';

/// Riga di una magia conosciuta (D-13, D-14): carta senza contatore (gli usi
/// sono nella riga compatta), descrizione, riga compatta; segnalibro se attiva.
class KnownSpellRow extends StatelessWidget {
  const KnownSpellRow({
    super.key,
    required this.entry,
    required this.recovery,
    required this.cardSize,
    required this.onTap,
    required this.onLongPress,
    this.resistTrigger,
  });

  final SpellbookEntry entry;
  final SpellRecoveryStatus recovery;
  final double cardSize;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int? resistTrigger;

  @override
  Widget build(BuildContext context) {
    final spell = entry.spell;
    final description = spell.description;
    final textStyle = KlimmeckGuideTheme.instance.bodyMedium;
    return GestureDetector(
      key: ValueKey('spell-row-${spell.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: SpellResist(
        trigger: resistTrigger,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              AnimatedOpacity(
                opacity: entry.isPending
                    ? KlimmeckGuideTheme.pendingInkOpacity
                    : 1,
                duration: KlimmeckGuideTheme.pendingInkDuration,
                child: SpellCard(
                  spell: spell,
                  size: cardSize,
                  isMarked: entry.isActive,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description != null)
                        Text(description, style: textStyle),
                      Text(
                        spellSummaryLine(
                          spell: spell,
                          usages: entry.usages,
                          recovery: recovery,
                        ),
                        style: textStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
