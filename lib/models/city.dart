import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'enums/city_type.dart';
import 'lore.dart';

class City {
  City({
    required this.id,
    required this.area,
    required this.type,
    required this.name,
    required this.markerLocation,
    required this.relatedLore,
  });

  final String id;
  final CityType? type;
  final LatLngBounds? area;
  final String? name;
  final LatLng? markerLocation;
  final Lore? relatedLore;

  factory City.fromJson(Map<String, dynamic> json) {
    LatLngBounds? bounds;
    if (json['area'] != null) {
      final List<LatLng> points = List<LatLng>.from(
        json['area'].map(
          (x) => LatLng(
            (x['latitude'] as num).toDouble(),
            (x['longitude'] as num).toDouble(),
          ),
        ),
      );
      if (points.isNotEmpty) {
        bounds = LatLngBounds.fromPoints(points);
      }
    }

    return City(
      id: json["id"],
      type: json["type"] != null ? CityType.values.byName(json["type"]) : null,
      area: bounds,
      name: json["name"],
      markerLocation: json['markerLocation'] != null
          ? LatLng(
              (json['markerLocation']['latitude'] as num).toDouble(),
              (json['markerLocation']['longitude'] as num).toDouble(),
            )
          : null,
      relatedLore: json['relatedLore'] != null
          ? Lore.fromJson(json['relatedLore'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.name,
    "name": name,
    "markerLocation": markerLocation != null
        ? {
            "latitude": markerLocation!.latitude,
            "longitude": markerLocation!.longitude,
          }
        : null,
    "area": area != null
        ? [
            {
              "latitude": area!.southWest.latitude,
              "longitude": area!.southWest.longitude,
            },
            {
              "latitude": area!.northEast.latitude,
              "longitude": area!.northEast.longitude,
            },
          ]
        : null,
    "relatedLore": relatedLore?.toJson(),
  };
}
