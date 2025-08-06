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
  final CityType type;
  final LatLngBounds area;
  final String name;
  final LatLng markerLocation;
  final List<Lore> relatedLore;

  factory City.fromJson(Map<String, dynamic> json) {
    final List<LatLng> points = List<LatLng>.from(
      json['area'].map((x) => LatLng(x['latitude'], x['longitude'])),
    );

    final bounds = LatLngBounds.fromPoints(points);

    return City(
      id: json["id"],
      type: CityType.values.byName(json["type"]),
      area: bounds,
      name: json["name"],
      markerLocation: LatLng(
        json['markerLocation']['latitude'],
        json['markerLocation']['longitude'],
      ),
      relatedLore: List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type.name,
    "name": name,
    "markerLocation": {"latitude": markerLocation.latitude, "longitude": markerLocation.longitude},
    "area": [
      {"latitude": area.southWest.latitude, "longitude": area.southWest.longitude},
      {"latitude": area.northEast.latitude, "longitude": area.northEast.longitude},
    ],
    "relatedLore": relatedLore.map((lore) => lore.toJson()).toList(),
  };
}
