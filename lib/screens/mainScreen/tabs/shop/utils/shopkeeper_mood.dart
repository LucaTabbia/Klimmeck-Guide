import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart';

/// Espressione del negoziante dietro il bancone: ogni momento della
/// transazione ha la sua scena del negozio.
enum ShopkeeperMood {
  welcoming('assets/images/shop_background.jpg'),
  counting('assets/images/shop_background_counting.jpg'),
  pleased('assets/images/shop_background_pleased.jpg'),
  puzzled('assets/images/shop_background_puzzled.jpg'),
  angry('assets/images/shop_background_angry.jpg');

  const ShopkeeperMood(this.background);

  final String background;
}

/// Il negoziante si arrabbia solo per una borsa che non basta; ogni altro
/// rifiuto lo lascia perplesso.
ShopkeeperMood shopkeeperMoodFor(TransactionState state) => switch (state) {
  TransactionInitial() => ShopkeeperMood.welcoming,
  TransactionLoading() => ShopkeeperMood.counting,
  TransactionDone() => ShopkeeperMood.pleased,
  TransactionError(failure: TransactionFailure.insufficientFunds) =>
    ShopkeeperMood.angry,
  TransactionError() => ShopkeeperMood.puzzled,
};

const String countingLine = 'Controllo che sia tutto in ordine';
const String dealDoneLine = 'Ottimo! Posso fare altro per te?';
const String annoyedLine = 'Smettila di toccarmi! Sto lavorando';

/// Frase del fumetto per [state]; null quando il negoziante tace (nessuna
/// transazione o rifiuto mostrato come banner).
String? shopkeeperLineFor(TransactionState state) => switch (state) {
  TransactionInitial() => null,
  TransactionLoading() => countingLine,
  TransactionDone() => dealDoneLine,
  TransactionError(:final failure) => shopkeeperRefusalLine(failure),
};
