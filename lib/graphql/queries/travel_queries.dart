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

  /// Anteprima del viaggio automatico di un'accettazione (15-CONTEXT D-01,
  /// BE Phase 14 D-08): owner-only, `null` quando l'accettazione non comporta
  /// un viaggio (marker uguale alla posizione o salto istantaneo).
  static const String getQuestTravelPreview =
      '''
    query GetQuestTravelPreview(\$request: AcceptQuestRequest!) {
      questTravelPreview(request: \$request) {
        ${TravelPreviewFragment.fields}
      }
    }''';
}
