import 'package:equatable/equatable.dart';

import '../travel/travel_cost_text.dart';
import '../travel/travel_preview.dart';

/// Riga «Viaggio» del foglio missione (15-CONTEXT D-04): il cibo e la vita
/// del viaggio automatico verso il marker, dall'anteprima del BE. Rossa e
/// swipe spento quando il BE dice che il personaggio non arriverebbe vivo.
class QuestTravelLine extends Equatable {
  const QuestTravelLine({required this.text, required this.isStarving});

  static const String _prefix = 'Viaggio: ';
  static const String _separator = ' · ';

  /// `null` = nessuna anteprima (in attesa, fallita, nessun viaggio, sola
  /// lettura): la riga non c'è.
  static QuestTravelLine? of(TravelPreview? preview) {
    if (preview == null) return null;
    if (!preview.arrivesAlive) {
      return const QuestTravelLine(
        text: '$_prefix$starvingPhrase',
        isStarving: true,
      );
    }
    final food = foodText(preview.food, empty: noFoodLineText);
    return QuestTravelLine(
      text: '$_prefix$food$_separator${lifeText(preview)}',
      isStarving: false,
    );
  }

  final String text;
  final bool isStarving;

  @override
  List<Object?> get props => [text, isStarving];
}
