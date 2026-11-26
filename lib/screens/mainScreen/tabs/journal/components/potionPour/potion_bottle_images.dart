import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// I livelli disegnati della boccetta (Phase 26 D-04), dal bundle: per la
/// boccetta tappata a riposo e per quella aperta, il vetro sotto il liquido e
/// sopra il liquido tutto ciò che non è vetro (contorno, corde, etichetta);
/// il tappo a parte, per quando salta via.
class PotionBottleImages {
  const PotionBottleImages({
    required this.glass,
    required this.overlay,
    required this.cork,
    required this.corkedGlass,
    required this.corkedOverlay,
  });

  static const String glassAsset = 'assets/images/potion_glass.png';
  static const String overlayAsset = 'assets/images/potion_overlay.png';
  static const String corkAsset = 'assets/images/potion_cork.png';
  static const String corkedGlassAsset =
      'assets/images/potion_glass_corked.png';
  static const String corkedOverlayAsset =
      'assets/images/potion_overlay_corked.png';

  final ui.Image glass;
  final ui.Image overlay;
  final ui.Image cork;
  final ui.Image corkedGlass;
  final ui.Image corkedOverlay;

  static Future<PotionBottleImages> load(AssetBundle bundle) async {
    final images = await Future.wait([
      _decode(bundle, glassAsset),
      _decode(bundle, overlayAsset),
      _decode(bundle, corkAsset),
      _decode(bundle, corkedGlassAsset),
      _decode(bundle, corkedOverlayAsset),
    ]);
    return PotionBottleImages(
      glass: images[0],
      overlay: images[1],
      cork: images[2],
      corkedGlass: images[3],
      corkedOverlay: images[4],
    );
  }

  static Future<ui.Image> _decode(AssetBundle bundle, String asset) async {
    final data = await bundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}
