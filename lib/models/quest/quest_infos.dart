import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../enemy.dart';
import '../enums/quest_type.dart';
import '../lore.dart';

class QuestInfos {
  QuestInfos({
    required this.timeToComplete,
    required this.title,
    required this.enemy,
    required this.type,
    required this.area,
    required this.markerLocation,
    required this.relatedLore,
  });

  final int? timeToComplete;
  final String? title;
  final Enemy? enemy;
  final QuestType? type;
  final LatLngBounds? area;
  final LatLng? markerLocation;
  final List<Lore>? relatedLore;

  factory QuestInfos.fromJson(Map<String, dynamic> json) {
    final bounds = json['area'] != null
        ? LatLngBounds.fromPoints(
            List<LatLng>.from(json['area'].map((x) => LatLng(x['latitude'], x['longitude']))),
          )
        : null;

    return QuestInfos(
      title: json["title"],
      enemy: json["enemy"] != null ? Enemy.fromJson(json["enemy"]) : null,
      type: json["type"] != null ? QuestType.values.byName(json["type"]) : null,
      markerLocation: json["markerLocation"] != null
          ? LatLng(json["markerLocation"]['latitude'], json["markerLocation"]['longitude'])
          : null,
      area: bounds,
      relatedLore: json['relatedLore'] != null
          ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
          : null,
      timeToComplete: (json["timeToComplete"] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "enemy": enemy?.id,
    "type": type?.name,
    "markerLocation": markerLocation != null
        ? {"latitude": markerLocation!.latitude, "longitude": markerLocation!.longitude}
        : null,
    "area": area != null
        ? [
            {"latitude": area!.southWest.latitude, "longitude": area!.southWest.longitude},
            {"latitude": area!.northEast.latitude, "longitude": area!.northEast.longitude},
          ]
        : null,
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "timeToComplete": timeToComplete,
  };
}
