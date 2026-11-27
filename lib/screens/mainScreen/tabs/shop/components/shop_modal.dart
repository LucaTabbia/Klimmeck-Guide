import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';

import '../../../../../models/enums/effect_type.dart';
import '../../../../../models/enums/equip_type.dart';
import '../../../../../shared/components/dropdown.dart';
import '../../../../../shared/components/modal/paper_sheet_modal.dart';

class ShopModal extends StatefulWidget {
  const ShopModal({
    super.key,
    required this.equipments,
    required this.items,
    this.pets = const [],
    required this.selection,
    required this.onSelect,
    required this.isBuy,
    required this.isAdd,
    required this.onEquipmentInfo,
    this.equippedPetId,
    this.wornEquipment,
    this.petNames = const {},
    this.onCompanionInfo,
  });

  final List<AssetQuantity> equipments;
  final List<AssetQuantity> items;
  final List<Pet> pets;
  final TradeSelection selection;
  final bool isBuy;
  final bool? isAdd;
  final void Function(TradeSelection) onSelect;
  final Function(EquipmentItem) onEquipmentInfo;

  /// Solo sul lato vendita: il compagno al fianco del personaggio (D-07).
  final String? equippedPetId;

  /// Solo sul lato vendita: gli equipaggiamenti indossati dal personaggio.
  final Equipment? wornEquipment;

  /// Solo sul lato vendita: nome scelto per id del compagno (D-20, Pitfall 9).
  final Map<String, String> petNames;

  /// Tocco prolungato su un compagno: apre il suo dettaglio (D-35).
  final void Function(Pet pet, String? name)? onCompanionInfo;

