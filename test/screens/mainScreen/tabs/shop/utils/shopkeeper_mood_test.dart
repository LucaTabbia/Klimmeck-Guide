import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/utils/shopkeeper_mood.dart';

void main() {
  group('shopkeeperMoodFor', () {
    test('welcomes the customer while no transaction is under way', () {
      expect(shopkeeperMoodFor(TransactionInitial()), ShopkeeperMood.welcoming);
    });

    test('counts the coins while the server answers', () {
      expect(shopkeeperMoodFor(TransactionLoading()), ShopkeeperMood.counting);
    });

    test('is pleased by a done deal', () {
      expect(shopkeeperMoodFor(TransactionDone()), ShopkeeperMood.pleased);
    });

    test('gets angry at a purse too light', () {
      expect(
        shopkeeperMoodFor(
          TransactionError(TransactionFailure.insufficientFunds),
        ),
        ShopkeeperMood.angry,
      );
    });

    test('is puzzled by every other refusal', () {
      final others = TransactionFailure.values.where(
        (failure) => failure != TransactionFailure.insufficientFunds,
      );
      for (final failure in others) {
        expect(
          shopkeeperMoodFor(TransactionError(failure)),
          ShopkeeperMood.puzzled,
          reason: failure.name,
        );
      }
    });
  });

  group('ShopkeeperMood.background', () {
    test('every mood has its own shop scene', () {
      expect({
        for (final mood in ShopkeeperMood.values) mood.background,
      }, hasLength(ShopkeeperMood.values.length));
      expect(
        ShopkeeperMood.welcoming.background,
        'assets/images/shop_background.jpg',
      );
    });
  });

  group('shopkeeperLineFor', () {
    test('says nothing while no transaction is under way', () {
      expect(shopkeeperLineFor(TransactionInitial()), isNull);
    });

    test('checks the purse while the server answers', () {
      expect(
        shopkeeperLineFor(TransactionLoading()),
        'Controllo che sia tutto in ordine',
      );
    });

    test('a done deal reads «Ottimo! Posso fare altro per te?»', () {
      expect(
        shopkeeperLineFor(TransactionDone()),
        'Ottimo! Posso fare altro per te?',
      );
    });

    test('a refusal reads its shopkeeper line', () {
      expect(
        shopkeeperLineFor(
          TransactionError(TransactionFailure.insufficientFunds),
        ),
        'Vuoi truffarmi? Non hai soldi a sufficienza!',
      );
    });

    test('a banner refusal leaves the bubble empty', () {
      expect(
        shopkeeperLineFor(TransactionError(TransactionFailure.shopNotInCity)),
        isNull,
      );
    });
  });
}
