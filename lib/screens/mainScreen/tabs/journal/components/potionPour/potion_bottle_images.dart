import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// I tre livelli disegnati della boccetta (Phase 26 D-04), dal bundle: il
/// vetro sotto il liquido, sopra il liquido tutto ciò che non è vetro
/// (contorno, corde, etichetta), il tappo a parte.
class PotionBottleImages {
  const PotionBottleImages({
    required this.glass,
    required this.overlay,
    required this.cork,
  });

  static const String glassAsset = 'assets/images/potion_glass.png';
  static const String overlayAsset = 'assets/images/potion_overlay.png';
  static const String corkAsset = 'assets/images/potion_cork.png';

  final ui.Image glass;
  final ui.Image overlay;
  final ui.Image cork;

  static Future<PotionBottleImages> load(AssetBundle bundle) async {
    final images = await Future.wait([
      _decode(bundle, glassAsset),
      _decode(bundle, overlayAsset),
      _decode(bundle, corkAsset),
    ]);
    return PotionBottleImages(
      glass: images[0],
      overlay: images[1],
      cork: images[2],
    );
  }

  static Future<ui.Image> _decode(AssetBundle bundle, String asset) async {
    final data = await bundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}
