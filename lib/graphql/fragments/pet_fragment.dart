import 'coins_fragment.dart';

class PetFragment {
  /// Campi del compagno: nessuna immagine (D-13), velocità solo stampata (D-11).
  static const String fields =
      '''
    id
    name
    speedModifier
    sellable
    buyPrice {
      ${CoinsFragment.fields}
    }
    sellPrice {
      ${CoinsFragment.fields}
    }
  ''';
}
