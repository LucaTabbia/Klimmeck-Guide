import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache su disco degli SVG di dominio.
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
}
