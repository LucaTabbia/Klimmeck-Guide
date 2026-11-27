import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/config/companion_care.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/coins_pouch.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/counter_shadow.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/edit_pencil_rubber.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/utils/poke_streak.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/utils/shopkeeper_mood.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_name_sheet.dart';

import '../../../../models/character/character.dart';
import '../../../../shared/components/cached_svg.dart';
import '../../../../shared/components/popup/companion_details_route.dart';
import '../../../../shared/components/popup/equipment_info_display.dart';
import '../../characterCubit/character_cubit.dart';
import 'components/shop_modal.dart';
import 'components/transaction_message_bubble.dart';

class Shop extends StatefulWidget {
  const Shop({
    super.key,
    required this.cities,
    this.isCompanionNamingEnabled = companionCareEnabled,
  });

  final List<City> cities;

  /// Chiede un nome per ogni compagno comprato (D-18); spento fino al gate.
  final bool isCompanionNamingEnabled;

  /// Zona toccabile sopra il negoziante.
  static const Key shopkeeperKey = ValueKey('shopkeeper');

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> with SingleTickerProviderStateMixin {
  TradeSelection _toBuy = const TradeSelection();
  TradeSelection _toSell = const TradeSelection();

  /// Compagni della transazione in volo, presi alla consegna della
  /// sacchetta: il personaggio
  /// aggiornato può arrivare prima della risposta e togliere dal carrello i
  /// compagni appena comprati.
  List<Pet> _petsInFlight = const [];

  final PokeStreak _pokes = PokeStreak();

  /// Dieci tocchi di fila e il negoziante sbotta per qualche secondo.
  bool _isAnnoyed = false;
  Timer? _annoyedTimer;

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    super.initState();
  }

