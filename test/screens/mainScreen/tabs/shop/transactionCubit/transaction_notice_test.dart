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
  });
}
