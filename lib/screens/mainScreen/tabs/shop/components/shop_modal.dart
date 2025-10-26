import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/items_filter.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';

import '../../../../../models/enums/effect_type.dart';
import '../../../../../models/enums/equip_type.dart';
import '../../../../../shared/components/dropdown.dart';

class ShopModal extends StatefulWidget {
  const ShopModal({
    super.key,
    required this.equipments,
    required this.items,
    required this.onSelect,
    required this.selectedItems,
    required this.isBuy,
    required this.isAdd,
  });

  final List<AssetQuantity> equipments;
  final List<AssetQuantity> items;
  final List<AssetQuantity> selectedItems;
  final bool isBuy;
  final bool? isAdd;
  final Function(List<AssetQuantity>) onSelect;

  @override
  State<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> {
  late List<AssetQuantity> selectedItems;

  EquipType? selectedEquipFilter;
  EffectType? selectedEffectFilter;

  bool isEquipOpen = false;
  bool isItemOpen = false;

  @override
  void initState() {
    setState(() {
      selectedItems = widget.selectedItems;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 200) / 5;

    final filteredEquipments = selectedEquipFilter == null
        ? widget.equipments
        : widget.equipments
              .where(
                (e) =>
                    (e.item! as EquipmentItem).equipType == selectedEquipFilter,
              )
              .toList();

    final filteredItems = selectedEffectFilter == null
        ? widget.items
        : widget.items
              .where((i) => (i.item as LootItem).effect == selectedEffectFilter)
              .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 40),
            Dropdown(
              key: const ValueKey('armor_dropdown'),
              sectionName: "Armatura",
              maxHeight: isEquipOpen && isItemOpen
                  ? (constraints.maxHeight - (180 + 43)) / 2
                  : constraints.maxHeight - (180 + 43),
              onToggle: () => setState(() {
                isEquipOpen = !isEquipOpen;
              }),
              data: Column(
                children: [
                  ItemsFilter(
                    values: EquipType.values,
                    current: selectedEquipFilter,
                    onTap: (value) => setState(() {
                      selectedEquipFilter = value;
                    }),
                    getImage: (EquipType value) => value.imagePath,
                  ),
                  ...List.generate(filteredEquipments.length, (index) {
                    final selectedAsset = selectedItems.firstWhereOrNull(
                      (q) => q.item?.id == filteredEquipments[index].item!.id,
                    );

                    return ItemRow(
                      key: ValueKey(filteredEquipments[index].item!.id),
                      assetItem: filteredEquipments[index].item!,
                      size: itemSize,
                      isBuy: widget.isBuy,
                      quantity: selectedAsset?.quantity,
                      onSelect: () => _onSelect(
                        filteredEquipments[index].item!,
                        widget.isAdd,
                        widget.equipments,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Dropdown(
              key: const ValueKey('items_dropdown'),
              sectionName: "Oggetti",
              maxHeight: isEquipOpen && isItemOpen
                  ? (constraints.maxHeight - (180 + 43)) / 2
                  : constraints.maxHeight - (180 + 43),
              onToggle: () => setState(() {
                isItemOpen = !isItemOpen;
              }),
              data: Column(
                children: [
                  ItemsFilter(
                    values: EffectType.values,
                    current: selectedEffectFilter,
                    onTap: (value) => setState(() {
                      selectedEffectFilter = value;
                    }),
                    getImage: (EffectType value) => value.imagePath,
                  ),
                  ...List.generate(filteredItems.length, (index) {
                    final selectedAsset = selectedItems.firstWhereOrNull(
                      (q) => q.item?.id == filteredItems[index].item!.id,
                    );

                    return ItemRow(
                      key: ValueKey(filteredItems[index].item!.id),
                      assetItem: filteredItems[index].item!,
                      size: itemSize,
                      isBuy: widget.isBuy,
                      quantity: selectedAsset?.quantity,
                      onSelect: () => _onSelect(
                        filteredItems[index].item!,
                        widget.isAdd,
                        widget.items,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 140),
          ],
        );
      },
    );
  }

  void _onSelect(AssetItem item, bool? isAdd, List<AssetQuantity> ownedItems) {
    if (isAdd == null) return;

    final index = selectedItems.indexWhere((q) => q.item?.id == item.id);
    final owned = !widget.isBuy
        ? ownedItems.firstWhere(
            (ownedItem) => ownedItem.item?.id == item.id,
            orElse: () => AssetQuantity(item: item, quantity: 0),
          )
        : null;

    if (index != -1) {
      final selected = selectedItems[index];
      final newQty = (selected.quantity ?? 0) + (isAdd ? 1 : -1);

      final canUpdate = widget.isBuy || newQty <= (owned?.quantity ?? 0);

      if (!canUpdate) {
        return;
      }

      if (newQty > 0) {
        selected.quantity = newQty;
      } else {
        selectedItems.removeAt(index);
      }
    } else if (isAdd) {
      selectedItems.add(AssetQuantity(item: item, quantity: 1));
    }

    setState(() {});
    widget.onSelect(selectedItems);
  }
}
