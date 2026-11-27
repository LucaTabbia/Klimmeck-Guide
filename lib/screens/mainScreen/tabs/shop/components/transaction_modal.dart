import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../models/enums/column_layout_type.dart';
import '../../../../../shared/components/dropdown.dart';
import '../../../../../shared/components/modal/paper_sheet_modal.dart';

class TransactionModal extends StatefulWidget {
  const TransactionModal({
    super.key,
    required this.toBuy,
    required this.toSell,
    required this.onChanged,
    required this.character,
    this.isAdd,
    required this.onEquipmentInfo,
    this.onCompanionInfo,
  });

  final TradeSelection toBuy;
  final TradeSelection toSell;
  final void Function(TradeSelection selection, bool isBuy) onChanged;
  final Character character;
  final bool? isAdd;
  final void Function(EquipmentItem) onEquipmentInfo;

  /// Tocco prolungato su un compagno del carrello: apre il dettaglio (D-35).
  final void Function(Pet pet, String? name)? onCompanionInfo;

  static const Key totalKey = ValueKey('receipt_total');

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  static const double _topMargin = 40;
  static const double _totalRowHeight = 60;
  static const double _reservedHeight =
      _topMargin + PaperSheetModal.contentBottomMargin + _totalRowHeight + 43;

  bool isBuyOpen = false;
  bool isSellOpen = false;

  late TradeSelection _toBuy;
  late TradeSelection _toSell;

  /// Nomi scelti dei compagni posseduti, per il lato vendita (Pitfall 9).
  Map<String, String> get _sellNames =>
      widget.character.assets?.chosenPetNames ?? const {};

  @override
  void initState() {
    super.initState();
    _toBuy = widget.toBuy;
    _toSell = widget.toSell;
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 200) / 5;
    final balance = TradeBalance.of(bought: _toBuy, sold: _toSell);
    final isPositive = balance.isTotalPositive;
    final String sign = isPositive ? "+" : "-";

    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownHeight = isBuyOpen && isSellOpen
            ? (constraints.maxHeight - _reservedHeight) / 2
            : constraints.maxHeight - _reservedHeight;
        return Column(
          children: [
            const SizedBox(height: _topMargin),
            Dropdown(
              key: const ValueKey('buy_dropdown'),
              sectionName: "Acquisto",
              maxHeight: dropdownHeight,
              onToggle: () => setState(() {
                isBuyOpen = !isBuyOpen;
              }),
              data: _buildSelectionRows(_toBuy, itemSize, isBuy: true),
            ),
            Dropdown(
              key: const ValueKey('sell_dropdown'),
              sectionName: "Vendita",
              maxHeight: dropdownHeight,
              onToggle: () => setState(() {
                isSellOpen = !isSellOpen;
              }),
              data: _buildSelectionRows(_toSell, itemSize, isBuy: false),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: SizedBox(
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      height: 50,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          maxFontSize: 20,
                          textAlign: TextAlign.start,
                          "Valore Totale:",
                          style: KlimmeckGuideTheme.instance.specialText,
                        ),
                      ),
                    ),
                    Spacer(),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      height: 50,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: AutoSizeText(
                              sign,
                              maxFontSize: 24,
                              minFontSize: 12,
                              style: KlimmeckGuideTheme.instance.bodyMedium
                                  .copyWith(
                                    color: isPositive
                                        ? KlimmeckGuideTheme.mysticBlue
                                        : KlimmeckGuideTheme.bloodRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: CoinsDisplay(
                              key: TransactionModal.totalKey,
                              coins: balance.total,
                              height: 50,
                              layout: CoinLayoutType.row,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: PaperSheetModal.contentBottomMargin),
          ],
        );
      },
    );
  }

  Widget _buildSelectionRows(
    TradeSelection selection,
    double itemSize, {
    required bool isBuy,
  }) {
    final names = isBuy ? const <String, String>{} : _sellNames;
    return Column(
      children: [
        for (final asset in selection.assets)
          ItemRow(
            key: ValueKey(asset.item!.id),
            assetItem: asset.item!,
            size: itemSize,
            isBuy: isBuy,
            onLongTap: (equipItem) => widget.onEquipmentInfo(equipItem),
            quantity: asset.quantity,
            onSelect: (item) => _onSelect(asset, widget.isAdd, isBuy),
          ),
        for (final pet in selection.pets)
          _buildCompanionRow(pet, itemSize, isBuy: isBuy, name: names[pet.id]),
      ],
    );
  }

  Widget _buildCompanionRow(
    Pet pet,
    double size, {
    required bool isBuy,
    required String? name,
  }) {
    final onCompanionInfo = widget.onCompanionInfo;
    return CompanionRow(
      key: ValueKey('trade-pet-${pet.id}'),
      pet: pet,
      size: size,
      isBuy: isBuy,
      name: name,
      onTap: () => _onTapPet(pet, isBuy),
      onLongPress: onCompanionInfo == null
          ? null
          : () => onCompanionInfo(pet, name),
    );
  }

  void _onSelect(AssetQuantity assetQuantity, bool? isAdd, bool isBuy) {
    if (isAdd == null) return;
    final selection = isBuy ? _toBuy : _toSell;
    final updated = List<AssetQuantity>.from(selection.assets);
    final index = updated.indexWhere(
      (q) => q.item?.id == assetQuantity.item!.id,
    );
    final newQty = (assetQuantity.quantity ?? 0) + (isAdd ? 1 : -1);

    if (newQty > 0) {
      updated[index] = assetQuantity.copyWith(quantity: newQty);
    } else if (index != -1) {
      updated.removeAt(index);
    }
    _update(selection.withAssets(updated), isBuy);
  }

  /// Un compagno vale sempre uno: la matita non fa nulla, la gomma lo toglie.
  void _onTapPet(Pet pet, bool isBuy) {
    if (widget.isAdd != false) return;
    final selection = isBuy ? _toBuy : _toSell;
    _update(selection.removePet(pet.id), isBuy);
  }

  void _update(TradeSelection selection, bool isBuy) {
    setState(() {
      if (isBuy) {
        _toBuy = selection;
      } else {
        _toSell = selection;
      }
    });
    widget.onChanged(selection, isBuy);
  }
}
