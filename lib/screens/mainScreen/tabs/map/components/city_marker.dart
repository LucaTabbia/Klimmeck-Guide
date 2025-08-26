import 'package:flutter/material.dart';

import '../../../../../models/city.dart';

class CityMarker extends StatefulWidget {
  const CityMarker({super.key, required this.city, required this.zoom, required this.onTap});

  final City city;
  final double zoom;
  final VoidCallback onTap;

  @override
  State<CityMarker> createState() => _CityMarkerState();
}

class _CityMarkerState extends State<CityMarker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(),
      child: Align(
        alignment: Alignment.center,
        child: Image.asset(
          widget.city.image ?? "",
          width: widget.city.size != null ? widget.city.size! * widget.zoom / 2 : 0,
          height: widget.city.size != null ? widget.city.size! * widget.zoom / 2 : 0,
        ),
      ),
    );
  }
}
