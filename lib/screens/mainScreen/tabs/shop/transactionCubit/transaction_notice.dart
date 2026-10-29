import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';

const String transactionNoticeTitle = 'Negozio non disponibile';

/// Solo il rifiuto fuori città diventa banner (D-16); il resto resta nel
/// fumetto del negoziante. Copy provvisoria (D-19).
KGNotification? transactionNoticeFor(TransactionFailure failure) =>
    switch (failure) {
      TransactionFailure.shopNotInCity => const KGNotification(
        title: transactionNoticeTitle,
        description: 'Il negozio è disponibile solo in città',
      ),
      _ => null,
    };
