import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';

class MapUtils {
  MapUtils._();

  static bool pointInPolygon(double lat, double lon, List<LatLng> polygon) {
    if (polygon.isEmpty) return false;

    bool inside = false;

    final List<LatLng> closedPolygon = List.from(polygon);
    if (closedPolygon.length > 1 &&
        (closedPolygon.first.latitude != closedPolygon.last.latitude ||
            closedPolygon.first.longitude != closedPolygon.last.longitude)) {
      closedPolygon.add(closedPolygon.first);
    }

    for (int i = 0, j = closedPolygon.length - 1; i < closedPolygon.length; j = i++) {
      final double yi = closedPolygon[i].latitude;
      final double xi = closedPolygon[i].longitude;
      final double yj = closedPolygon[j].latitude;
      final double xj = closedPolygon[j].longitude;

      final double denominator = (yj - yi).abs() < 1e-12 ? 1e-12 : (yj - yi);
      final bool intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / denominator + xi);

      if (intersect) inside = !inside;
    }

    return inside;
  }

  static City? findNearestCity(LatLng point, List<City> cities) {
    if (cities.isEmpty) return null;

    City? nearestCity;
    double minDistanceSquared = double.infinity;

    for (final city in cities) {
      final markerLocation = city.markerLocation?.location;
      if (markerLocation == null) continue;

      final distanceSquared =
          math.pow(markerLocation.latitude - point.latitude, 2) +
              math.pow(markerLocation.longitude - point.longitude, 2);

      if (distanceSquared < minDistanceSquared) {
        minDistanceSquared = distanceSquared.toDouble();
        nearestCity = city;
      }
    }

    return nearestCity;
  }

  static City? findCityContainingPoint(LatLng point, List<City> cities) {
    for (final city in cities) {
      final area = city.area;
      if (area != null && area.isNotEmpty) {
        if (pointInPolygon(point.latitude, point.longitude, area)) {
          return city;
        }
      }
    }
    return null;
  }

  static LatLng clampToBounds(LatLng point, LatLngBounds bounds) {
    return LatLng(
      point.latitude.clamp(bounds.south, bounds.north),
      point.longitude.clamp(bounds.west, bounds.east),
    );
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

