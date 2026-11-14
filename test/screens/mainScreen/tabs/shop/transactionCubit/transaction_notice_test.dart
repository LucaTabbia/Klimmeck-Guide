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
        (failure) =>
            failure != TransactionFailure.shopNotInCity &&
            failure != TransactionFailure.imprisoned &&
            failure != TransactionFailure.missionInProgress,
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
    test('the prison refusal becomes a banner with the release time '
        '(quick 261110-cgd)', () {
      expect(
        transactionNoticeFor(
          TransactionFailure.imprisoned,
          imprisonedFor: const Duration(hours: 9, minutes: 12),
        ),
        const KGNotification(
          title: 'Negozio non disponibile',
          description: 'Sei in prigione: uscirai fra 9 h 12 min',
        ),
      );
      expect(
        transactionNoticeFor(TransactionFailure.imprisoned)!.description,
        'Sei in prigione',
      );
    });

    test('missionInProgress is a shop banner with the wait line '
        '(D-11, D-30)', () {
      expect(
        transactionNoticeFor(TransactionFailure.missionInProgress),
        const KGNotification(
          title: 'Negozio non disponibile',
          description: "Sei impegnato in una missione: aspetta l'esito",
        ),
      );
    });

    test('BAD_USER_INPUT raises no banner (D-13)', () {
      expect(transactionNoticeFor(TransactionFailure.badUserInput), isNull);
    });
  });

  group('shopkeeperRefusalLine', () {
    test("BAD_USER_INPUT keeps the shopkeeper's generic line (D-13)", () {
      expect(
        shopkeeperRefusalLine(TransactionFailure.badUserInput),
        genericRefusalLine,
      );
    });

    test('only the off-city and prison refusals have no bubble line: they are '
        'banners (Phase 9 D-16, quick 261110-cgd)', () {
      expect(shopkeeperRefusalLine(TransactionFailure.shopNotInCity), isNull);
      expect(shopkeeperRefusalLine(TransactionFailure.imprisoned), isNull);
      final others = TransactionFailure.values.where(
        (failure) =>
            failure != TransactionFailure.shopNotInCity &&
            failure != TransactionFailure.imprisoned &&
            failure != TransactionFailure.missionInProgress,
      );
      for (final failure in others) {
        expect(shopkeeperRefusalLine(failure), isNotNull, reason: failure.name);
      }
    });

    test('missionInProgress has no shopkeeper bubble (D-30)', () {
      expect(
        shopkeeperRefusalLine(TransactionFailure.missionInProgress),
        isNull,
      );
    });

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
