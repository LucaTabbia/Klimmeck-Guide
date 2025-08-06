import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:latlong2/latlong.dart';

import 'enemy.dart';
import 'loot_item.dart';
import 'lore.dart';

class Quest {
  Quest({
    required this.id,
    required this.title,
    required this.enemy,
    required this.type,
    required this.area,
    required this.requiredPoints,
    required this.markerLocation,
    required this.prizeCoins,
    required this.prizeItem,
    required this.relatedLore,
    required this.xpPrize,
    required this.requiredAdventurers,
    required this.registeredAdventurers,
    required this.requiredLoot,
    required this.randomLoot,
  });

  final int requiredAdventurers;
  final List<Character> registeredAdventurers;
  final List<LootItem> requiredLoot;
  final List<LootItem> randomLoot;
  final String id;
  final String title;
  final Enemy enemy;
  final QuestType type;
  final LatLngBounds area;
  final LatLng markerLocation;
  final int requiredPoints;
  final int prizeCoins;
  final int xpPrize;
  final EquipmentItem prizeItem;
  final List<Lore> relatedLore;

  factory Quest.fromJson(Map<String, dynamic> json) {
    final List<LatLng> points = List<LatLng>.from(
      json['area'].map((x) => LatLng(x['latitude'], x['longitude'])),
    );

    final bounds = LatLngBounds.fromPoints(points);

    return Quest(
      id: json["id"],
      title: json["title"],
      enemy: Enemy.fromJson(json["enemy"]),
      type: QuestType.values.byName(json["type"]),
      markerLocation: LatLng(json["location"]['latitude'], json["location"]['longitude']),
      requiredPoints: json["requiredPoints"].toInt(),
      area: bounds,
      prizeCoins: json["prizeCoins"].toInt(),
      xpPrize: json["xpPrize"].toInt(),
      prizeItem: EquipmentItem.fromJson(json['prizeItem']),
      relatedLore: List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x))),
      requiredAdventurers: json["requiredAdventurers"].toInt(),
      registeredAdventurers: List<Character>.from(
        json['registeredAdventurers'].map((x) => Character.fromJson(x)),
      ),
      requiredLoot: List<LootItem>.from(json['requiredLoot'].map((x) => LootItem.fromJson(x))),
      randomLoot: List<LootItem>.from(json['randomLoot'].map((x) => LootItem.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "enemy": enemy.id,
    "type": type.name,
    "location": markerLocation.toJson(),
    "requiredPoints": requiredPoints,
    "area": [
      {"latitude": area.southWest.latitude, "longitude": area.southWest.longitude},
      {"latitude": area.northEast.latitude, "longitude": area.northEast.longitude},
    ],
    "prizeCoins": prizeCoins,
    "xpPrize": xpPrize,
    "prizeItem": prizeItem.id,
    "relatedLore": relatedLore.map((s) => s.id).toList(),
  };
}
