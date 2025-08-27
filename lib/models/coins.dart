class Coins {
  Coins({required this.gold, required this.silver, required this.copper});

  final int? gold;
  final int? silver;
  final int? copper;

  factory Coins.fromJson(Map<String, dynamic> json) {
    return Coins(
      gold: json["gold"]?.toInt(),
      silver: json["silver"]?.toInt(),
      copper: json["copper"]?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {"gold": gold, "silver": silver, "copper": copper};
}
