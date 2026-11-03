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

const String genericRefusalLine = 'Hmmm... Qualcosa non mi torna. Riproviamo?';

/// Riga del fumetto del negoziante per ogni rifiuto (D-05, D-06); null solo
/// per il rifiuto fuori città, che è il banner (Phase 9 D-16). Copy
/// provvisoria (D-13).
String? shopkeeperRefusalLine(TransactionFailure failure) => switch (failure) {
  TransactionFailure.shopNotInCity => null,
  TransactionFailure.itemNotInShop => 'Questa merce non la tratto',
  TransactionFailure.petAlreadyOwned => 'Hai già questo compagno',
  TransactionFailure.petNotOwned => 'Questo compagno non è più tuo',
  TransactionFailure.insufficientFunds => 'Non ti bastano le monete',
  _ => genericRefusalLine,
};
