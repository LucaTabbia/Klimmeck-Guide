/// Constants used throughout the map feature.
class MapConstants {
  MapConstants._();

  static const double capitalVisibleZoom = 0;
  static const double cityVisibleZoom = 2.5;
  static const double villageVisibleZoom = 3.2;
  static const double questVisibleZoom = 4;

  static const double initialZoom = 2;
  static const double minZoom = 0;

  static const double maxZoom = 5;

  static const Duration mapAnimationDuration = Duration(milliseconds: 100);
  static const Duration questSheetAnimationDuration = Duration(milliseconds: 300);

  static const Duration smoothScrollInterval = Duration(milliseconds: 16);

  static const double scrollAcceleration = 0.01;
  static const double scrollDamping = 0.8;

  static const double animationStopThreshold = 0.001;

  static const double characterMarkerSize = 60;

  /// Inquadratura della rotta d'anteprima sopra il foglio di conferma (D-04).
  static const double previewRoutePadding = 48;
  static const double previewSheetHeightFraction = 0.5;
  static const double previewSheetGap = 24;
}

