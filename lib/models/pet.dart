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
  final String name;
  final int power;
  final int buyPrice;
  final int sellPrice;
  final int maxXp;
  final int xp;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json["id"],
    name: json["name"],
    xp: json["xp"].toInt(),
    maxXp: json["maxXp"].toInt(),
    power: json["power"].toInt(),
    buyPrice: json["buyPrice"].toInt(),
    sellPrice: json["sellPrice"].toInt(),
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
