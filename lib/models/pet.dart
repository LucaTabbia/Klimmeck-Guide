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
  ];
}
