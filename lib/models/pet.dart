import 'dart:io';

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
  final int? buyPrice;
  final int? sellPrice;
  final int? maxXp;
  final int? xp;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json["id"],
    name: json["name"],
    xp: json["xp"] != null ? (json["xp"] as num).toInt() : null,
    maxXp: json["maxXp"] != null ? (json["maxXp"] as num).toInt() : null,
    power: json["power"] != null ? (json["power"] as num).toInt() : null,
    buyPrice: json["buyPrice"] != null ? (json["buyPrice"] as num).toInt() : null,
    sellPrice: json["sellPrice"] != null ? (json["sellPrice"] as num).toInt() : null,
    imagePath: json["imagePath"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "xp": xp,
    "maxXp": maxXp,
    "power": power,
    "buyPrice": buyPrice,
    "sellPrice": sellPrice,
    "imagePath": imagePath,
  };
}