  @override
  State<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> {
  static const double _topMargin = 40;
  static const double _fixedHeight =
      _topMargin + PaperSheetModal.contentBottomMargin;
  static const double _headerHeight = 43;

  late TradeSelection _selection;

  Set<EquipType> _equipFilter = const {};
  Set<EffectType> _effectFilter = const {};

  bool isEquipOpen = false;
  bool isItemOpen = false;
  bool isPetOpen = false;

  @override
  void initState() {
    super.initState();
    _selection = widget.selection;
  }

  /// Un tipo sparito dalle liste esce dai filtri per sempre (D-23).
  @override
  void didUpdateWidget(ShopModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _equipFilter = retainedFilterSelections(
      _equipFilter,
      presentEquipTypes(widget.equipments),
    );
    _effectFilter = retainedFilterSelections(
      _effectFilter,
      presentEffectTypes(widget.items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 200) / 5;

    final equipTypes = presentEquipTypes(widget.equipments);
    final equipFilter = retainedFilterSelections(_equipFilter, equipTypes);
    final effectTypes = presentEffectTypes(widget.items);
    final effectFilter = retainedFilterSelections(_effectFilter, effectTypes);

    final filteredEquipments = widget.equipments
        .where(
          (e) => matchesFilterSelection(
            equipFilter,
            e.item?.asEquipment?.equipType,
          ),
        )
        .toList();

    final filteredItems = widget.items
        .where(
          (i) => matchesFilterSelection(effectFilter, i.item?.asLoot?.effect),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: _topMargin),
                Dropdown(
                  key: const ValueKey('armor_dropdown'),
                  sectionName: "Armatura",
                  maxHeight: _dropdownHeight(constraints),
                  onToggle: () => setState(() {
                    isEquipOpen = !isEquipOpen;
                  }),
                  pinned: equipTypes.isEmpty
                      ? null
                      : ItemsFilter<EquipType>(
                          values: equipTypes,
                          selected: equipFilter,
                          onChanged: (selected) =>
                              setState(() => _equipFilter = selected),
                          getImage: (value) => value.imagePath,
                        ),
                  data: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(filteredEquipments.length, (index) {
                        final selectedAsset = _selection.assets
                            .firstWhereOrNull(
                              (q) =>
                                  q.item?.id ==
                                  filteredEquipments[index].item!.id,
                            );

                        return ItemRow(
                          key: ValueKey(filteredEquipments[index].item!.id),
                          assetItem: filteredEquipments[index].item!,
                          size: itemSize,
                          isBuy: widget.isBuy,
                          onLongTap: (selectedEquip) =>
                              widget.onEquipmentInfo(selectedEquip),
                          quantity: selectedAsset?.quantity,
                          isSelected: _isWorn(filteredEquipments[index])
                              ? true
                              : null,
                          onSelect: (item) => _onSelect(
                            item as EquipmentItem,
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
                  maxHeight: _dropdownHeight(constraints),
                  onToggle: () => setState(() {
                    isItemOpen = !isItemOpen;
                  }),
                  pinned: effectTypes.isEmpty
                      ? null
                      : ItemsFilter<EffectType>(
                          values: effectTypes,
                          selected: effectFilter,
                          onChanged: (selected) =>
                              setState(() => _effectFilter = selected),
                          getImage: (value) => value.imagePath,
                        ),
                  data: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(filteredItems.length, (index) {
                        final selectedAsset = _selection.assets
                            .firstWhereOrNull(
                              (q) =>
                                  q.item?.id == filteredItems[index].item!.id,
                            );

                        return ItemRow(
                          key: ValueKey(filteredItems[index].item!.id),
                          assetItem: filteredItems[index].item!,
                          size: itemSize,
                          isBuy: widget.isBuy,
                          quantity: selectedAsset?.quantity,
                          onSelect: (item) => _onSelect(
                            item as LootItem,
                            widget.isAdd,
                            widget.items,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (widget.pets.isNotEmpty)
                  Dropdown(
                    key: const ValueKey('companions_dropdown'),
                    sectionName: 'Compagni',
                    maxHeight: _dropdownHeight(constraints),
                    onToggle: () => setState(() => isPetOpen = !isPetOpen),
                    data: Column(
                      children: [
                        for (final pet in widget.pets)
                          _buildCompanionRow(pet, itemSize),
                      ],
                    ),
                  ),
                const SizedBox(height: PaperSheetModal.contentBottomMargin),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Il segnalibro rosso del Diario segna gli equipaggiamenti indossati.
  bool _isWorn(AssetQuantity owned) {
    final id = owned.item?.id;
    if (id == null) return false;
    return widget.wornEquipment?.slotsWearing(id).isNotEmpty ?? false;
  }

  Widget _buildCompanionRow(Pet pet, double size) {
    final name = widget.isBuy ? null : widget.petNames[pet.id];
    final onCompanionInfo = widget.onCompanionInfo;
    return CompanionRow(
      key: ValueKey('shop-pet-${pet.id}'),
      pet: pet,
      size: size,
      isBuy: widget.isBuy,
      name: name,
      isEquipped: pet.id == widget.equippedPetId,
      isSelected: _selection.containsPet(pet.id),
      onTap: () => _onTapPet(pet),
      onLongPress: onCompanionInfo == null
          ? null
          : () => onCompanionInfo(pet, name),
    );
  }

  /// Altezza divisa fra i menu aperti, al netto delle testate dei menu
  /// chiusi (Pitfall 5): con tre menu nessuna combinazione sborda.
  double _dropdownHeight(BoxConstraints constraints) {
    final openStates = [
      isEquipOpen,
      isItemOpen,
      if (widget.pets.isNotEmpty) isPetOpen,
    ];
    final openCount = openStates.where((isOpen) => isOpen).length;
    final closedCount = openStates.length - openCount;
    final reserved = _fixedHeight + _headerHeight * math.max(1, closedCount);
    return (constraints.maxHeight - reserved) / math.max(1, openCount);
  }

  void _onSelect(AssetItem item, bool? isAdd, List<AssetQuantity> ownedItems) {
    if (isAdd == null) return;
    final List<AssetQuantity> updatedSelectedItems = List.from(
      _selection.assets,
    );
    final index = updatedSelectedItems.indexWhere((q) => q.item?.id == item.id);

    final owned = !widget.isBuy
        ? ownedItems.firstWhere(
            (ownedItem) => ownedItem.item?.id == item.id,
            orElse: () => AssetQuantity(item: item, quantity: 0),
          )
        : null;

    if (index != -1) {
      final selected = updatedSelectedItems[index];
      final newQty = (selected.quantity ?? 0) + (isAdd ? 1 : -1);
      final canUpdate = widget.isBuy || newQty <= (owned?.quantity ?? 0);
      if (!canUpdate) {
        return;
      }

      if (newQty > 0) {
        final newSelected = selected.copyWith(quantity: newQty);
        updatedSelectedItems[index] = newSelected;
      } else {
        updatedSelectedItems.removeAt(index);
      }
    } else if (isAdd) {
      updatedSelectedItems.add(AssetQuantity(item: item, quantity: 1));
    }
    _update(_selection.withAssets(updatedSelectedItems));
  }

  void _onTapPet(Pet pet) {
    final isAdd = widget.isAdd;
    if (isAdd == null) return;
    _update(isAdd ? _selection.addPet(pet) : _selection.removePet(pet.id));
  }

  void _update(TradeSelection selection) {
    setState(() => _selection = selection);
    widget.onSelect(_selection);
  }
}
