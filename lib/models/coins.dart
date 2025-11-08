import 'package:equatable/equatable.dart';

class Coins extends Equatable {
  final int gold;
  final int silver;
  final int copper;

  const Coins({this.gold = 0, this.silver = 0, this.copper = 0});

  factory Coins.fromJson(Map<String, dynamic> json) {
    return Coins(
      gold: json["gold"]?.toInt() ?? 0,
      silver: json["silver"]?.toInt() ?? 0,
      copper: json["copper"]?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "gold": gold,
    "silver": silver,
    "copper": copper,
  };

  Coins normalize() {
    int newCopper = copper;
    int newSilver = silver;
    int newGold = gold;

    newSilver += newCopper ~/ 100;
    newCopper %= 100;

    newGold += newSilver ~/ 100;
    newSilver %= 100;

    return Coins(gold: newGold, silver: newSilver, copper: newCopper);
  }

  Coins operator +(Coins other) {
    return Coins(
      gold: gold + other.gold,
      silver: silver + other.silver,
      copper: copper + other.copper,
    ).normalize();
  }

  Coins operator -(Coins other) {
    int totalCopperA = toCopper();
    int totalCopperB = other.toCopper();
    int result = totalCopperA - totalCopperB;
    return Coins.fromCopper(result);
  }

  int toCopper() => gold * 100 * 100 + silver * 100 + copper;

  factory Coins.fromCopper(int totalCopper) {
    int newGold = totalCopper ~/ 10000;
    int newSilver = (totalCopper % 10000) ~/ 100;
    int newCopper = totalCopper % 100;
    return Coins(gold: newGold, silver: newSilver, copper: newCopper);
  }

  bool canAfford(Coins cost) {
    return toCopper() >= cost.toCopper();
  }

  Coins multiply(int factor) {
    return Coins(
      gold: gold * factor,
      silver: silver * factor,
      copper: copper * factor,
    ).normalize();
  }

  bool operator >=(Coins other) => toCopper() >= other.toCopper();
  bool operator <=(Coins other) => toCopper() <= other.toCopper();
  bool operator >(Coins other) => toCopper() > other.toCopper();
  bool operator <(Coins other) => toCopper() < other.toCopper();

  @override
  String toString() => "${gold}g ${silver}s ${copper}c";

  @override
  List<Object?> get props => [gold, silver, copper];

  Coins copyWith({int? gold, int? silver, int? copper}) {
    return Coins(
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      copper: copper ?? this.copper,
    );
  }
}
