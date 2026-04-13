import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:latlong2/latlong.dart';

import 'city.dart';
import 'enums/poi_type.dart';

class PointOfInterest extends Equatable {
  const PointOfInterest({
    required this.id,
    required this.type,
    required this.location,
    required this.city,
    required this.quest,
  });

  final String id;
  final List<PoiType>? type;
  final LatLng? location;
  final City? city;
  final Quest? quest;

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json["id"] as String,
      type: json["type"]?.map((poiType) => PoiType.values.byName(poiType)),
      location: json["location"][0] != null
          ? LatLng(
              (json["location"][0] as num).toDouble(),
              (json["location"][1] as num).toDouble(),
            )
          : null,
      city: json["city"] != null ? City.fromJson(json['city']) : null,
      quest: json["quest"] != null ? Quest.fromJson(json['quest']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.map((s) => s.name).toList(),
    "location": location != null
        ? [location?.latitude, location?.longitude]
        : null,
    "city": city?.toJson(),
    "quest": quest?.toJson(),
  };

  PointOfInterest copyWith({
    String? id,
    List<PoiType>? type,
    LatLng? location,
    dynamic city,
    dynamic quest,
  }) {
    return PointOfInterest(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      city: city ?? this.city,
      quest: quest ?? this.quest,
    );
  }

  @override
  List<Object?> get props => [id, type, location, city, quest];
}
