import 'dart:io';

import 'coins.dart';

class Pet {
  Pet({
    required this.id,
    required this.name,
    required this.power,
    required this.buyPrice,
    required this.sellPrice,
    required this.xp,
    required this.maxXp,
    required this.imagePath,
  });

  final String? imagePath;
  final String id;
  final String? name;
  final int? power;
  final Coins? buyPrice;
  final Coins? sellPrice;
  final int? maxXp;
  final int? xp;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json["id"],
    name: json["name"],
    xp: json["xp"] != null ? (json["xp"] as num).toInt() : null,
    maxXp: json["maxXp"] != null ? (json["maxXp"] as num).toInt() : null,
    power: json["power"] != null ? (json["power"] as num).toInt() : null,
    sellPrice: json['sellPrice'] != null ? Coins.fromJson(json['sellPrice']) : null,
    buyPrice: json['buyPrice'] != null ? Coins.fromJson(json['buyPrice']) : null,
    imagePath: json["imagePath"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "xp": xp,
    "maxXp": maxXp,
    "power": power,
    "buyPrice": buyPrice?.toJson(),
    "sellPrice": sellPrice?.toJson(),
    "imagePath": imagePath,
  };
}
