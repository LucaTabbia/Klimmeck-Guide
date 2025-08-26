import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'character.dart';
import 'enemy.dart';
import 'enums/quest_type.dart';
import 'enums/title_type.dart';
import 'equipment_item.dart';
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
    required this.minTitle,
  });

  final int? requiredAdventurers;
  final List<Character>? registeredAdventurers;
  final List<LootItem>? requiredLoot;
  final List<LootItem>? randomLoot;
  final String id;
  final String? title;
  final Enemy? enemy;
  final QuestType? type;
  final LatLngBounds? area;
  final LatLng? markerLocation;
  final int? requiredPoints;
  final int? prizeCoins;
  final int? xpPrize;
  final EquipmentItem? prizeItem;
  final List<Lore>? relatedLore;
  final TitleType? minTitle;

  factory Quest.fromJson(Map<String, dynamic> json) {
    final bounds = json['area'] != null
        ? LatLngBounds.fromPoints(
            List<LatLng>.from(json['area'].map((x) => LatLng(x['latitude'], x['longitude']))),
          )
        : null;

    return Quest(
      id: json["id"],
      title: json["title"],
      enemy: json["enemy"] != null ? Enemy.fromJson(json["enemy"]) : null,
      type: json["type"] != null ? QuestType.values.byName(json["type"]) : null,
      markerLocation: json["location"] != null
          ? LatLng(json["location"]['latitude'], json["location"]['longitude'])
          : null,
      requiredPoints: (json["requiredPoints"] as num?)?.toInt(),
      area: bounds,
      prizeCoins: (json["prizeCoins"] as num?)?.toInt(),
      xpPrize: (json["xpPrize"] as num?)?.toInt(),
      prizeItem: json["prizeItem"] != null ? EquipmentItem.fromJson(json['prizeItem']) : null,
      relatedLore: json['relatedLore'] != null
          ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
          : null,
      requiredAdventurers: (json["requiredAdventurers"] as num?)?.toInt(),
      registeredAdventurers: json['registeredAdventurers'] != null
          ? List<Character>.from(json['registeredAdventurers'].map((x) => Character.fromJson(x)))
          : null,
      requiredLoot: json['requiredLoot'] != null
          ? List<LootItem>.from(json['requiredLoot'].map((x) => LootItem.fromJson(x)))
          : null,
      randomLoot: json['randomLoot'] != null
          ? List<LootItem>.from(json['randomLoot'].map((x) => LootItem.fromJson(x)))
          : null,
      minTitle: json['minTitle'] != null ? TitleType.values.byName(json['minTitle']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "enemy": enemy?.id,
    "type": type?.name,
    "location": markerLocation != null
        ? {"latitude": markerLocation!.latitude, "longitude": markerLocation!.longitude}
        : null,
    "requiredPoints": requiredPoints,
    "area": area != null
        ? [
            {"latitude": area!.southWest.latitude, "longitude": area!.southWest.longitude},
            {"latitude": area!.northEast.latitude, "longitude": area!.northEast.longitude},
          ]
        : null,
    "prizeCoins": prizeCoins,
    "xpPrize": xpPrize,
    "prizeItem": prizeItem?.id,
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "requiredAdventurers": requiredAdventurers,
    "registeredAdventurers": registeredAdventurers?.map((s) => s.id).toList(),
    "requiredLoot": requiredLoot?.map((s) => s.id).toList(),
    "randomLoot": randomLoot?.map((s) => s.id).toList(),
    "minTitle": minTitle?.name,
  };
}
