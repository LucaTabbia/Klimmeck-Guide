import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:latlong2/latlong.dart';

import 'enums/city_type.dart';
import 'lore.dart';

class City extends Equatable {
  const City({
    required this.id,
    required this.area,
    required this.type,
    required this.name,
    required this.markerLocation,
    required this.relatedLore,
  });

  final String id;
  final CityType? type;
  final List<LatLng>? area;
  final String? name;
  final PointOfInterest? markerLocation;
  final Lore? relatedLore;

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json["id"],
      type: json["type"] != null ? CityType.values.byName(json["type"]) : null,
      area: json["area"] != null
          ? (json["area"] as List)
                .map(
                  (coords) => LatLng(
                    (coords[0] as num).toDouble(),
                    (coords[1] as num).toDouble(),
                  ),
                )
                .toList()
          : null,
      name: json["name"],
      markerLocation: json["markerLocation"] != null
          ? PointOfInterest.fromJson(json["markerLocation"])
          : null,
      relatedLore: json["relatedLore"] != null
          ? Lore.fromJson(json["relatedLore"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.name,
    "name": name,
    "markerLocation": markerLocation?.toJson(),
    "area": area?.map((p) => [p.latitude, p.longitude]).toList(),
    "relatedLore": relatedLore?.toJson(),
  };

  City copyWith({
    String? id,
    CityType? type,
    List<LatLng>? area,
    String? name,
    PointOfInterest? markerLocation,
    Lore? relatedLore,
  }) {
    return City(
      id: id ?? this.id,
      type: type ?? this.type,
      area: area ?? this.area,
      name: name ?? this.name,
      markerLocation: markerLocation ?? this.markerLocation,
      relatedLore: relatedLore ?? this.relatedLore,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    area,
    name,
    markerLocation,
    relatedLore,
  ];
}
