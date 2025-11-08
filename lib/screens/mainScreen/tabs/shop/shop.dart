import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/edit_pencil_rubber.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';

import '../../../../models/character/character.dart';
import '../../../../shared/components/cached_svg.dart';
import '../../../../shared/components/coins_display.dart';
import '../../../../shared/components/popup/equipment_info_display.dart';
import '../../../../theme/kg_theme.dart';
import '../../characterCubit/character_cubit.dart';
import 'components/shop_modal.dart';
import 'components/transaction_message_bubble.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> with SingleTickerProviderStateMixin {
  List<AssetQuantity> _allEquipments = [];
  List<AssetQuantity> _allItems = [];

  List<AssetQuantity> _itemsToSell = [];
  List<AssetQuantity> _itemsToBuy = [];

  bool? _isAdd;
  bool _showTransactionMessage = false;
  String _transactionMessage = "";

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    context.read<ShopCubit>().getData();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildCoinsDisplay() {
    return BlocSelector<CharacterCubit, CharacterState, Coins?>(
      selector: (state) {
        if (state is CharacterLoaded) {
          return state.character.status?.coins;
        }
        return null;
      },
      builder: (context, coins) {
        return Positioned(
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
                child: CoinsDisplay(
                  coins: coins,
                  height: MediaQuery.of(context).size.height / 4,
                  color: KlimmeckGuideTheme.parchment,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSelect(List<AssetQuantity> items, bool isBuy) {
    if (isBuy) {
      setState(() => _itemsToBuy = items);
    } else {
      setState(() => _itemsToSell = items);
    }
  }

  void _onConfirm(Coins total, bool isTotalPositive, Character character) {
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
      id: character.id,
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
    Character? character,
  ) {
    showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        bool? isAddLocal = _isAdd;
        EquipmentItem? selectedEquipmentLocal;

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
                    onSelect: (items) => _onSelect(items, isBuy),
                    onEquipmentInfo: (selectedEquip) {
                      setModalState(
                        () => selectedEquipmentLocal = selectedEquip,
                      );
                      _animationController.forward();
                    },
                    isAdd: isAddLocal,
                  ),
                ),
                EditPencilRubber(
                  isAdd: isAddLocal,
                  onToggle: (newIsAdd) {
                    setModalState(() => isAddLocal = newIsAdd);
                    setState(() => _isAdd = newIsAdd);
                  },
                ),
                EquipmentInfoSheetDisplay(
                  selectedEquipment: selectedEquipmentLocal,
                  animationController: _animationController,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showModalTransaction(Character? character) {
    if (character == null) return;

    showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        bool? isAddLocal = _isAdd;
        EquipmentItem? selectedEquipmentLocal;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              children: [
                PaperSheetModal(
                  child: TransactionModal(
                    itemsToSell: _itemsToSell,
                    itemsToBuy: _itemsToBuy,
                    onConfirm: (total, isTotalPositive) =>
                        _onConfirm(total, isTotalPositive, character),
                    onChangedList: (items, isBuy) {
                      _onSelect(items, isBuy);
                      if (_itemsToBuy.isEmpty && _itemsToSell.isEmpty) {
                        Navigator.of(context).pop();
                      }
                    },
                    onEquipmentInfo: (selectedEquip) {
                      setModalState(
                        () => selectedEquipmentLocal = selectedEquip,
                      );
                      _animationController.forward();
                    },
                    character: character,
                    isAdd: isAddLocal,
                  ),
                ),
                EditPencilRubber(
                  isAdd: isAddLocal,
                  onToggle: (newIsAdd) {
                    setModalState(() => isAddLocal = newIsAdd);
                    setState(() => _isAdd = newIsAdd);
                  },
                ),
                EquipmentInfoSheetDisplay(
                  selectedEquipment: selectedEquipmentLocal,
                  animationController: _animationController,
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionCubit, TransactionState>(
      listener: (context, state) {
        if (state is TransactionInitial) {
          setState(() => _showTransactionMessage = false);
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
          return BlocBuilder<CharacterCubit, CharacterState>(
            builder: (context, characterState) {
              final Character? character = (characterState is CharacterLoaded)
                  ? characterState.character
                  : null;

              if (character == null) {
                return const Center(child: CircularProgressIndicator());
              }

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
                    TransactionMessageBubble(message: _transactionMessage),

                  _buildCoinsDisplay(),

                  Positioned(
                    bottom: -10,
                    child: Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 1.5,
                        width: MediaQuery.of(context).size.width / 1.2,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Spacer(flex: 2),
                            GestureDetector(
                              onTap: () => _showModalShop(
                                _allEquipments,
                                _allItems,
                                true,
                                character,
                              ),
                              child: CachedSvg(
                                width: MediaQuery.of(context).size.width / 3.3,
                                height:
                                    MediaQuery.of(context).size.height / 1.7,
                                url:
                                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660789/buy_pqj7e9.svg",
                              ),
                            ),
                            const Spacer(),
                            if (_itemsToBuy.isNotEmpty ||
                                _itemsToSell.isNotEmpty)
                              GestureDetector(
                                onTap: () => _showModalTransaction(character),
                                child: CachedSvg(
                                  height:
                                      MediaQuery.of(context).size.height / 3.2,
                                  width: MediaQuery.of(context).size.width / 6,
                                  url:
                                      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683133/completeTransaction_kptwjx.svg",
                                ),
                              )
                            else
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 6,
                              ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showModalShop(
                                character.assets!.ownedEquipments!,
                                character.assets!.ownedItems!,
                                false,
                                character,
                              ),
                              child: SizedBox(
                                child: CachedSvg(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height:
                                      MediaQuery.of(context).size.height / 2.3,
                                  url:
                                      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660787/sell_x0fw5i.svg",
                                ),
                              ),
                            ),
                            const Spacer(flex: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
