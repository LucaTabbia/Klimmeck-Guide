import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';

import '../../models/asset_item.dart';
import '../../models/equipment_item.dart';
import '../../models/spell.dart';
import '../../theme/kg_theme.dart';

class SpellRow extends StatelessWidget {
  const SpellRow({
    super.key,
    required this.spell,
    this.onSelect,
    this.isSelected,
    required this.size,
    this.usages,
    this.onLongTap,
  });

  final int? usages;
  final double size;
  final Spell spell;
  final bool? isSelected;
  final Function(AssetItem)? onSelect;
  final Function(EquipmentItem)? onLongTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SpellCard(spell: spell, size: size, usages: usages),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              spell.description!,
              style: KlimmeckGuideTheme.instance.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
