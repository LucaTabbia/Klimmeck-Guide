import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/city.dart';

class CityMarker extends StatefulWidget {
  const CityMarker({super.key, required this.city, required this.onTap});

  final City city;
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
        child: CachedSvg(
          url: widget.city.image ?? "",
          width: widget.city.size!.toDouble(),
          height: widget.city.size!.toDouble(),
        ),
      ),
    );
  }
}
