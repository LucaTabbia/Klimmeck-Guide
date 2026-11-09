import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';

/// Carosello dei report d'imboscata di un arrivo (16-CONTEXT D-05, D-13): una
/// pergamena per imboscata in ordine cronologico, «k di N» come indicatore,
/// si sfoglia solo con lo swipe. «Continua» su qualunque pagina chiude il
/// carosello: il presenter conferma tutto il gruppo.
///
/// D-19: con più report le pagine sono più strette della viewport, così la
/// pergamena vicina fa capolino dal bordo (a destra sulla prima pagina, a
/// sinistra dalle successive); un solo report occupa tutta la larghezza.
class AmbushReportCarousel extends StatefulWidget {
  const AmbushReportCarousel({
    super.key,
    required this.results,
    required this.onContinue,
  });

  static const Key pagesKey = ValueKey('ambushReportCarousel.pages');

  /// D-19: frazione della viewport occupata da ogni slot pagina quando i
  /// report sono più di uno. La pergamena del foglio (315/375, centrata nel
  /// suo slot) è larga circa 0,39 della viewport in landscape: con questo
  /// valore la vicina mostra circa il 7% della larghezza dello schermo.
  static const double peekViewportFraction = 0.62;

  /// Ordine della coda (per `resolvedAt`, D-05): il carosello non riordina.
  final List<QuestResult> results;
  final VoidCallback onContinue;

  @override
  State<AmbushReportCarousel> createState() => _AmbushReportCarouselState();
}

class _AmbushReportCarouselState extends State<AmbushReportCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: _hasSeveralReports
        ? AmbushReportCarousel.peekViewportFraction
        : 1.0,
  );

  bool get _hasSeveralReports => widget.results.length > 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
    key: AmbushReportCarousel.pagesKey,
    controller: _controller,
    children: [
      for (final (index, result) in widget.results.indexed)
        QuestResultSheet(
          key: ValueKey('ambushReportCarousel.page.${result.id}'),
          result: result,
          position: index + 1,
          total: widget.results.length,
          onContinue: widget.onContinue,
        ),
    ],
  );
}
