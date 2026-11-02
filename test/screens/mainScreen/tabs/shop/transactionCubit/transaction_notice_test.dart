import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart';

void main() {
  group('transactionNoticeFor', () {
    test('shopNotInCity becomes the out-of-city banner', () {
      expect(
        transactionNoticeFor(TransactionFailure.shopNotInCity),
        const KGNotification(
          title: 'Negozio non disponibile',
          description: 'Il negozio è disponibile solo in città',
        ),
      );
    });

    test('every other failure stays in the shopkeeper bubble', () {
      final others = TransactionFailure.values.where(
        (failure) => failure != TransactionFailure.shopNotInCity,
      );
      for (final failure in others) {
        expect(transactionNoticeFor(failure), isNull, reason: failure.name);
      }
    });

    test(
      'the pool and companion refusals stay in the shopkeeper bubble, never a banner (D-05)',
      () {
        for (final failure in [
          TransactionFailure.itemNotInShop,
          TransactionFailure.petAlreadyOwned,
          TransactionFailure.petNotOwned,
        ]) {
          expect(transactionNoticeFor(failure), isNull, reason: failure.name);
        }
      },
    );
  });

  group('shopkeeperRefusalLine', () {
    test(
      'only the off-city refusal has no bubble line: it is the banner (Phase 9 D-16)',
      () {
        expect(shopkeeperRefusalLine(TransactionFailure.shopNotInCity), isNull);
        final others = TransactionFailure.values.where(
          (failure) => failure != TransactionFailure.shopNotInCity,
        );
        for (final failure in others) {
          expect(
            shopkeeperRefusalLine(failure),
            isNotNull,
            reason: failure.name,
          );
        }
      },
    );

    test(
      'an item outside the pool reads «Questa merce non la tratto» (D-05)',
      () {
        expect(
          shopkeeperRefusalLine(TransactionFailure.itemNotInShop),
          'Questa merce non la tratto',
        );
      },
    );

    test(
      'a companion already owned reads «Hai già questo compagno» (D-06)',
      () {
        expect(
          shopkeeperRefusalLine(TransactionFailure.petAlreadyOwned),
          'Hai già questo compagno',
        );
      },
    );

    test(
      'a companion no longer owned reads «Questo compagno non è più tuo» (D-06)',
      () {
        expect(
          shopkeeperRefusalLine(TransactionFailure.petNotOwned),
          'Questo compagno non è più tuo',
        );
      },
    );

    test('missing coins read «Non ti bastano le monete»', () {
      expect(
        shopkeeperRefusalLine(TransactionFailure.insufficientFunds),
        'Non ti bastano le monete',
      );
    });

    test("every other refusal keeps today's generic line", () {
      for (final failure in [
        TransactionFailure.totalMismatch,
        TransactionFailure.unknown,
        TransactionFailure.connection,
      ]) {
        expect(
          shopkeeperRefusalLine(failure),
          genericRefusalLine,
          reason: failure.name,
        );
      }
      expect(genericRefusalLine, 'Hmmm... Qualcosa non mi torna. Riproviamo?');
    });
  });
}
