import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';

/// Carosello dei report d'imboscata di un arrivo (16-CONTEXT D-05, D-13): una
/// pergamena per imboscata in ordine cronologico, «k di N» come indicatore,
/// si sfoglia solo con lo swipe. «Continua» su qualunque pagina chiude il
/// carosello: il presenter conferma tutto il gruppo.
class AmbushReportCarousel extends StatelessWidget {
  const AmbushReportCarousel({
    super.key,
    required this.results,
    required this.onContinue,
  });

  static const Key pagesKey = ValueKey('ambushReportCarousel.pages');

  /// Ordine della coda (per `resolvedAt`, D-05): il carosello non riordina.
  final List<QuestResult> results;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => PageView(
    key: pagesKey,
    children: [
      for (final (index, result) in results.indexed)
        QuestResultSheet(
          key: ValueKey('ambushReportCarousel.page.${result.id}'),
          result: result,
          position: index + 1,
          total: results.length,
          onContinue: onContinue,
        ),
    ],
  );
}
