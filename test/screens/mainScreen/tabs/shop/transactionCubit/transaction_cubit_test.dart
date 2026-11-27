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

  TransactionCubit buildCubit({
    Duration resetDelay = Duration.zero,
    Duration minimumLoading = Duration.zero,
  }) => TransactionCubit(
    graphQl,
    resetDelay: resetDelay,
    minimumLoading: minimumLoading,
  );

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
  });

  test('starts from TransactionInitial with a four seconds reset', () {
    final cubit = TransactionCubit(graphQl);

    expect(cubit.state, isA<TransactionInitial>());
    expect(cubit.resetDelay, const Duration(seconds: 4));
    cubit.close();
  });

  test('the shopkeeper counts the coins for at least two seconds', () {
    final cubit = TransactionCubit(graphQl);

    expect(cubit.minimumLoading, const Duration(seconds: 2));
    cubit.close();
  });

  group('minimum loading', () {
    TransactionState stateAfter(
      FakeAsync async,
      TransactionCubit cubit,
      Duration elapsed,
    ) {
      async.elapse(elapsed);
      return cubit.state;
    }

    test('a quick success stays Loading until the minimum has passed', () {
      fakeAsync((async) {
        when(
          () => graphQl.doTransaction(request),
        ).thenAnswer((_) async => 'ok');
        final cubit = buildCubit(
          resetDelay: const Duration(seconds: 4),
          minimumLoading: const Duration(seconds: 2),
        );

        cubit.doTransaction(request);

        expect(
          stateAfter(async, cubit, const Duration(milliseconds: 1999)),
          isA<TransactionLoading>(),
        );
        expect(
          stateAfter(async, cubit, const Duration(milliseconds: 1)),
          isA<TransactionDone>(),
        );
        cubit.close();
      });
    });

    test('a quick refusal stays Loading until the minimum has passed', () {
      fakeAsync((async) {
        when(
          () => graphQl.doTransaction(request),
        ).thenThrow(codedException('ITEM_NOT_IN_SHOP'));
        final cubit = buildCubit(
          resetDelay: const Duration(seconds: 4),
          minimumLoading: const Duration(seconds: 2),
        );

        cubit.doTransaction(request);

        expect(
          stateAfter(async, cubit, const Duration(milliseconds: 1999)),
          isA<TransactionLoading>(),
        );
        expect(
          stateAfter(async, cubit, const Duration(milliseconds: 1)),
          errorWith(TransactionFailure.itemNotInShop),
        );
        cubit.close();
      });
    });

    test('a slow reply is not delayed further', () {
      fakeAsync((async) {
        when(() => graphQl.doTransaction(request)).thenAnswer(
          (_) => Future.delayed(const Duration(seconds: 3), () => 'ok'),
        );
        final cubit = buildCubit(
          resetDelay: const Duration(seconds: 4),
          minimumLoading: const Duration(seconds: 2),
        );

        cubit.doTransaction(request);

        expect(
          stateAfter(async, cubit, const Duration(milliseconds: 2999)),
          isA<TransactionLoading>(),
        );
        expect(
          stateAfter(async, cubit, const Duration(milliseconds: 1)),
          isA<TransactionDone>(),
        );
        cubit.close();
      });
    });
  });

  blocTest<TransactionCubit, TransactionState>(
    'a purse too light is refused without asking the server',
    build: buildCubit,
    act: (cubit) => cubit.refuseInsufficientFunds(),
    wait: const Duration(milliseconds: 1),
    expect: () => [
      errorWith(TransactionFailure.insufficientFunds),
      isA<TransactionInitial>(),
    ],
    verify: (_) => verifyZeroInteractions(graphQl),
  );

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
    'a prison refusal carries the server release (quick 261110-cgd)',
    setUp: () {
      when(() => graphQl.doTransaction(request)).thenThrow(
        OperationException(
          graphqlErrors: [
            GraphQLError(
              message: 'server text',
              extensions: {
                'code': 'CHARACTER_IMPRISONED',
                'imprisonedUntil': '2026-11-10T22:00:00.000Z',
              },
            ),
          ],
        ),
      );
    },
    build: buildCubit,
    act: (cubit) => cubit.doTransaction(request),
    wait: const Duration(milliseconds: 1),
    expect: () => [
      isA<TransactionLoading>(),
      isA<TransactionError>()
          .having(
            (state) => state.failure,
            'failure',
            TransactionFailure.imprisoned,
          )
          .having(
            (state) => state.imprisonedUntil,
            'imprisonedUntil',
            DateTime.utc(2026, 11, 10, 22),
          ),
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
      async.elapse(Duration.zero);
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
