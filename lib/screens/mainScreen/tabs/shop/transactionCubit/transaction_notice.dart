import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/utils/prison_lines.dart';

const String transactionNoticeTitle = 'Negozio non disponibile';

/// Solo i rifiuti fuori città (D-16) e in prigione (quick 261110-cgd, con il
/// tempo che manca [imprisonedFor]) diventano banner; il resto resta nel
/// fumetto del negoziante. Copy provvisoria (D-19).
KGNotification? transactionNoticeFor(
  TransactionFailure failure, {
  Duration? imprisonedFor,
}) => switch (failure) {
  TransactionFailure.shopNotInCity => const KGNotification(
    title: transactionNoticeTitle,
    description: 'Il negozio è disponibile solo in città',
  ),
  TransactionFailure.imprisoned => KGNotification(
    title: transactionNoticeTitle,
    description: prisonReleaseLine(imprisonedFor),
  ),
  _ => null,
};

const String genericRefusalLine = 'Hmmm... Qualcosa non mi torna. Riproviamo?';

/// Riga del fumetto del negoziante per ogni rifiuto (D-05, D-06); null solo
/// per i rifiuti fuori città e in prigione, che sono banner (Phase 9 D-16,
/// quick 261110-cgd). Copy provvisoria (D-13).
String? shopkeeperRefusalLine(TransactionFailure failure) => switch (failure) {
  TransactionFailure.shopNotInCity || TransactionFailure.imprisoned => null,
  TransactionFailure.itemNotInShop => 'Questa merce non la tratto',
  TransactionFailure.petAlreadyOwned => 'Hai già questo compagno',
  TransactionFailure.petNotOwned => 'Questo compagno non è più tuo',
  TransactionFailure.insufficientFunds => 'Non ti bastano le monete',
  _ => genericRefusalLine,
};
