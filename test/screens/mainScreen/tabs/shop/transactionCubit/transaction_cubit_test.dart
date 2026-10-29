import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

void main() {
  late MockKlimmeckGraphQl graphQl;

  final request = TransactionRequest(
    id: 'c-1',
    boughtItems: TransactionItems(equipAssets: [], lootAssets: []),
    soldItems: TransactionItems(equipAssets: [], lootAssets: []),
    isTotalPositive: false,
    total: const Coins(copper: 3),
  );

  OperationException codedException(String code) => OperationException(
    graphqlErrors: [
      GraphQLError(message: 'server text', extensions: {'code': code}),
    ],
  );

  Matcher errorWith(TransactionFailure failure) => isA<TransactionError>()
      .having((state) => state.failure, 'failure', failure);

  TransactionCubit buildCubit({Duration resetDelay = Duration.zero}) =>
      TransactionCubit(graphQl, resetDelay: resetDelay);

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
  });

  test('starts from TransactionInitial with a four seconds reset', () {
    final cubit = TransactionCubit(graphQl);

    expect(cubit.state, isA<TransactionInitial>());
    expect(cubit.resetDelay, const Duration(seconds: 4));
    cubit.close();
  });

  blocTest<TransactionCubit, TransactionState>(
    'emits [Loading, Done, Initial] when the transaction succeeds',
    setUp: () {
      when(() => graphQl.doTransaction(request)).thenAnswer((_) async => 'ok');
    },
    build: buildCubit,
    act: (cubit) => cubit.doTransaction(request),
    wait: const Duration(milliseconds: 1),
    expect: () => [
      isA<TransactionLoading>(),
      isA<TransactionDone>(),
      isA<TransactionInitial>(),
    ],
  );

  blocTest<TransactionCubit, TransactionState>(
    'emits [Loading, Error(shopNotInCity), Initial] on SHOP_NOT_IN_CITY',
    setUp: () {
      when(
        () => graphQl.doTransaction(request),
      ).thenThrow(codedException('SHOP_NOT_IN_CITY'));
    },
    build: buildCubit,
    act: (cubit) => cubit.doTransaction(request),
    wait: const Duration(milliseconds: 1),
    expect: () => [
      isA<TransactionLoading>(),
      errorWith(TransactionFailure.shopNotInCity),
      isA<TransactionInitial>(),
    ],
  );

  blocTest<TransactionCubit, TransactionState>(
    'a non-GraphQL failure becomes Error(unknown)',
    setUp: () {
      when(
        () => graphQl.doTransaction(request),
      ).thenThrow(const FormatException('x'));
    },
    build: buildCubit,
    act: (cubit) => cubit.doTransaction(request),
    wait: const Duration(milliseconds: 1),
    expect: () => [
      isA<TransactionLoading>(),
      errorWith(TransactionFailure.unknown),
      isA<TransactionInitial>(),
    ],
  );

  blocTest<TransactionCubit, TransactionState>(
    'close cancels the pending reset',
    setUp: () {
      when(() => graphQl.doTransaction(request)).thenAnswer((_) async => 'ok');
    },
    build: () => buildCubit(resetDelay: const Duration(milliseconds: 5)),
    act: (cubit) async {
      await cubit.doTransaction(request);
      await cubit.close();
    },
    wait: const Duration(milliseconds: 20),
    expect: () => [isA<TransactionLoading>(), isA<TransactionDone>()],
  );

  test('close leaves no reset timer pending', () {
    fakeAsync((async) {
      when(() => graphQl.doTransaction(request)).thenAnswer((_) async => 'ok');
      final cubit = buildCubit(resetDelay: const Duration(seconds: 4));

      cubit.doTransaction(request);
      async.flushMicrotasks();
      expect(async.pendingTimers, hasLength(1));

      cubit.close();
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a new transaction replaces the pending reset', () {
    fakeAsync((async) {
      when(() => graphQl.doTransaction(request)).thenAnswer((_) async => 'ok');
      final cubit = buildCubit(resetDelay: const Duration(seconds: 4));

      cubit.doTransaction(request);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      cubit.doTransaction(request);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));

      expect(cubit.state, isA<TransactionDone>());
      expect(async.pendingTimers, hasLength(1));
      cubit.close();
    });
  });
}
