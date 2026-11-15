import 'coins_fragment.dart';
import 'damage_fragment.dart';

class PetFragment {
  /// Campi del compagno: vita massima e immagine servite oggi (Phase 22 D-09,
  /// D-34; emenda Phase 13 D-13), velocità solo stampata (D-11).
  /// `maxXp`, `attack`, `defense` e `rarity` sono della BE Phase 19
  /// (19-CONTEXT D-12, D-13, D-20); `rarity` può essere null.
  /// `recoveryTime` della BE Phase 23 (D-25), solo letto nel dettaglio.
  static const String fields =
      '''
    id
    name
    imagePath
    speedModifier
    sellable
    buyPrice {
      ${CoinsFragment.fields}
    }
    sellPrice {
      ${CoinsFragment.fields}
    }
    maxXp
    maxLifePoints
    recoveryTime
    attack {
      ${DamagesFragment.fields}
    }
    defense {
      ${DamagesFragment.fields}
    }
    rarity
  ''';
}
