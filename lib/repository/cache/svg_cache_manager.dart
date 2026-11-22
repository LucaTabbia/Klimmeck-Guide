import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'raster_delivery.dart';

/// Cache su disco delle immagini di dominio.
///
/// Il tetto di oggetti copre l'intero mondo (542 lore + 206 nemici) così il
/// riscaldamento al boot non sfratta le immagini appena scaricate (Phase 17 D-22).
class SvgCacheManager extends CacheManager {
  static const key = "svgCache";
  static const int maxObjects = 2000;

  SvgCacheManager()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: maxObjects,
        ),
      );

  /// File dell'immagine di dominio [url], nella sua consegna raster.
  Future<File> imageFile(String url) => getSingleFile(rasterDeliveryUrl(url));
}
