import 'package:flutter/material.dart';

import '../../models/asset_item.dart';
import '../../models/equipment_item.dart';
import '../../theme/kg_theme.dart';
import '../../utils/item_lines.dart';
import 'cards/equipment_item_card.dart';
import 'cards/loot_item_card.dart';
import 'coins_display.dart';

class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.assetItem,
    this.onSelect,
    this.showCoins = true,
    this.isBuy = true,
    this.isSelected,
    required this.size,
    this.quantity,
    this.onLongTap,
  });

  final int? quantity;
  final double size;
  final AssetItem assetItem;
  final bool isBuy;
  final bool showCoins;
  final bool? isSelected;
  final Function(AssetItem)? onSelect;
  final Function(EquipmentItem)? onLongTap;

  @override
  Widget build(BuildContext context) {
    final lootItem = assetItem.asLoot;
    final effectLine = lootItem == null ? null : itemEffectLabel(lootItem);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          assetItem.isEquipment
              ? EquipmentItemCard(
                  key: ValueKey(assetItem.id),
                  onLongPress: (equip) => onLongTap?.call(equip),
                  onTap: (item) => onSelect?.call(item),
                  quantity: quantity,
                  isSelected: isSelected,
                  size: size,
                  equipmentItem: assetItem.asEquipment!,
                )
              : LootItemCard(
                  key: ValueKey(assetItem.id),
                  onTap: (item) => onSelect?.call(item),
                  quantity: quantity,
                  size: size,
                  lootItem: assetItem.asLoot!,
                ),
          if (showCoins)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CoinsDisplay(
                coins: isBuy ? assetItem.buyPrice : assetItem.sellPrice,
                height: size,
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildTexts(effectLine),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTexts(String? effectLine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          assetItem.description,
          style: KlimmeckGuideTheme.instance.bodyMedium,
        ),
        if (effectLine != null)
          Text(
            effectLine,
            key: ValueKey('item-effect-${assetItem.id}'),
            style: KlimmeckGuideTheme.instance.bodyMedium,
          ),
      ],
    );
  }
}
