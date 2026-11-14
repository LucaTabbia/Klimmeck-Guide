import 'coins_fragment.dart';
import 'damage_fragment.dart';

class PetFragment {
  /// Campi del compagno: vita massima e immagine servite oggi (Phase 22 D-09,
  /// D-34; emenda Phase 13 D-13), velocità solo stampata (D-11).
  /// `maxXp`, `attack`, `defense` e `rarity` sono della BE Phase 19
  /// (19-CONTEXT D-12, D-13, D-20); `rarity` può essere null.
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
    attack {
      ${DamagesFragment.fields}
    }
    defense {
      ${DamagesFragment.fields}
    }
    rarity
  ''';
}