  /// Le scene del negoziante cambiano a ogni passo della transazione: già
  /// decodificate, lo sfondo non lampeggia.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final mood in ShopkeeperMood.values) {
      precacheImage(AssetImage(mood.background), context);
    }
  }

  @override
  void dispose() {
    _annoyedTimer?.cancel();
    _animationController.dispose();
    super.dispose();
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

  /// La sacchetta consegnata paga il carrello; una borsa che non basta la
  /// rifiuta il negoziante senza chiedere al server. Comprare non equipaggia
  /// mai (D-08): i compagni viaggiano solo in `petAssets` del lato giusto.
  void _pay(Character character) {
    final transactionCubit = context.read<TransactionCubit>();
    final balance = TradeBalance.of(bought: _toBuy, sold: _toSell);
    final purse = character.status?.coins ?? const Coins();
    if (!balance.isAffordableWith(purse)) {
      transactionCubit.refuseInsufficientFunds();
      return;
    }
    _petsInFlight = _toBuy.pets;
    transactionCubit.doTransaction(
      buildTransactionRequest(
        characterId: character.id,
        bought: _toBuy,
        sold: _toSell,
        total: balance.total,
        isTotalPositive: balance.isTotalPositive,
      ),
    );
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
      pets: purchasablePets(pool?.pets ?? const [], _ownedPetsOf(character)),
    );
  }

  _SheetStock _sellStock(Character character) => _SheetStock(
    equipments: character.assets?.ownedEquipments ?? const [],
    items: character.assets?.ownedItems ?? const [],
    pets: _ownedPetsOf(character),
    equippedPetId: character.assets?.pet?.id,
    wornEquipment: character.assets?.wornEquipment,
    petNames: character.assets?.chosenPetNames ?? const {},
  );

  void _showCompanionDetails(Pet pet, String? name) =>
      showCompanionDetails(context, pet: pet, name: name);

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
        /// Matita e gomma ripartono spente a ogni apertura del foglio.
        bool? isAddLocal;
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
                      wornEquipment: stock.wornEquipment,
                      petNames: stock.petNames,
                      onCompanionInfo: _showCompanionDetails,
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
                  onToggle: (newIsAdd) =>
                      setModalState(() => isAddLocal = newIsAdd),
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
        bool? isAddLocal;
        EquipmentItem? selectedEquipmentLocal;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              children: [
                PaperSheetModal(
                  child: TransactionModal(
                    toBuy: _toBuy,
                    toSell: _toSell,
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
                    onCompanionInfo: _showCompanionDetails,
                  ),
                ),
                EditPencilRubber(
                  isAdd: isAddLocal,
                  onToggle: (newIsAdd) =>
                      setModalState(() => isAddLocal = newIsAdd),
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
        if (state is TransactionDone) {
          final bought = _petsInFlight;
          _petsInFlight = const [];
          setState(() {
            _toBuy = const TradeSelection();
            _toSell = const TradeSelection();
          });
          _askNamesAfterFrame(bought);
        }
        if (state is TransactionError) _petsInFlight = const [];
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<ShopCubit, ShopState>(
            listenWhen: (_, current) => current is ShopLoadData,
            listener: (context, state) => _pruneBuySelection(state),
          ),
          BlocListener<CharacterCubit, CharacterState>(
            listenWhen: _ownedPetsChanged,
            listener: (context, state) =>
                _pruneOnOwnedPets((state as CharacterLoaded).character),
          ),
        ],
        child: _buildShop(),
      ),
    );
  }

  void _askNamesAfterFrame(List<Pet> bought) {
    if (!widget.isCompanionNamingEnabled || bought.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _askNames(bought));
  }

  /// Un foglio del nome per compagno, uno dopo l'altro (D-18); comprare non
  /// equipaggia mai (Phase 13 D-08), il nome arriva con `characterUpdated`.
  Future<void> _askNames(List<Pet> bought) async {
    for (final pet in bought) {
      if (!mounted) return;
      final characterState = context.read<CharacterCubit>().state;
      if (characterState is! CharacterLoaded) return;
      await showCompanionNameSheet(
        context,
        characterId: characterState.character.id,
        petId: pet.id,
        species: pet.name ?? '',
      );
    }
  }

  /// Un nuovo pool della città del marker tiene nell'acquisto solo ciò che
  /// la città vende ancora (D-03) e nessun compagno già posseduto (D-08).
  void _pruneBuySelection(ShopState state) {
    final characterState = context.read<CharacterCubit>().state;
    if (characterState is! CharacterLoaded) return;
    final character = characterState.character;
    final pool = _poolOf(state, character);
    if (pool == null) return;
    setState(
      () => _toBuy = _toBuy.retainPurchasable(
        pool,
        owned: _ownedPetsOf(character),
      ),
    );
  }

  /// Un compagno comprato o venduto altrove (risposta persa, altro device)
  /// esce dalle selezioni: il BE lo rifiuterebbe a ogni firma (D-07, D-08).
  void _pruneOnOwnedPets(Character character) {
    final owned = _ownedPetsOf(character);
    final pool = _poolOf(context.read<ShopCubit>().state, character);
    setState(() {
      _toBuy = pool == null
          ? _toBuy.withoutOwned(owned)
          : _toBuy.retainPurchasable(pool, owned: owned);
      _toSell = _toSell.retainOwned(owned);
    });
  }

  bool _ownedPetsChanged(CharacterState previous, CharacterState current) =>
      previous is CharacterLoaded &&
      current is CharacterLoaded &&
      !setEquals(
        _ownedPetIdsOf(previous.character),
        _ownedPetIdsOf(current.character),
      );

  List<Pet> _ownedPetsOf(Character character) =>
      character.assets?.ownedCatalogPets ?? const [];

  Set<String> _ownedPetIdsOf(Character character) => {
    for (final pet in _ownedPetsOf(character)) pet.id,
  };

  Widget _buildShop() {
    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, characterState) {
        final Character? character = (characterState is CharacterLoaded)
            ? characterState.character
            : null;

        if (character == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, transactionState) => Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildScene(transactionState),
              _buildShopkeeper(transactionState),
              if (_lineOf(transactionState) case final line?)
                TransactionMessageBubble(message: line),
              _buildCounter(character, transactionState),
              if (_isPurseOnCounter(transactionState)) _buildPouch(character),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScene(TransactionState transactionState) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Image.asset(
        _moodOf(transactionState).background,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }

  /// La stizza vale solo a bottega ferma: una transazione in corso parla
  /// per sé.
  bool _showsAnnoyance(TransactionState state) =>
      _isAnnoyed && state is TransactionInitial;

  ShopkeeperMood _moodOf(TransactionState state) => _showsAnnoyance(state)
      ? ShopkeeperMood.puzzled
      : shopkeeperMoodFor(state);

  String? _lineOf(TransactionState state) =>
      _showsAnnoyance(state) ? annoyedLine : shopkeeperLineFor(state);

  Widget _buildShopkeeper(TransactionState transactionState) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: size.width * 0.4,
      top: size.height * 0.18,
      width: size.width * 0.2,
      height: size.height * 0.6,
      child: GestureDetector(
        key: Shop.shopkeeperKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => _pokeShopkeeper(transactionState),
      ),
    );
  }

  void _pokeShopkeeper(TransactionState transactionState) {
    if (transactionState is! TransactionInitial) return;
    if (!_pokes.poke(DateTime.now())) return;
    setState(() => _isAnnoyed = true);
    _annoyedTimer?.cancel();
    _annoyedTimer = Timer(TransactionCubit.defaultResetDelay, () {
      if (mounted) setState(() => _isAnnoyed = false);
    });
  }

  /// Il borsello resta sul bancone tranne quando è in mano al negoziante:
  /// mentre conta le monete e nella scena contenta.
  bool _isPurseOnCounter(TransactionState transactionState) =>
      transactionState is! TransactionLoading &&
      transactionState is! TransactionDone;

  bool get _hasCart => !_toBuy.isEmpty || !_toSell.isEmpty;

  /// Listino, ricevuta e zaino appoggiati sul bancone, ognuno con la sua
  /// ombra di contatto: i riquadri degli SVG hanno margini trasparenti, per
  /// questo le misure partono dalla base disegnata dentro il riquadro.
  Widget _buildCounter(Character character, TransactionState transactionState) {
    final size = MediaQuery.of(context).size;
    // Mentre il negoziante conta, la ricevuta è già nelle sue mani.
    final showsReceipt = _hasCart && transactionState is! TransactionLoading;
    final priceListSide = size.height * 0.57;
    final priceListLeft = size.width * 0.06;
    final priceListBottom = size.height * 0.01 + 10;
    final backpackSide = size.height * 0.6;
    final backpackRight = size.width * 0.04;
    final backpackBottom = size.height * 0.03;
    final receiptLength = _receiptLength(size);
    final receiptBottom = size.height * 0.05 - 3;
    return Positioned.fill(
      child: Stack(
        children: [
          _shadowUnder(
            centerX: priceListLeft + priceListSide / 2,
            baseFromBottom: priceListBottom + priceListSide * 0.06,
            width: priceListSide * 0.8,
          ),
          Positioned(
            left: priceListLeft,
            bottom: priceListBottom,
            child: GestureDetector(
              onTap: () => _openBuySheet(character),
              child: CachedSvg(
                width: priceListSide,
                height: priceListSide,
                url: CloudinaryAssets.url(CloudinaryAssets.buy),
              ),
            ),
          ),
          if (showsReceipt) ...[
            Positioned(
              left: (size.width - receiptLength) / 2,
              bottom: receiptBottom,
              child: GestureDetector(
                onTap: () => _showModalTransaction(character),
                child: _buildReceipt(size),
              ),
            ),
          ],
          _shadowUnder(
            centerX: size.width - backpackRight - backpackSide * 0.5,
            baseFromBottom: backpackBottom + backpackSide * 0.13,
            width: backpackSide * 0.95,
          ),
          Positioned(
            right: backpackRight,
            bottom: backpackBottom,
            child: GestureDetector(
              onTap: () => _openSellSheet(character),
              child: CachedSvg(
                width: backpackSide,
                height: backpackSide,
                url: CloudinaryAssets.url(CloudinaryAssets.sell),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ombra schiacciata centrata sulla base di un oggetto, a [baseFromBottom]
  /// dal fondo dello schermo.
  Widget _shadowUnder({
    required double centerX,
    required double baseFromBottom,
    required double width,
  }) {
    final height = width * 0.2;
    return Positioned(
      left: centerX - width / 2,
      bottom: baseFromBottom - height * 0.7,
      child: CounterShadow(width: width, height: height),
    );
  }

  /// Leggera rotazione della ricevuta, come un foglio posato a mano.
  static const double _receiptTilt = 0.12;

  double _receiptLength(Size size) => size.height / 3.8 - 10;

  /// La ricevuta giace di traverso sul bancone, appena inclinata, con
  /// l'ombra del foglio che la segue. Il foglio è stretto in un
  /// riquadro quadrato: si ritaglia la sua colonna e i margini trasparenti
  /// sbordano senza spingere i vicini.
  Widget _buildReceipt(Size size) {
    final length = _receiptLength(size);
    return Transform.rotate(
      angle: _receiptTilt,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          PaperShadow(
            width: length * 0.9,
            height: length * 0.34,
            strength: 0.85,
          ),
          RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              width: length * 0.42,
              height: length,
              child: OverflowBox(
                maxWidth: double.infinity,
                child: CachedSvg(
                  height: length,
                  url: CloudinaryAssets.url(CloudinaryAssets.receipt),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Il borsello sporge dall'angolo del bancone con il saldo sul cartellino;
  /// con un carrello da pagare il negoziante lo prende all'altezza del petto,
  /// al centro della scena.
  Widget _buildPouch(Character character) {
    final size = MediaQuery.of(context).size;
    final pouchSide = size.height * 0.6;
    return Positioned(
      right: -pouchSide * 0.25,
      bottom: -pouchSide * 0.25,
      child: CoinsPouch(
        width: pouchSide,
        height: pouchSide,
        shopkeeper: Offset(size.width / 2, size.height * 0.55),
        purse: character.status?.coins,
        onDelivered: _hasCart ? () => _pay(character) : null,
      ),
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
    this.wornEquipment,
    this.petNames = const {},
  });

  final List<AssetQuantity> equipments;
  final List<AssetQuantity> items;
  final List<Pet> pets;
  final String? equippedPetId;
  final Equipment? wornEquipment;
  final Map<String, String> petNames;
}
