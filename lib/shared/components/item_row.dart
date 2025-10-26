import 'package:flutter/material.dart';

import '../../models/asset_item.dart';
import '../../models/equipment_item.dart';
import '../../models/loot_item.dart';
import '../../theme/kg_theme.dart';
import 'cards/equipment_item_card.dart';
import 'cards/loot_item_card.dart';
import 'coins_column.dart';

class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.assetItem,
    required this.onSelect,
    required this.isBuy,
    required this.size,
    this.quantity,
  });

  final int? quantity;
  final double size;
  final AssetItem assetItem;
  final bool isBuy;
  final Function onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          assetItem.runtimeType == EquipmentItem
              ? EquipmentItemCard(
                  key: ValueKey(assetItem.id),
                  onTap: _handleEquipmentTap,
                  quantity: quantity,
                  isSelected: true,
                  size: size,
                  equipmentItem: assetItem as EquipmentItem,
                )
              : LootItemCard(
                  key: ValueKey(assetItem.id),
                  onTap: _handleLootTap,
                  quantity: quantity,
                  isSelected: true,
                  size: size,
                  lootItem: assetItem as LootItem,
                ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CoinsColumn(
              coins: isBuy ? assetItem.buyPrice : assetItem.sellPrice,
              height: size,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                assetItem.description,
                style: KlimmeckGuideTheme.instance.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEquipmentTap(EquipmentItem item) {
    onSelect();
  }

  void _handleLootTap(LootItem item) {
    onSelect();
  }
}
