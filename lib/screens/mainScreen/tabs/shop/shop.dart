import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/coins_column.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../models/coins.dart';
import '../../../../shared/components/modal/paper_sheet_modal.dart';
import 'components/shop_modal.dart';

class Shop extends StatefulWidget {
  const Shop({super.key, required this.character});

  final Character character;

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  List<AssetQuantity> _allEquipments = [];
  List<AssetQuantity> _allItems = [];

  List<AssetQuantity> _itemsToSell = [];
  List<AssetQuantity> _itemsToBuy = [];

  bool? _isAdd;
  bool _showTransactionMessage = false;
  String _transactionMessage = "";

  @override
  void initState() {
    context.read<ShopCubit>().getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        if (state is TransactionInitial) {
          setState(() {
            _showTransactionMessage = false;
          });
        }
        if (state is TransactionLoading) {
          setState(() {
            _showTransactionMessage = true;
            _transactionMessage = "Controllo che sia tutto in ordine";
          });
        }
        if (state is TransactionDone) {
          setState(() {
            _itemsToSell = [];
            _itemsToBuy = [];
            _transactionMessage =
                "Sempre felice di fare affari! Posso esserle ancora utile?";
          });
        }
        if (state is TransactionError) {
          setState(() {
            _transactionMessage = "Hmmm... Qualcosa non mi torna. Riproviamo?";
          });
        }
      },
      child: BlocConsumer<ShopCubit, ShopState>(
        listener: (context, state) {
          if (state is ShopLoadData) {
            setState(() {
              _allEquipments = state.equipmentItems;
              _allItems = state.lootItems;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  'assets/images/shopBackground.png',
                  fit: BoxFit.cover,
                ),
              ),
              if (_showTransactionMessage)
                Positioned(
                  top: 0,
                  left: MediaQuery.of(context).size.width / 10,
                  child: Stack(
                    children: [
                      CachedSvg(
                        url:
                            "https://res.cloudinary.com/dzuhywp53/image/upload/v1761422762/comic_balloon_grteoq.svg",
                        height: 200,
                        width: 200,
                      ),
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 50.0,
                            horizontal: 30,
                          ),
                          child: Center(
                            child: AutoSizeText(
                              _transactionMessage,
                              textAlign: TextAlign.center,
                              style: KlimmeckGuideTheme.instance.titleMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: 50,
                right: 50,
                child: Stack(
                  children: [
                    CachedSvg(
                      url:
                          "https://res.cloudinary.com/dzuhywp53/image/upload/v1761306735/emptySatchel_aqvk1y.svg",
                      height: MediaQuery.of(context).size.height / 2,
                      width: MediaQuery.of(context).size.width / 6,
                    ),
                    Positioned(
                      top: 35,
                      left: MediaQuery.of(context).size.width / 12,
                      child: CoinsColumn(
                        coins: widget.character.status!.coins,
                        height: MediaQuery.of(context).size.height / 4,
                        color: KlimmeckGuideTheme.parchment,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -10,
                child: Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height / 1.5,
                    width: MediaQuery.of(context).size.width / 1.2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Spacer(flex: 2),
                        GestureDetector(
                          onTap: () =>
                              _showModalShop(_allEquipments, _allItems, true),
                          child: CachedSvg(
                            width: MediaQuery.of(context).size.width / 3.3,
                            height: MediaQuery.of(context).size.height / 1.7,
                            url:
                                "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660789/buy_pqj7e9.svg",
                          ),
                        ),
                        Spacer(),
                        if (_itemsToBuy.isNotEmpty || _itemsToSell.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showModalTransaction(),
                            child: CachedSvg(
                              height: MediaQuery.of(context).size.height / 3.2,
                              width: MediaQuery.of(context).size.width / 6,
                              url:
                                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683133/completeTransaction_kptwjx.svg",
                            ),
                          ),
                        if (_itemsToBuy.isEmpty && _itemsToSell.isEmpty)
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 6,
                          ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _showModalShop(
                            widget.character.assets!.ownedEquipments!,
                            widget.character.assets!.ownedItems!,
                            false,
                          ),
                          child: SizedBox(
                            child: CachedSvg(
                              width: MediaQuery.of(context).size.width / 3,
                              height: MediaQuery.of(context).size.height / 2.3,
                              url:
                                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660787/sell_x0fw5i.svg",
                            ),
                          ),
                        ),
                        Spacer(flex: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void onSelect(List<AssetQuantity> items, bool isBuy) {
    if (isBuy) {
      setState(() {
        _itemsToBuy = items;
      });
    } else {
      setState(() {
        _itemsToSell = items;
      });
    }
  }

  void onConfirm(Coins total, bool isTotalPositive) {
    TransactionItems splitAssets(List<AssetQuantity> items) {
      final equipAssets = <AssetQuantityInput>[];
      final lootAssets = <AssetQuantityInput>[];

      for (final asset in items) {
        final itemId = asset.item?.id;
        if (itemId == null) continue;
        final input = AssetQuantityInput(
          item: itemId,
          quantity: asset.quantity ?? 0,
        );
        if (asset.item is EquipmentItem) {
          equipAssets.add(input);
        } else {
          lootAssets.add(input);
        }
      }

      return TransactionItems(equipAssets: equipAssets, lootAssets: lootAssets);
    }

    final soldItems = splitAssets(_itemsToSell);
    final boughtItems = splitAssets(_itemsToBuy);

    final request = TransactionRequest(
      id: widget.character.id,
      boughtItems: boughtItems,
      soldItems: soldItems,
      isTotalPositive: isTotalPositive,
      total: total,
    );

    context.read<TransactionCubit>().doTransaction(request);
    Navigator.pop(context);
  }

  void _showModalShop(
    List<AssetQuantity> equipments,
    List<AssetQuantity> items,
    bool isBuy,
  ) {
    showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        bool? isAddLocal = _isAdd;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              children: [
                PaperSheetModal(
                  child: ShopModal(
                    equipments: equipments,
                    items: items,
                    selectedItems: isBuy ? _itemsToBuy : _itemsToSell,
                    isBuy: isBuy,
                    onSelect: (items) => onSelect(items, isBuy),
                    isAdd: isAddLocal,
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  bottom: 150,
                  left: isAddLocal == true ? 0 : -80,
                  child: GestureDetector(
                    onTap: () {
                      if (isAddLocal == true) {
                        setModalState(() => isAddLocal = null);
                        setState(() => _isAdd = null);
                      } else {
                        setModalState(() => isAddLocal = true);
                        setState(() => _isAdd = true);
                      }
                    },
                    child: SizedBox(
                      height: 150,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: SvgPicture.network(
                          "https://res.cloudinary.com/dzuhywp53/image/upload/v1761320846/pencil_wpysez.svg",
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  bottom: 0,
                  left: isAddLocal == false ? 0 : -80,
                  child: GestureDetector(
                    onTap: () {
                      if (isAddLocal == false) {
                        setModalState(() => isAddLocal = null);
                        setState(() => _isAdd = null);
                      } else {
                        setModalState(() => isAddLocal = false);
                        setState(() => _isAdd = false);
                      }
                    },
                    child: SizedBox(
                      height: 150,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: SvgPicture.network(
                          "https://res.cloudinary.com/dzuhywp53/image/upload/v1761320949/rubber_bnonlz.svg",
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showModalTransaction() {
    showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        bool? isAddLocal = _isAdd;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              children: [
                PaperSheetModal(
                  child: TransactionModal(
                    itemsToSell: _itemsToSell,
                    itemsToBuy: _itemsToBuy,
                    onConfirm: (total, isTotalPositive) =>
                        onConfirm(total, isTotalPositive),
                    onChangedList: (items, isBuy) => {
                      onSelect(items, isBuy),
                      if (_itemsToBuy.isEmpty && _itemsToSell.isEmpty)
                        {Navigator.of(context).pop()},
                    },
                    character: widget.character,
                    isAdd: isAddLocal,
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  bottom: 150,
                  left: isAddLocal == true ? 0 : -80,
                  child: GestureDetector(
                    onTap: () {
                      if (isAddLocal == true) {
                        setModalState(() => isAddLocal = null);
                        setState(() => _isAdd = null);
                      } else {
                        setModalState(() => isAddLocal = true);
                        setState(() => _isAdd = true);
                      }
                    },
                    child: SizedBox(
                      height: 150,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: SvgPicture.network(
                          "https://res.cloudinary.com/dzuhywp53/image/upload/v1761320846/pencil_wpysez.svg",
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  bottom: 0,
                  left: isAddLocal == false ? 0 : -80,
                  child: GestureDetector(
                    onTap: () {
                      if (isAddLocal == false) {
                        setModalState(() => isAddLocal = null);
                        setState(() => _isAdd = null);
                      } else {
                        setModalState(() => isAddLocal = false);
                        setState(() => _isAdd = false);
                      }
                    },
                    child: SizedBox(
                      height: 150,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: SvgPicture.network(
                          "https://res.cloudinary.com/dzuhywp53/image/upload/v1761320949/rubber_bnonlz.svg",
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
