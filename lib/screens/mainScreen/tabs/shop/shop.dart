import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/edit_pencil_rubber.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart';
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
  const Shop({super.key, required this.cities});

  final List<City> cities;

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> with SingleTickerProviderStateMixin {
  TradeSelection _toBuy = const TradeSelection();
  TradeSelection _toSell = const TradeSelection();

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

  void _onSelect(TradeSelection selection, bool isBuy) {
    setState(() {
      if (isBuy) {
        _toBuy = selection;
      } else {
        _toSell = selection;
      }
    });
  }

  /// Comprare non equipaggia mai (D-08): i compagni viaggiano solo in
  /// `petAssets` del lato giusto.
  void _onConfirm(Coins total, bool isTotalPositive, Character character) {
    context.read<TransactionCubit>().doTransaction(
      buildTransactionRequest(
        characterId: character.id,
        bought: _toBuy,
        sold: _toSell,
        total: total,
        isTotalPositive: isTotalPositive,
      ),
    );
    Navigator.pop(context);
  }

  /// Il foglio d'acquisto legge il pool dal vivo (D-03): aperto durante il
  /// caricamento si riempie all'arrivo; un pool fallito si richiede al tocco
  /// (azione esplicita, regola 2). Il foglio vive sopra i provider della shell:
  /// i cubit si catturano prima di aprirlo.
  void _openBuySheet(Character character) {
    final shopCubit = context.read<ShopCubit>();
    final characterCubit = context.read<CharacterCubit>();
    _retryFailedPool(shopCubit, character);
    _showModalShop(
      isBuy: true,
      stockOf: (buildModal) => BlocBuilder<ShopCubit, ShopState>(
        bloc: shopCubit,
        builder: (_, state) => BlocBuilder<CharacterCubit, CharacterState>(
          bloc: characterCubit,
          builder: (_, characterState) =>
              buildModal(_buyStock(state, characterState)),
        ),
      ),
    );
  }

  void _openSellSheet(Character character) {
    _showModalShop(
      isBuy: false,
      stockOf: (buildModal) => buildModal(_sellStock(character)),
    );
  }

  void _retryFailedPool(ShopCubit shopCubit, Character character) {
    final cityId = _cityIdOf(character);
    final state = shopCubit.state;
    if (cityId == null || state is! ShopError || state.cityId != cityId) {
      return;
    }
    shopCubit.getData(cityId);
  }

  _SheetStock _buyStock(ShopState state, CharacterState characterState) {
    if (characterState is! CharacterLoaded) return const _SheetStock();
    final character = characterState.character;
    final pool = _poolOf(state, character);
    return _SheetStock(
      equipments: pool?.equipment ?? const [],
      items: pool?.loot ?? const [],
      pets: purchasablePets(
        pool?.pets ?? const [],
        character.assets?.ownedPets ?? const [],
      ),
    );
  }

  _SheetStock _sellStock(Character character) => _SheetStock(
    equipments: character.assets?.ownedEquipments ?? const [],
    items: character.assets?.ownedItems ?? const [],
    pets: character.assets?.ownedPets ?? const [],
    equippedPetId: character.assets?.pet?.id,
  );

  void _showModalShop({
    required bool isBuy,
    required Widget Function(Widget Function(_SheetStock stock) buildModal)
    stockOf,
  }) {
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
                  child: stockOf(
                    (stock) => ShopModal(
                      equipments: stock.equipments,
                      items: stock.items,
                      pets: stock.pets,
                      equippedPetId: stock.equippedPetId,
                      selection: isBuy ? _toBuy : _toSell,
                      isBuy: isBuy,
                      onSelect: (selection) => _onSelect(selection, isBuy),
                      onEquipmentInfo: (selectedEquip) {
                        setModalState(
                          () => selectedEquipmentLocal = selectedEquip,
                        );
                        _animationController.forward();
                      },
                      isAdd: isAddLocal,
                    ),
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
                    toBuy: _toBuy,
                    toSell: _toSell,
                    onConfirm: (total, isTotalPositive) =>
                        _onConfirm(total, isTotalPositive, character),
                    onChanged: (selection, isBuy) {
                      _onSelect(selection, isBuy);
                      if (_toBuy.isEmpty && _toSell.isEmpty) {
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

  void _showRefusal(TransactionFailure failure) {
    final line = shopkeeperRefusalLine(failure);
    _showTransactionMessage = line != null;
    _transactionMessage = line ?? '';
  }

  /// Solo il pool della città del marker (D-03): uno stato di un'altra città
  /// (cubit a livello di shell) o un caricamento in corso mostrano liste vuote.
  CityShop? _poolOf(ShopState state, Character character) {
    final cityId = _cityIdOf(character);
    return state is ShopLoadData && state.cityId == cityId ? state.pool : null;
  }

  String? _cityIdOf(Character character) =>
      currentCityOf(widget.cities, character.status?.location)?.id;

  @override
  Widget build(BuildContext context) {
    return ShopPoolLoader(cities: widget.cities, child: _buildPage());
  }

  Widget _buildPage() {
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
            _toBuy = const TradeSelection();
            _toSell = const TradeSelection();
            _transactionMessage =
                "Sempre felice di fare affari! Posso esserle ancora utile?";
          });
        }
        if (state is TransactionError) {
          setState(() => _showRefusal(state.failure));
        }
      },
      child: BlocListener<ShopCubit, ShopState>(
        listenWhen: (_, current) => current is ShopLoadData,
        listener: (context, state) => _pruneBuySelection(state),
        child: _buildShop(),
      ),
    );
  }

  /// Un nuovo pool della città del marker tiene nell'acquisto solo ciò che
  /// la città vende ancora (D-03).
  void _pruneBuySelection(ShopState state) {
    final characterState = context.read<CharacterCubit>().state;
    if (characterState is! CharacterLoaded) return;
    final pool = _poolOf(state, characterState.character);
    if (pool == null) return;
    setState(() => _toBuy = _toBuy.retainPurchasable(pool));
  }

  Widget _buildShop() {
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
                        onTap: () => _openBuySheet(character),
                        child: CachedSvg(
                          width: MediaQuery.of(context).size.width / 3.3,
                          height: MediaQuery.of(context).size.height / 1.7,
                          url:
                              "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660789/buy_pqj7e9.svg",
                        ),
                      ),
                      const Spacer(),
                      if (!_toBuy.isEmpty || !_toSell.isEmpty)
                        GestureDetector(
                          onTap: () => _showModalTransaction(character),
                          child: CachedSvg(
                            height: MediaQuery.of(context).size.height / 3.2,
                            width: MediaQuery.of(context).size.width / 6,
                            url:
                                "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683133/completeTransaction_kptwjx.svg",
                          ),
                        )
                      else
                        SizedBox(width: MediaQuery.of(context).size.width / 6),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openSellSheet(character),
                        child: SizedBox(
                          child: CachedSvg(
                            width: MediaQuery.of(context).size.width / 3,
                            height: MediaQuery.of(context).size.height / 2.3,
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
  }
}

/// Merce mostrata da un foglio del negozio.
class _SheetStock {
  const _SheetStock({
    this.equipments = const [],
    this.items = const [],
    this.pets = const [],
    this.equippedPetId,
  });

  final List<AssetQuantity> equipments;
  final List<AssetQuantity> items;
  final List<Pet> pets;
  final String? equippedPetId;
}
