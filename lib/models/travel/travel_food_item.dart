import 'package:equatable/equatable.dart';

import '../loot_item.dart';

/// Cibo che il BE mangerà per il viaggio (BE Phase 14 D-09): un oggetto e
/// quante unità. L'ordine è quello del BE; il FE non sceglie né somma.
class TravelFoodItem extends Equatable {
  const TravelFoodItem({required this.item, required this.quantity});

  final LootItem item;
  final int quantity;

  /// Sempre non vuoto: [listFrom] scarta le voci senza nome.
  String get name => item.name ?? '';

  /// Solo id e nome (selezione a profondità 1, 15-REPO-RULES): un campo in
  /// più non può far cadere l'anteprima. `null` per una voce malformata.
  static TravelFoodItem? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final item = json['item'];
    final quantity = json['quantity'];
    if (item is! Map<String, dynamic> || quantity is! num || quantity < 1) {
      return null;
    }
    final id = item['id'];
    final name = item['name'];
    if (id is! String || name is! String || name.isEmpty) return null;
    return TravelFoodItem(
      item: LootItem.fromJson({'id': id, 'name': name}),
      quantity: quantity.toInt(),
    );
  }

  /// Voce malformata scartata, il resto resta (regola della Phase 13, D-01).
  static List<TravelFoodItem> listFrom(Object? json) {
    if (json is! List) return const [];
    return List.unmodifiable(json.map(tryFromJson).whereType<TravelFoodItem>());
  }

  Map<String, dynamic> toJson() => {
    'item': {'id': item.id, 'name': item.name},
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [item, quantity];
}
