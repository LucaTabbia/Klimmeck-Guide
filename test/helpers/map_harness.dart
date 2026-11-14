import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'test_app.dart';

/// `FlutterMap` minimale per i test dei layer (nessun layer di tile, nessuna
/// rete), stessa CRS della mappa reale.
Widget mapHarness(
  List<Widget> layers, {
  MapController? controller,
  VoidCallback? onMapReady,
  double initialZoom = 2,
}) => buildTestApp(
  home: SizedBox(
    width: 780,
    height: 360,
    child: FlutterMap(
      mapController: controller,
      options: MapOptions(
        crs: const Epsg4326(),
        initialCenter: const LatLng(0, 0),
        initialZoom: initialZoom,
        onMapReady: onMapReady,
      ),
      children: layers,
    ),
  ),
);
