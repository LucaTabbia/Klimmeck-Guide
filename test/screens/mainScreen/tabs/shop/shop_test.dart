import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shop.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_name_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fakes/svg_http_overrides.dart';
import '../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const _cloudinary = 'https://res.cloudinary.com/dzuhywp53/image/upload/';

final _cities = [
  City.fromJson({
    'id': 'city-1',
    'markerLocation': {
      'id': 'city-marker-1',
      'location': [1.0, 2.0],
    },
  }),
];

final _swordPool = CityShop.fromJson(
  cityShopJson(
    cityId: 'city-1',
    equipment: [equipmentAssetJson()],
    loot: [],
    pets: [],
  ),
);

const _swordRow = 'Equipaggiamento e-sword';

final _horse = Pet.fromJson(petJson());

final _horsePool = CityShop.fromJson(
  cityShopJson(cityId: 'city-1', equipment: [], loot: [], pets: [petJson()]),
);

final _owl = Pet.fromJson(petJson(id: 'pet-owl', name: 'Gufo'));

final _stablePool = CityShop.fromJson(
  cityShopJson(
    cityId: 'city-1',
    equipment: [equipmentAssetJson()],
    loot: [],
    pets: [
      petJson(),
      petJson(id: 'pet-owl', name: 'Gufo'),
    ],
  ),
);

CharacterLoaded _characterInCity({
  List<Map<String, dynamic>> ownedPets = const [],
}) => CharacterLoaded(
  Character.fromJson({
    ...travellingCharacterJson(locationId: 'city-marker-1'),
    'assets': {'ownedPets': ownedPets},
  }),
);

/// Personaggio con le monete per firmare il carrello.
CharacterLoaded _payingCharacterInCity({
  List<Map<String, dynamic>> ownedPets = const [],
}) {
  final json = travellingCharacterJson(locationId: 'city-marker-1');
  return CharacterLoaded(
    Character.fromJson({
      ...json,
      'status': {
        ...json['status'] as Map<String, dynamic>,
        'coins': coinsJson(gold: 10),
      },
      'assets': {'ownedPets': ownedPets},
    }),
  );
}

Finder _cell(String asset) => find.byWidgetPredicate(
  (widget) => widget is CachedSvg && widget.url == '$_cloudinary$asset',
);

/// Le celle del negozio usano URL completi: senza cache `CachedSvg` va in rete.
void _seedShopCells() {
  final svg =
      File('${Directory.systemTemp.createTempSync('kg_shop').path}/seed.svg')
        ..writeAsStringSync(
          '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
        );
  for (final asset in [
    CloudinaryAssets.buy,
    CloudinaryAssets.sell,
    CloudinaryAssets.emptySatchel,
    CloudinaryAssets.completeTransaction,
  ]) {
    SvgCache().add('$_cloudinary$asset', svg);
  }
}

