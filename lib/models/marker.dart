import 'package:latlong2/latlong.dart';

class CustomMarker {
  CustomMarker({
    required this.name,
    required this.coord,
  });

  final String name;
  final LatLng coord;

  factory CustomMarker.fromJson(Map<String, dynamic> json) =>
      CustomMarker(
        name: json["name"],
        coord: json["coord"],
      );

  Map<String, dynamic> toJson() => {
    "title": name,
    "coord": coord,
  };
}