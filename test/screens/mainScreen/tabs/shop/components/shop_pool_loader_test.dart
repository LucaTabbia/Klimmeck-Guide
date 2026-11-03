import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

final _cities = [
  City.fromJson({
    'id': 'city-1',
    'markerLocation': {
      'id': 'city-marker-1',
      'location': [1.0, 2.0],
    },
  }),
  City.fromJson({
    'id': 'city-2',
    'markerLocation': {
      'id': 'city-marker-2',
      'location': [3.0, 4.0],
    },
  }),
];

CharacterLoaded _characterOn(
  String locationId, {
  Map<String, dynamic>? pendingQuest,
}) => CharacterLoaded(
  Character.fromJson(
    travellingCharacterJson(locationId: locationId, pendingQuest: pendingQuest),
  ),
);

void main() {
  late MockCharacterCubit characterCubit;
  late MockShopCubit shopCubit;
  late MockTransactionCubit transactionCubit;
  late StreamController<CharacterState> characterStates;
  late StreamController<TransactionState> transactionStates;

  setUp(() {
    characterCubit = MockCharacterCubit();
    shopCubit = MockShopCubit();
    transactionCubit = MockTransactionCubit();
    characterStates = StreamController<CharacterState>.broadcast();
    transactionStates = StreamController<TransactionState>.broadcast();
    addTearDown(characterStates.close);
    addTearDown(transactionStates.close);
    whenListen(
      characterCubit,
      characterStates.stream,
      initialState: _characterOn('city-marker-1'),
    );
    whenListen(
      transactionCubit,
      transactionStates.stream,
      initialState: TransactionInitial(),
    );
    when(() => shopCubit.getData(any())).thenAnswer((_) async {});
  });

  Future<void> pumpLoader(WidgetTester tester) => tester.pumpWidget(
    buildTestApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<CharacterCubit>.value(value: characterCubit),
          BlocProvider<ShopCubit>.value(value: shopCubit),
          BlocProvider<TransactionCubit>.value(value: transactionCubit),
        ],
        child: ShopPoolLoader(
          cities: _cities,
          child: const SizedBox(key: Key('shop-page')),
        ),
      ),
    ),
  );

  Future<void> emitCharacter(WidgetTester tester, CharacterState state) async {
    when(() => characterCubit.state).thenReturn(state);
    characterStates.add(state);
    await tester.pump();
  }

  Future<void> emitTransaction(
    WidgetTester tester,
    TransactionState state,
  ) async {
    when(() => transactionCubit.state).thenReturn(state);
    transactionStates.add(state);
    await tester.pump();
  }

  testWidgets('loads the pool of the marker city on mount (D-03)', (
    tester,
  ) async {
    await pumpLoader(tester);

    verify(() => shopCubit.getData('city-1')).called(1);
  });

  testWidgets('does nothing off a city marker', (tester) async {
    when(() => characterCubit.state).thenReturn(_characterOn('poi-9'));

    await pumpLoader(tester);

    verifyNever(() => shopCubit.getData(any()));
  });

  testWidgets(
    'reloads when the character lands on another city while the page is '
    'shown (D-03)',
    (tester) async {
      await pumpLoader(tester);

      await emitCharacter(tester, _characterOn('city-marker-2'));

      verify(() => shopCubit.getData('city-1')).called(1);
      verify(() => shopCubit.getData('city-2')).called(1);
    },
  );

  testWidgets(
    'does not reload when the character changes without changing city (D-03)',
    (tester) async {
      await pumpLoader(tester);

      await emitCharacter(
        tester,
        _characterOn('city-marker-1', pendingQuest: questJson()),
      );

      verify(() => shopCubit.getData(any())).called(1);
    },
  );

  testWidgets('reloads after an ITEM_NOT_IN_SHOP refusal (D-05)', (
    tester,
  ) async {
    await pumpLoader(tester);

    await emitTransaction(
      tester,
      TransactionError(TransactionFailure.itemNotInShop),
    );

    verify(() => shopCubit.getData('city-1')).called(2);
  });

  testWidgets('does not reload after any other refusal (D-05)', (tester) async {
    await pumpLoader(tester);

    await emitTransaction(
      tester,
      TransactionError(TransactionFailure.insufficientFunds),
    );

    verify(() => shopCubit.getData(any())).called(1);
  });

  testWidgets('renders its child unchanged', (tester) async {
    await pumpLoader(tester);

    expect(find.byKey(const Key('shop-page')), findsOneWidget);
  });
}
