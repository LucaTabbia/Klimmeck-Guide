import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/utils.dart';

import '../../../../../models/coins.dart';
import '../../../../../models/enums/column_layout_type.dart';
import '../../../../../shared/components/animated_pencil_text.dart';
import '../../../../../shared/components/dropdown.dart';

class TransactionModal extends StatefulWidget {
  const TransactionModal({
    super.key,
    required this.itemsToSell,
    required this.itemsToBuy,
    required this.onConfirm,
    required this.onChangedList,
    required this.character,
    this.isAdd,
    required this.onEquipmentInfo,
  });

  final List<AssetQuantity> itemsToSell;
  final List<AssetQuantity> itemsToBuy;
  final Function(Coins, bool) onConfirm;
  final Character character;
  final bool? isAdd;
  final Function(List<AssetQuantity>, bool) onChangedList;
  final Function(EquipmentItem) onEquipmentInfo;

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  bool isBuyOpen = false;
  bool isSellOpen = false;
  bool _showSignature = false;

  late List<AssetQuantity> _finalItemsToSell;
  late List<AssetQuantity> _finalItemsToBuy;
  late Coins totalBuy;
  late Coins totalSell;

  @override
  void initState() {
    setState(() {
      _finalItemsToBuy = widget.itemsToBuy;
      _finalItemsToSell = widget.itemsToSell;
    });

    setState(() {
      totalBuy = getTotalAmount(_finalItemsToBuy, true);
      totalSell = getTotalAmount(_finalItemsToSell, false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 200) / 5;
    final bool isPositive = totalSell > totalBuy;
    final int diffCopper = (totalSell.toCopper() - totalBuy.toCopper()).abs();
    final Coins total = Coins.fromCopper(diffCopper);
    final String sign = isPositive ? "+" : "-";
    final canAfford = widget.character.status!.coins!.canAfford(total);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 40),
            Dropdown(
              key: const ValueKey('buy_dropdown'),
              sectionName: "Acquisto",
              maxHeight: isBuyOpen && isSellOpen
                  ? (constraints.maxHeight - (180 + 110 + 43)) / 2
                  : constraints.maxHeight - (180 + 110 + 43),
              onToggle: () => setState(() {
                isBuyOpen = !isBuyOpen;
              }),
              data: Column(
                children: [
                  ...List.generate(
                    _finalItemsToBuy.length,
                    (index) => ItemRow(
                      key: ValueKey(_finalItemsToBuy[index].item!.id),
                      assetItem: _finalItemsToBuy[index].item!,
                      size: itemSize,
                      isBuy: true,
                      onLongTap: (equipItem) =>
                          widget.onEquipmentInfo(equipItem),
                      quantity: _finalItemsToBuy[index].quantity,
                      onSelect: (item) => _onSelect(
                        _finalItemsToBuy[index],
                        widget.isAdd,
                        true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Dropdown(
              key: const ValueKey('sell_dropdown'),
              sectionName: "Vendita",
              maxHeight: isBuyOpen && isSellOpen
                  ? (constraints.maxHeight - (180 + 110 + 43)) / 2
                  : constraints.maxHeight - (180 + 110 + 43),
              onToggle: () => setState(() {
                isSellOpen = !isSellOpen;
              }),
              data: Column(
                children: [
                  ...List.generate(
                    _finalItemsToSell.length,
                    (index) => ItemRow(
                      key: ValueKey(_finalItemsToSell[index].item!.id),
                      assetItem: _finalItemsToSell[index].item!,
                      onLongTap: (equipItem) =>
                          widget.onEquipmentInfo(equipItem),
                      size: itemSize,
                      quantity: _finalItemsToSell[index].quantity,
                      isBuy: false,
                      onSelect: (item) => _onSelect(
                        _finalItemsToSell[index],
                        widget.isAdd,
                        false,
                      ),
                    ),
                  ),
                ],
              ),
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

  void _onSelect(AssetQuantity assetQuantity, bool? isAdd, bool isBuy) {
    if (isAdd == null) return;
    List<AssetQuantity> currentList = isBuy
        ? _finalItemsToBuy
        : _finalItemsToSell;
    List<AssetQuantity> updatedList = List.from(currentList);
    final price = isBuy
        ? assetQuantity.item!.buyPrice!
        : assetQuantity.item!.sellPrice!;

    if (isAdd) {
      if (isBuy) {
        totalBuy = totalBuy + price;
      } else {
        totalSell = totalSell + price;
      }
    } else {
      if (isBuy) {
        totalBuy = totalBuy - price;
      } else {
        totalSell = totalSell - price;
      }
    }

    final int index = updatedList.indexWhere(
      (q) => q.item?.id == assetQuantity.item!.id,
    );

    final newQty = (assetQuantity.quantity ?? 0) + (isAdd ? 1 : -1);

    if (newQty > 0) {
      final newAssetQuantity = assetQuantity.copyWith(quantity: newQty);
      updatedList[index] = newAssetQuantity;
    } else if (index != -1) {
      updatedList.removeAt(index);
    }

    if (isBuy) {
      _finalItemsToBuy = updatedList;
    } else {
      _finalItemsToSell = updatedList;
    }
    setState(() {});
    widget.onChangedList(isBuy ? _finalItemsToBuy : _finalItemsToSell, isBuy);
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
