import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_resist.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/spell_lines.dart';

/// Riga degli slot (D-10, D-11): esattamente `slots.length` box; zero slot = riga neutra.
class SpellSlotRow extends StatelessWidget {
  const SpellSlotRow({
    super.key,
    required this.slots,
    required this.cardSize,
    required this.onTap,
    required this.onLongPress,
    this.resistSignal,
  });

  final List<SpellSlot> slots;
  final double cardSize;
  final ValueChanged<String> onTap;
  final ValueChanged<Spell> onLongPress;
  final SpellResistSignal? resistSignal;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Text(
        noSpellSlotsLine,
        style: KlimmeckGuideTheme.instance.bodyMedium,
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < slots.length; index++)
          _buildBox(index, slots[index]),
      ],
    );
  }

  Widget _buildBox(int index, SpellSlot slot) {
    final spell = slot.spell;
    return Container(
      key: ValueKey('spell-slot-box-$index'),
      height: cardSize,
      width: cardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(KlimmeckGuideTheme.radius),
        ),
        border: Border.all(color: KlimmeckGuideTheme.deepNight, width: 2),
      ),
      child: spell == null ? null : _buildFilled(slot, spell),
    );
  }

  Widget _buildFilled(SpellSlot slot, Spell spell) => GestureDetector(
    key: ValueKey('spell-slot-${spell.id}'),
    behavior: HitTestBehavior.opaque,
    onTap: () => onTap(spell.id),
    onLongPress: () => onLongPress(spell),
    child: SpellResist(
      trigger: resistTriggerFor(resistSignal, spell.id),
      child: AnimatedOpacity(
        opacity: slot.isPending ? KlimmeckGuideTheme.pendingInkOpacity : 1,
        duration: KlimmeckGuideTheme.pendingInkDuration,
        child: SpellCard(spell: spell, size: cardSize, usages: slot.usages),
      ),
    ),
  );
}
