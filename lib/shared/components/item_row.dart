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
    this.isDisabled = false,
    this.statusLine,
  });

  final int? quantity;
  final double size;
  final AssetItem assetItem;
  final bool isBuy;
  final bool showCoins;
  final bool? isSelected;
  final Function(AssetItem)? onSelect;
  final Function(EquipmentItem)? onLongTap;

  /// Riga spenta (D-12): la carta sbiadisce; chi chiama non passa `onSelect`.
  final bool isDisabled;

  /// Riga di stato sotto le altre (D-12), es. il conto alla rovescia.
  final String? statusLine;

  @override
  Widget build(BuildContext context) {
    final lootItem = assetItem.asLoot;
    final effectLine = lootItem == null ? null : itemEffectLabel(lootItem);
    final injuriesLine = lootItem == null ? null : healedInjuriesLine(lootItem);
    final recovery = lootItem == null ? null : recoveryLine(lootItem.recovery);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          AnimatedOpacity(
            key: ValueKey('item-card-opacity-${assetItem.id}'),
            opacity: isDisabled ? KlimmeckGuideTheme.pendingInkOpacity : 1,
            duration: KlimmeckGuideTheme.pendingInkDuration,
            child: assetItem.isEquipment
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
              child: _buildTexts(effectLine, injuriesLine, recovery),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTexts(
    String? effectLine,
    String? injuriesLine,
    String? recoveryText,
  ) {
    final style = KlimmeckGuideTheme.instance.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(assetItem.description, style: style),
        if (effectLine != null)
          Text(
            effectLine,
            key: ValueKey('item-effect-${assetItem.id}'),
            style: style,
          ),
        if (injuriesLine != null)
          Text(
            injuriesLine,
            key: ValueKey('item-injuries-${assetItem.id}'),
            style: style,
          ),
        if (recoveryText != null)
          Text(
            recoveryText,
            key: ValueKey('item-recovery-${assetItem.id}'),
            style: style,
          ),
        if (statusLine case final status?)
          Text(
            status,
            key: ValueKey('item-status-${assetItem.id}'),
            style: style,
          ),
      ],
    );
  }
}
