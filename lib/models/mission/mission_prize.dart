import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/mission/mission_entries.dart';
import 'package:klimmeck_guide/models/quest/quest_cure.dart';

/// Oggetto in premio con la sua quantità (`MissionPrizeItem { item quantity }`).
class MissionPrizeItem extends Equatable {
  const MissionPrizeItem({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  static MissionPrizeItem? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final itemId = json['item'];
    final quantity = missionIntOf(json['quantity']);
    if (itemId is! String || quantity == null) return null;
    return MissionPrizeItem(itemId: itemId, quantity: quantity);
  }

  Map<String, dynamic> toJson() => {'item': itemId, 'quantity': quantity};

  @override
  List<Object?> get props => [itemId, quantity];
}

/// Premio di un personaggio nella bozza: precompilato dal BE col blocco del
/// rango (D-22), l'oste toglie o aggiunge dal catalogo servito.
class MissionPrize extends Equatable {
  const MissionPrize({
    required this.characterId,
    required this.coins,
    required this.xp,
    this.cure,
    this.items = const [],
    this.petId,
    this.spellId,
  });

  final String characterId;
  final Coins coins;
  final int xp;

  /// `null` = nessuna cura (assente o tolta).
  final QuestCure? cure;
  final List<MissionPrizeItem> items;
  final String? petId;
  final String? spellId;

  /// Confine di parsing: senza `character`, `coins` o `xp` vale `null`.
  static MissionPrize? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final characterId = json['character'];
    final coins = json['coins'];
    final xp = missionIntOf(json['xp']);
    if (characterId is! String || coins is! Map<String, dynamic>) return null;
    if (xp == null) return null;
    try {
      return MissionPrize(
        characterId: characterId,
        coins: Coins.fromJson(coins),
        xp: xp,
        cure: QuestCure.tryFromJson(json['cure']),
        items: missionEntriesOf(json['items'], MissionPrizeItem.tryFromJson),
        petId: _idOrNull(json['pet']),
        spellId: _idOrNull(json['spell']),
      );
    } on Object {
      return null;
    }
  }

  static String? _idOrNull(Object? json) => json is String ? json : null;

  @override
  List<Object?> get props => [
    characterId,
    coins,
    xp,
    cure,
    items,
    petId,
    spellId,
  ];
}
