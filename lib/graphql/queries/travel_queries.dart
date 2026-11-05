import '../fragments/fragments.dart';

class TravelQueries {
  /// Anteprima del viaggio libero verso il marker di una città: distanza,
  /// durata, rotta, cibo e vita persa, nessuna scrittura (BE Phase 8 §4,
  /// BE Phase 14).
  static const String getTravelPreview =
      '''
    query GetTravelPreview(\$request: TravelRequest!) {
      travelPreview(request: \$request) {
        ${TravelPreviewFragment.fields}
      }
    }''';
}
