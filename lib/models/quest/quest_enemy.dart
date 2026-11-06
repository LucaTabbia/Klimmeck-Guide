import 'package:equatable/equatable.dart';

import '../enemy.dart';
import '../quantity_line.dart';

/// Voce di `QuestInfos.enemies` / `QuestResult.enemies` (BE Phase 13 D-01):
/// un tipo di nemico e quanti ne affronta la quest. L'ordine è quello del BE
/// (per una dungeon l'ordine delle tappe, BE D-12).
class QuestEnemy extends Equatable {
  const QuestEnemy({required this.enemy, required this.quantity});

  /// Solo id, nome, immagine e xp: altri campi del nemico farebbero fallire
  /// `Enemy.fromJson` (BE §14); `xp` serve solo al ritratto (D-02).
  factory QuestEnemy.fromJson(Map<String, dynamic> json) {
    final enemy = json['enemy'];
    final quantity = json['quantity'];
    if (enemy is! Map<String, dynamic> || enemy['id'] is! String) {
      throw const FormatException('QuestEnemy.enemy missing');
    }
    if (quantity is! num || quantity < 1) {
      throw const FormatException('QuestEnemy.quantity invalid');
    }
    return QuestEnemy(
      enemy: Enemy.fromJson({
        'id': enemy['id'],
        'name': enemy['name'],
        'imagePath': enemy['imagePath'],
        'xp': enemy['xp'],
      }),
      quantity: quantity.toInt(),
    );
  }

  final Enemy enemy;
  final int quantity;

  /// Quest della board: una voce malformata scarta la quest intera
  /// (`Quest.tryFromJson`), mai la board (D-01).
  static List<QuestEnemy> listFrom(Object? json) {
    if (json == null) return const [];
    if (json is! List) throw const FormatException('enemies is not a list');
    return List.unmodifiable(json.map(_strictEntryFrom));
  }

  /// Risultati: una voce malformata è scartata, il risultato resta (D-01 C3).
  static List<QuestEnemy> lenientListFrom(Object? json) {
    if (json is! List) return const [];
    return List.unmodifiable(
      json.whereType<Map<String, dynamic>>().map(_tryFromJson).nonNulls,
    );
  }

  static QuestEnemy _strictEntryFrom(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('enemies entry is not an object');
    }
    return QuestEnemy.fromJson(json);
  }

  static QuestEnemy? _tryFromJson(Map<String, dynamic> json) {
    try {
      return QuestEnemy.fromJson(json);
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'enemy': {
      'id': enemy.id,
      'name': enemy.name,
      'imagePath': enemy.imagePath,
      'xp': enemy.xp,
    },
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [enemy, quantity];
}

/// Righe «Nx nome» (formato dei «Consigliati», D-02): un tipo per riga,
/// voci dello stesso nemico sommate al primo posto, ordine del BE; il nome
/// nudo solo se la quest ha un solo nemico in tutto (anche contando i senza nome).
List<String> enemyLinesOf(List<QuestEnemy> enemies) {
  final names = <String, String>{};
  final quantities = <String, int>{};
  for (final entry in enemies) {
    final name = entry.enemy.name;
    if (name == null || name.isEmpty) continue;
    final id = entry.enemy.id;
    names.putIfAbsent(id, () => name);
    quantities[id] = (quantities[id] ?? 0) + entry.quantity;
  }
  final total = enemies.fold<int>(0, (sum, entry) => sum + entry.quantity);
  if (names.length == 1 && total == 1) {
    return List.unmodifiable(names.values);
  }
  return List.unmodifiable([
    for (final id in names.keys) quantityLine(quantities[id]!, names[id]!),
  ]);
}

/// Il più forte per il ritratto (D-02): `xp` più alto, `null` vale 0, a
/// parità vince il primo. Il FE non ordina mai le righe per `xp`.
Enemy? strongestEnemyOf(List<QuestEnemy> enemies) {
  Enemy? strongest;
  for (final entry in enemies) {
    if (strongest == null || (entry.enemy.xp ?? 0) > (strongest.xp ?? 0)) {
      strongest = entry.enemy;
    }
  }
  return strongest;
}
