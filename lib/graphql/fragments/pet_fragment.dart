import 'coins_fragment.dart';
import 'damage_fragment.dart';

class PetFragment {
  /// Campi del compagno: nessuna immagine (D-13), velocità solo stampata (D-11).
  /// `maxXp`, `attack`, `defense` e `rarity` sono della BE Phase 19
  /// (19-CONTEXT D-12, D-13, D-20); `rarity` può essere null.
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
    maxXp
    attack {
      ${DamagesFragment.fields}
    }
    defense {
      ${DamagesFragment.fields}
    }
    rarity
  ''';
}
