import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/damages.dart';

import 'coins.dart';

class Pet extends Equatable {
  const Pet({
    required this.id,
    required this.name,
    required this.damages,
    required this.buyPrice,
    required this.sellPrice,
    required this.xp,
    required this.maxXp,
    required this.imagePath,
    required this.currentLifePoints,
    required this.maxLifePoints,
    this.speedModifier,
    this.sellable,
  });

  final String? imagePath;
  final String id;
  final String? name;
  final Damages? damages;
  final Coins? buyPrice;
  final Coins? sellPrice;
  final int? maxXp;
  final int? xp;
  final int? currentLifePoints;
  final int? maxLifePoints;

  /// Moltiplicatore servito dal BE: null per un compagno non da sella (D-07); il FE non calcola mai la velocità (D-11).
  final double? speedModifier;
  final bool? sellable;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json["id"],
    name: json["name"],
    xp: json["xp"] != null ? (json["xp"] as num).toInt() : null,
    maxXp: json["maxXp"] != null ? (json["maxXp"] as num).toInt() : null,
    damages: json["damages"] != null ? Damages.fromJson(json["damages"]) : null,
    sellPrice: json['sellPrice'] != null
        ? Coins.fromJson(json['sellPrice'])
        : null,
    buyPrice: json['buyPrice'] != null
        ? Coins.fromJson(json['buyPrice'])
        : null,
    imagePath: json["imagePath"],
    currentLifePoints: json["currentLifePoints"]?.toInt(),
    maxLifePoints: json["maxLifePoints"]?.toInt(),
    speedModifier: (json['speedModifier'] as num?)?.toDouble(),
    sellable: json['sellable'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "xp": xp,
    "maxXp": maxXp,
    "damages": damages?.toJson(),
    "buyPrice": buyPrice?.toJson(),
    "sellPrice": sellPrice?.toJson(),
    "currentLifePoints": currentLifePoints,
    "maxLifePoints": maxLifePoints,
    "imagePath": imagePath,
    "speedModifier": speedModifier,
    "sellable": sellable,
  };

  Pet copyWith({
    String? imagePath,
    String? id,
    String? name,
    Damages? damages,
    Coins? buyPrice,
    Coins? sellPrice,
    int? maxXp,
    int? xp,
    int? currentLifePoints,
    int? maxLifePoints,
    double? speedModifier,
    bool? sellable,
  }) {
    return Pet(
      imagePath: imagePath ?? this.imagePath,
      id: id ?? this.id,
      name: name ?? this.name,
      damages: damages ?? this.damages,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      maxXp: maxXp ?? this.maxXp,
      xp: xp ?? this.xp,
      currentLifePoints: currentLifePoints ?? this.currentLifePoints,
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
    damages,
    buyPrice,
    sellPrice,
    maxXp,
    xp,
    currentLifePoints,
    maxLifePoints,
    speedModifier,
    sellable,
  ];
}
