import 'package:flutter/cupertino.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';

import '../../../../../shared/components/cards/equipment_item_card.dart';
import '../../../../../shared/components/dropdown.dart';
import '../../../../../shared/components/item_grid.dart';

class ShopModal extends StatefulWidget {
  const ShopModal({super.key, required this.equipments, required this.items});

  final List<EquipmentItem> equipments;
  final List<LootItem> items;

  @override
  State<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> {
  Coins currentTotal = Coins(gold: 0, silver: 0, copper: 0);

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 200) / 5;

    return Column(
      children: [
        const SizedBox(height: 40),
        Dropdown(
          key: const ValueKey('armor_dropdown'),
          sectionName: "Armatura",
          data: ItemGrid<EquipmentItem>(
            items: widget.equipments,
            size: itemSize,
            itemBuilder: _buildEquipmentCard,
          ),
        ),

        Dropdown(
          key: const ValueKey('items_dropdown'),
          sectionName: "Oggetti",
          data: ItemGrid<LootItem>(
            items: widget.items,
            size: itemSize,
            itemBuilder: _buildLootCard,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(EquipmentItem item, double size) {
    return EquipmentItemCard(
      key: ValueKey(item.id),
      onTap: _handleEquipmentTap,
      onLongPress: _handleEquipmentLongPress,
      isSelected: false,
      size: size,
      equipmentItem: item,
    );
  }

  Widget _buildLootCard(LootItem item, double size) {
    return LootItemCard(
      key: ValueKey(item.id),
      onTap: _handleLootTap,
      isSelected: true,
      size: size,
      lootItem: item,
    );
  }

  void _handleEquipmentTap(EquipmentItem item) {}

  void _handleEquipmentLongPress(EquipmentItem item) {}

  void _handleLootTap(LootItem item) {}
}
