import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/damages.dart';

import 'coins.dart';
import 'enums/rarity_type.dart';

class Pet extends Equatable {
  const Pet({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.maxXp,
    required this.imagePath,
    required this.maxLifePoints,
    this.attack,
    this.defense,
    this.rarity,
    this.speedModifier,
    this.sellable,
  });

  final String? imagePath;
  final String id;
  final String? name;
  final Damages? attack;
  final Damages? defense;
  final RarityType? rarity;
  final Coins? buyPrice;
  final Coins? sellPrice;
  final int? maxXp;
  final int? maxLifePoints;

  /// Moltiplicatore servito dal BE: null per un compagno non da sella (D-07); il FE non calcola mai la velocità (D-11).
  final double? speedModifier;
  final bool? sellable;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json["id"],
    name: json["name"],
    maxXp: json["maxXp"] != null ? (json["maxXp"] as num).toInt() : null,
    attack: _damagesFrom(json['attack']),
    defense: _damagesFrom(json['defense']),
    rarity: RarityType.values.asNameMap()[json['rarity']],
    sellPrice: json['sellPrice'] != null
        ? Coins.fromJson(json['sellPrice'])
        : null,
    buyPrice: json['buyPrice'] != null
        ? Coins.fromJson(json['buyPrice'])
        : null,
    imagePath: json["imagePath"],
    maxLifePoints: json["maxLifePoints"]?.toInt(),
    speedModifier: (json['speedModifier'] as num?)?.toDouble(),
    sellable: json['sellable'] as bool?,
  );

  static Damages? _damagesFrom(Object? json) =>
      json is Map<String, dynamic> ? Damages.fromJson(json) : null;

  /// Compagno da un riferimento tollerante (premio o ricompensa, D-06/D-07):
  /// null se non è una mappa con un `id` stringa.
  static Pet? tryFromJson(Object? json) =>
      json is Map<String, dynamic> && json['id'] is String
      ? Pet.fromJson(json)
      : null;

  /// Confine di lista o di slot (posseduti, pool del negozio, equipaggiato):
  /// un compagno che non si legge vale null invece di far fallire chi lo
  /// contiene.
  static Pet? tryFromEntryJson(Object? json) {
    try {
      return tryFromJson(json);
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "maxXp": maxXp,
    "attack": attack?.toJson(),
    "defense": defense?.toJson(),
    "rarity": rarity?.name,
    "buyPrice": buyPrice?.toJson(),
    "sellPrice": sellPrice?.toJson(),
    "maxLifePoints": maxLifePoints,
    "imagePath": imagePath,
    "speedModifier": speedModifier,
    "sellable": sellable,
  };

  Pet copyWith({
    String? imagePath,
    String? id,
    String? name,
    Damages? attack,
    Damages? defense,
    RarityType? rarity,
    Coins? buyPrice,
    Coins? sellPrice,
    int? maxXp,
    int? maxLifePoints,
    double? speedModifier,
    bool? sellable,
  }) {
    return Pet(
      imagePath: imagePath ?? this.imagePath,
      id: id ?? this.id,
      name: name ?? this.name,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      rarity: rarity ?? this.rarity,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      maxXp: maxXp ?? this.maxXp,
      maxLifePoints: maxLifePoints ?? this.maxLifePoints,
      speedModifier: speedModifier ?? this.speedModifier,
      sellable: sellable ?? this.sellable,
    );
  }

  @override
  List<Object?> get props => [
    imagePath,
    id,
    name,
    attack,
    defense,
    rarity,
    buyPrice,
    sellPrice,
    maxXp,
    maxLifePoints,
    speedModifier,
    sellable,
  ];
}
