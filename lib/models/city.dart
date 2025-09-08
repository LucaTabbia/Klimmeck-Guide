import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/enums/city_size_type.dart';
import 'package:latlong2/latlong.dart';

import 'enums/city_type.dart';
import 'lore.dart';

class City {
  City({
    required this.id,
    required this.image,
    required this.area,
    required this.type,
    required this.name,
    required this.citySize,
    required this.size,
    required this.markerLocation,
    required this.relatedLore,
  });

  final String id;
  final String? image;
  final CityType? type;
  final CitySizeType? citySize;
  final LatLngBounds? area;
  final String? name;
  final int? size;
  final LatLng? markerLocation;
  final Lore? relatedLore;

  factory City.fromJson(Map<String, dynamic> json) {
    LatLngBounds? bounds;
    if (json['area'] != null) {
      final List<LatLng> points = List<LatLng>.from(
        json['area'].map((x) => LatLng(x['latitude'], x['longitude'])),
      );
      if (points.isNotEmpty) {
        bounds = LatLngBounds.fromPoints(points);
      }
    }

    return City(
      id: json["id"],
      type: json["type"] != null ? CityType.values.byName(json["type"]) : null,
      citySize: json["citySize"] != null ? CitySizeType.values.byName(json["citySize"]) : null,
      area: bounds,
      image: json["image"],
      name: json["name"],
      size: json["size"]?.toInt(),
      markerLocation: json['markerLocation'] != null
          ? LatLng(json['markerLocation']['latitude'], json['markerLocation']['longitude'])
          : null,
      relatedLore: json['relatedLore'] != null ? Lore.fromJson(json['relatedLore']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.name,
    "citySize": citySize?.name,
    "name": name,
    "image": image,
    "size": size,
    "markerLocation": markerLocation != null
        ? {"latitude": markerLocation!.latitude, "longitude": markerLocation!.longitude}
        : null,
    "area": area != null
        ? [
            {"latitude": area!.southWest.latitude, "longitude": area!.southWest.longitude},
            {"latitude": area!.northEast.latitude, "longitude": area!.northEast.longitude},
          ]
        : null,
    "relatedLore": relatedLore?.toJson(),
  };
}
