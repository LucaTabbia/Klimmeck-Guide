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
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shop.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
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

CharacterLoaded _characterInCity({
  List<Map<String, dynamic>> ownedPets = const [],
}) => CharacterLoaded(
  Character.fromJson({
    ...travellingCharacterJson(locationId: 'city-marker-1'),
    'assets': {'ownedPets': ownedPets},
  }),
);

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
  });

  Future<void> pumpShop(WidgetTester tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<ShopCubit>.value(value: shopCubit),
            BlocProvider<TransactionCubit>.value(value: transactionCubit),
          ],
          child: Scaffold(body: Shop(cities: _cities)),
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
}
