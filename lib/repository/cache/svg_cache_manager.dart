import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SvgCacheManager extends CacheManager {
  static const key = "svgCache";

  SvgCacheManager()
    : super(Config(key, stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 300));
}
