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

import '../../../../../models/coins.dart';
import '../../../../../models/enums/column_layout_type.dart';
import '../../../../../shared/components/animated_pencil_text.dart';
import '../../../../../shared/components/dropdown.dart';

class TransactionModal extends StatefulWidget {
  const TransactionModal({
    super.key,
    required this.toBuy,
    required this.toSell,
    required this.onConfirm,
    required this.onChanged,
    required this.character,
    this.isAdd,
    required this.onEquipmentInfo,
  });

  final TradeSelection toBuy;
  final TradeSelection toSell;
  final void Function(Coins total, bool isTotalPositive) onConfirm;
  final void Function(TradeSelection selection, bool isBuy) onChanged;
  final Character character;
  final bool? isAdd;
  final void Function(EquipmentItem) onEquipmentInfo;

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  static const double _reservedHeight = 180 + 110 + 43;

  bool isBuyOpen = false;
  bool isSellOpen = false;
  bool _showSignature = false;

  late TradeSelection _toBuy;
  late TradeSelection _toSell;

  @override
  void initState() {
    super.initState();
    _toBuy = widget.toBuy;
    _toSell = widget.toSell;
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 200) / 5;
    final totalBuy = _toBuy.total(isBuy: true);
    final totalSell = _toSell.total(isBuy: false);
    final bool isPositive = totalSell > totalBuy;
    final int diffCopper = (totalSell.toCopper() - totalBuy.toCopper()).abs();
    final Coins total = Coins.fromCopper(diffCopper);
    final String sign = isPositive ? "+" : "-";

    /// Un saldo positivo non chiede monete: si firma sempre (D-14).
    final canAfford =
        isPositive || widget.character.status!.coins!.canAfford(total);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownHeight = isBuyOpen && isSellOpen
            ? (constraints.maxHeight - _reservedHeight) / 2
            : constraints.maxHeight - _reservedHeight;
        return Column(
          children: [
            const SizedBox(height: 40),
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
                              coins: total,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  height: 50,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AutoSizeText(
                      "Firma dell'acquirente:",
                      style: KlimmeckGuideTheme.instance.specialText,
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    if (canAfford && !_showSignature) {
                      setState(() {
                        _showSignature = !_showSignature;
                      });
                      Future.delayed(const Duration(milliseconds: 400), () {
                        widget.onConfirm(total, isPositive);
                      });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width / 3,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: KlimmeckGuideTheme.darkBronze,
                            ),
                          ),
                        ),
                      ),
                      if (_showSignature)
                        SizedBox(
                          height: 50,
                          width: MediaQuery.of(context).size.width / 3,
                          child: AnimatedPencilText(
                            key: ValueKey(
                              "signature_${widget.character.infos!.name!}",
                            ),
                            text: widget.character.infos!.name!,
                          ),
                        ),
                      if (!canAfford)
                        Positioned.fill(
                          child: CustomPaint(painter: _RedXPainter()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 140),
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
          CompanionRow(
            key: ValueKey('trade-pet-${pet.id}'),
            pet: pet,
            size: itemSize,
            isBuy: isBuy,
            onTap: () => _onTapPet(pet, isBuy),
          ),
      ],
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

class _RedXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