void main() {
  late MockKlimmeckGraphQl graphQl;
  late ShopCubit shopCubit;
  late MockCharacterCubit characterCubit;
  late MockTransactionCubit transactionCubit;
  late StreamController<CharacterState> characterStates;
  late MockCompanionNameCubit companionNameCubit;

  setUpAll(
    () => registerFallbackValue(
      buildTransactionRequest(
        characterId: '',
        bought: const TradeSelection(),
        sold: const TradeSelection(),
        total: const Coins(),
        isTotalPositive: true,
      ),
    ),
  );

  setUp(() {
    useSvgHttpOverrides();
    seedSvgCache([
      CloudinaryAssets.arrowDown,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bottomEmptySheet,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
      CloudinaryAssets.weaponType,
    ]);
    _seedShopCells();
    graphQl = MockKlimmeckGraphQl();
    shopCubit = ShopCubit(graphQl);
    addTearDown(shopCubit.close);
    characterCubit = MockCharacterCubit();
    transactionCubit = MockTransactionCubit();
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(characterStates.close);
    whenListen(
      characterCubit,
      characterStates.stream,
      initialState: _characterInCity(),
    );
    whenListen(
      transactionCubit,
      const Stream<TransactionState>.empty(),
      initialState: TransactionInitial(),
    );
    companionNameCubit = MockCompanionNameCubit();
    whenListen(
      companionNameCubit,
      const Stream<CompanionNameState>.empty(),
      initialState: const CompanionNameIdle(),
    );
    when(() => companionNameCubit.reset()).thenReturn(null);
  });

  Future<void> pumpShop(
    WidgetTester tester, {
    bool isCompanionNamingEnabled = false,
    Size? physicalSize,
  }) async {
    useLandscapePhone(tester);
    if (physicalSize != null) tester.view.physicalSize = physicalSize;
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<ShopCubit>.value(value: shopCubit),
            BlocProvider<TransactionCubit>.value(value: transactionCubit),
            BlocProvider<CompanionNameCubit>.value(value: companionNameCubit),
          ],
          child: Scaffold(
            body: Shop(
              cities: _cities,
              isCompanionNamingEnabled: isCompanionNamingEnabled,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('buy sheet pool (WR-01)', () {
    testWidgets(
      'a buy sheet opened while the pool loads fills in when it arrives (D-03)',
      (tester) async {
        final pool = Completer<CityShop>();
        when(
          () => graphQl.getCityShop('city-1'),
        ).thenAnswer((_) => pool.future);
        await pumpShop(tester);

        await tapAndSettle(tester, _cell(CloudinaryAssets.buy));
        await tapAndSettle(tester, find.text('Armatura'));
        expect(find.text(_swordRow), findsNothing);

        pool.complete(_swordPool);
        await tester.pumpAndSettle();

        expect(find.text(_swordRow), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the buy cell after a failed load retries the pool (rule 2)',
      (tester) async {
        var calls = 0;
        when(() => graphQl.getCityShop('city-1')).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw Exception('network');
          return _swordPool;
        });
        await pumpShop(tester);
        await tester.pumpAndSettle();
        expect(shopCubit.state, const ShopError('city-1'));

        await tapAndSettle(tester, _cell(CloudinaryAssets.buy));
        await tapAndSettle(tester, find.text('Armatura'));

        verify(() => graphQl.getCityShop('city-1')).called(2);
        expect(find.text(_swordRow), findsOneWidget);
      },
    );
  });

  group('owned pets as entries (Phase 19)', () {
    testWidgets('a pet owned as an entry is not purchasable (D-03)', (
      tester,
    ) async {
      when(
        () => graphQl.getCityShop('city-1'),
      ).thenAnswer((_) async => _horsePool);
      when(
        () => characterCubit.state,
      ).thenReturn(_characterInCity(ownedPets: [ownedPetJson(xp: 40)]));
      await pumpShop(tester);
      await tester.pumpAndSettle();

      await tapAndSettle(tester, _cell(CloudinaryAssets.buy));
      expect(tester.widget<ShopModal>(find.byType(ShopModal)).pets, isEmpty);
      Navigator.of(tester.element(find.byType(ShopModal))).pop();
      await tester.pumpAndSettle();

      await tapAndSettle(tester, _cell(CloudinaryAssets.sell));
      expect(tester.widget<ShopModal>(find.byType(ShopModal)).pets, [_horse]);
    });
  });

  group('selection against the owned pets (WR-02)', () {
    Finder completeCell() => _cell(CloudinaryAssets.completeTransaction);

    Future<void> selectPet(WidgetTester tester, {required String cell}) async {
      await tapAndSettle(tester, _cell(cell));
      tester
          .widget<ShopModal>(find.byType(ShopModal))
          .onSelect(const TradeSelection().addPet(_horse));
      Navigator.of(tester.element(find.byType(ShopModal))).pop();
      await tester.pumpAndSettle();
      expect(completeCell(), findsOneWidget);
    }

    Future<void> emitCharacter(
      WidgetTester tester,
      CharacterState state,
    ) async {
      when(() => characterCubit.state).thenReturn(state);
      characterStates.add(state);
      await tester.pumpAndSettle();
    }

    testWidgets('a pet bought meanwhile leaves the purchase selection (D-08)', (
      tester,
    ) async {
      when(
        () => graphQl.getCityShop('city-1'),
      ).thenAnswer((_) async => _horsePool);
      await pumpShop(tester);
      await tester.pumpAndSettle();
      await selectPet(tester, cell: CloudinaryAssets.buy);

      await emitCharacter(
        tester,
        _characterInCity(ownedPets: [ownedPetJson()]),
      );

      expect(completeCell(), findsNothing);
    });

    testWidgets(
      'a pet that left the inventory leaves the sale selection (D-07)',
      (tester) async {
        when(
          () => graphQl.getCityShop('city-1'),
        ).thenAnswer((_) async => _horsePool);
        when(
          () => characterCubit.state,
        ).thenReturn(_characterInCity(ownedPets: [ownedPetJson()]));
        await pumpShop(tester);
        await tester.pumpAndSettle();
        await selectPet(tester, cell: CloudinaryAssets.sell);

        await emitCharacter(tester, _characterInCity());

        expect(completeCell(), findsNothing);
      },
    );
  });

  group('name prompts after a purchase (D-18)', () {
    late StreamController<TransactionState> transactionStates;

    setUp(() {
      transactionStates = StreamController<TransactionState>.broadcast();
      addTearDown(transactionStates.close);
      whenListen(
        transactionCubit,
        transactionStates.stream,
        initialState: TransactionInitial(),
      );
      when(
        () => transactionCubit.doTransaction(any()),
      ).thenAnswer((_) async {});
      when(
        () => graphQl.getCityShop('city-1'),
      ).thenAnswer((_) async => _stablePool);
      when(() => characterCubit.state).thenReturn(_payingCharacterInCity());
    });

    Finder prompt() => find.byType(CompanionNameSheet);

    String? promptedPetOf(WidgetTester tester) =>
        tester.widget<CompanionNameSheet>(prompt()).petId;

    /// Un po' più alto del telefono: con le monete il sacchetto del negozio
    /// sfora di 6 px col font dei test (difetto preesistente, deferred-items).
    Future<void> pumpPayingShop(
      WidgetTester tester, {
      bool isCompanionNamingEnabled = true,
    }) async {
      await pumpShop(
        tester,
        isCompanionNamingEnabled: isCompanionNamingEnabled,
        physicalSize: const Size(2340, 1440),
      );
      await tester.pumpAndSettle();
    }

    Future<void> buy(
      WidgetTester tester,
      TradeSelection selection, {
      CharacterLoaded? arrivingFirst,
    }) async {
      await tapAndSettle(tester, _cell(CloudinaryAssets.buy));
      tester.widget<ShopModal>(find.byType(ShopModal)).onSelect(selection);
      Navigator.of(tester.element(find.byType(ShopModal))).pop();
      await tester.pumpAndSettle();
      await tapAndSettle(tester, _cell(CloudinaryAssets.completeTransaction));
      tester
          .widget<TransactionModal>(find.byType(TransactionModal))
          .onConfirm(const Coins(gold: 2), false);
      await tester.pumpAndSettle();
      if (arrivingFirst != null) {
        when(() => characterCubit.state).thenReturn(arrivingFirst);
        characterStates.add(arrivingFirst);
        await tester.pumpAndSettle();
      }
      transactionStates.add(TransactionDone());
      await tester.pumpAndSettle();
    }

    Future<void> skipPrompt(WidgetTester tester) async {
      await tester.tap(find.byKey(CompanionNameSheet.skipKey));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'after a purchase each bought companion gets a name prompt in turn (D-18)',
      (tester) async {
        await pumpPayingShop(tester);

        await buy(tester, const TradeSelection().addPet(_horse).addPet(_owl));

        expect(prompt(), findsOneWidget);
        expect(promptedPetOf(tester), _horse.id);
        expect(
          find.text('Come chiamerai il tuo Cavallo da viaggio?'),
          findsOneWidget,
        );
        expect(tester.widget<CompanionNameSheet>(prompt()).characterId, 'c-1');

        await skipPrompt(tester);
        expect(prompt(), findsOneWidget);
        expect(promptedPetOf(tester), _owl.id);

        await skipPrompt(tester);
        expect(prompt(), findsNothing);
      },
    );

    testWidgets(
      'a companion served with the character before the reply still gets '
      'its prompt (D-18)',
      (tester) async {
        await pumpPayingShop(tester);

        await buy(
          tester,
          const TradeSelection().addPet(_owl),
          arrivingFirst: _payingCharacterInCity(
            ownedPets: [
              ownedPetJson(
                pet: petJson(id: 'pet-owl', name: 'Gufo'),
              ),
            ],
          ),
        );

        expect(promptedPetOf(tester), _owl.id);
      },
    );

    testWidgets('buying only items opens no prompt (D-18)', (tester) async {
      await pumpPayingShop(tester);

      await buy(tester, TradeSelection(assets: [_stablePool.equipment.first]));

      expect(prompt(), findsNothing);
    });

    testWidgets('with the switch off no prompt opens (Pitfall 3)', (
      tester,
    ) async {
      await pumpPayingShop(tester, isCompanionNamingEnabled: false);

      await buy(tester, const TradeSelection().addPet(_horse));

      expect(prompt(), findsNothing);
      verifyNever(() => companionNameCubit.reset());
    });
  });
}
