import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:latlong2/latlong.dart';

class Lore {
  Lore({
    required this.image,
    required this.id,
    required this.locations,
    required this.type,
    required this.name,
    required this.description,
    required this.relatedLore,
    required this.unlocked,
  });

  final String id;
  final LoreType? type;
  final String? image;
  final List<LatLng>? locations;
  final String? name;
  final String? description;
  final List<Lore>? relatedLore;
  bool? unlocked;

  factory Lore.fromJson(Map<String, dynamic> json) => Lore(
    id: json["id"],
    type: json["type"] != null ? LoreType.values.byName(json["type"]) : null,
    locations: json['locations'] != null
        ? List<LatLng>.from(json['locations'].map((x) => LatLng(x['latitude'], x['longitude'])))
        : [],
    name: json["name"],
    description: json["description"],
    relatedLore: json['relatedLore'] != null
        ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
        : [],
    unlocked: json["unlocked"] ?? false,
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.name,
    "name": name,
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "description": description,
    "locations": locations?.map((s) => {"latitude": s.latitude, "longitude": s.longitude}).toList(),
    "unlocked": unlocked,
    "image": image,
  };
}
