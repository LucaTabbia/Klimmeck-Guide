import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/enums/city_type.dart';

import '../../../../../models/city.dart';

class CityMarker {
  static Marker build({required City city, required double zoom}) {
    String cityImage = "";
    double citySize = 30;

    switch (city.type) {
      case CityType.drusteaCapital:
        cityImage = "assets/images/cliffbreak.png";
        citySize = 55 * zoom / 2;
        break;
      case CityType.flameCenterCapital:
        cityImage = "assets/images/virnen.png";
        citySize = 40 * zoom / 2;
        break;
      case CityType.necrorianCity:
        cityImage = "assets/images/necrorian.png";
        citySize = 60 * zoom / 2;
        break;
      case CityType.mirwaCapital:
        cityImage = "assets/images/mirwen.png";
        citySize = 60 * zoom / 2;
        break;
      case CityType.flameNorthCapital:
        cityImage = "assets/images/bellport.png";
        citySize = 44 * zoom / 2;
        break;
      case CityType.harkenCity:
        cityImage = "assets/images/ferrion.png";
        citySize = 53 * zoom / 2;
        break;
      case CityType.liberiaCapital:
        cityImage = "assets/images/liberia.png";
        citySize = 50 * zoom / 2;
        break;
      case CityType.motherCapital:
        cityImage = "assets/images/morrulir.png";
        citySize = 60 * zoom / 2;
        break;
      case CityType.valanCapital:
        cityImage = "assets/images/valantar.png";
        citySize = 70 * zoom / 2;
        break;
      case CityType.talmvereVillage:
        cityImage = "assets/images/talmvere.png";
        citySize = 40 * zoom / 2;
        break;
      default:
        break;
    }

    return Marker(
      point: city.markerLocation,
      width: citySize,
      height: citySize,
      child: Align(
        alignment: Alignment.topCenter,
        child: Image.asset(cityImage, width: citySize, height: citySize),
      ),
    );
  }
}
