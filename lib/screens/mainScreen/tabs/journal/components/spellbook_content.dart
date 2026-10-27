import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/known_spell_row.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_resist.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_slot_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/spell_lines.dart';

/// Contenuto della sezione Magie (D-10..D-15): riga degli slot e lista nell'ordine del BE.
class SpellbookContent extends StatelessWidget {
  const SpellbookContent({
    super.key,
    required this.spellbook,
    required this.recoveries,
    required this.cardSize,
    required this.onToggle,
    required this.onShowDetails,
    this.resistSignal,
  });

  final Spellbook spellbook;

  /// Stato del recupero per id magia; un id assente vale [SpellRecoveryFull].
  final Map<String, SpellRecoveryStatus> recoveries;
  final double cardSize;
  final ValueChanged<String> onToggle;
  final ValueChanged<Spell> onShowDetails;
  final SpellResistSignal? resistSignal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpellSlotRow(
          slots: spellbook.slots,
          cardSize: cardSize,
          onTap: onToggle,
          onLongPress: onShowDetails,
          resistSignal: resistSignal,
        ),
        if (spellbook.entries.isEmpty)
          Text(
            noKnownSpellsLine,
            style: KlimmeckGuideTheme.instance.bodyMedium,
          ),
        for (final entry in spellbook.entries) _buildRow(entry),
      ],
    ),
  );

  Widget _buildRow(SpellbookEntry entry) {
    final spell = entry.spell;
    return KnownSpellRow(
      key: ValueKey(spell.id),
      entry: entry,
      recovery: recoveries[spell.id] ?? const SpellRecoveryFull(),
      cardSize: cardSize,
      onTap: () => onToggle(spell.id),
      onLongPress: () => onShowDetails(spell),
      resistTrigger: resistTriggerFor(resistSignal, spell.id),
    );
  }
}
