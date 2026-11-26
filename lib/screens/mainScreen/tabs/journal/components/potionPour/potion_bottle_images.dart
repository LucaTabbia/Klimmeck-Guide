import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// I tre livelli disegnati della boccetta (Phase 26 D-04), dal bundle.
class PotionBottleImages {
  const PotionBottleImages({
    required this.glass,
    required this.label,
    required this.cork,
  });

  static const String glassAsset = 'assets/images/potion_glass.png';
  static const String labelAsset = 'assets/images/potion_label.png';
  static const String corkAsset = 'assets/images/potion_cork.png';

  final ui.Image glass;
  final ui.Image label;
  final ui.Image cork;

  static Future<PotionBottleImages> load(AssetBundle bundle) async {
    final images = await Future.wait([
      _decode(bundle, glassAsset),
      _decode(bundle, labelAsset),
      _decode(bundle, corkAsset),
    ]);
    return PotionBottleImages(
      glass: images[0],
      label: images[1],
      cork: images[2],
    );
  }

  static Future<ui.Image> _decode(AssetBundle bundle, String asset) async {
    final data = await bundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}
