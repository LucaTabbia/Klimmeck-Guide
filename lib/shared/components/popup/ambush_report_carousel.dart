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
/// sinistra dalle successive) e all'apertura il carosello fa un breve
/// movimento in avanti e torna sulla prima pagina; un solo report occupa
/// tutta la larghezza e non si muove.
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

  /// D-19: il nudge d'apertura trasla le pagine (non la posizione di scroll,
  /// che durante un'animazione ignorerebbe i tap) di al più questa distanza,
  /// avanti in `nudgeOut` e indietro in `nudgeBack`; non cambia mai pagina.
  static const double nudgeDistance = 28;
  static const Duration nudgeOut = Duration(milliseconds: 240);
  static const Duration nudgeBack = Duration(milliseconds: 280);

  /// Ordine della coda (per `resolvedAt`, D-05): il carosello non riordina.
  final List<QuestResult> results;
  final VoidCallback onContinue;

  @override
  State<AmbushReportCarousel> createState() => _AmbushReportCarouselState();
}

class _AmbushReportCarouselState extends State<AmbushReportCarousel> {
  /// Spostamento del nudge lungo la sua durata: avanti con easeOut, indietro
  /// con easeIn, da zero a zero.
  static final Animatable<double> _nudgeTravel = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: AmbushReportCarousel.nudgeDistance,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: AmbushReportCarousel.nudgeOut.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: AmbushReportCarousel.nudgeDistance,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: AmbushReportCarousel.nudgeBack.inMilliseconds.toDouble(),
    ),
  ]);

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
  Widget build(BuildContext context) {
    final pages = _pages();
    if (!_hasSeveralReports) return pages;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AmbushReportCarousel.nudgeOut + AmbushReportCarousel.nudgeBack,
      child: pages,
      builder: (context, progress, child) => Transform.translate(
        offset: Offset(-_nudgeTravel.transform(progress), 0),
        child: child,
      ),
    );
  }

  /// `Clip.none`: durante il nudge la striscia della pagina vicina entra nel
  /// bordo liberato invece di restare tagliata al limite della viewport.
  Widget _pages() => PageView(
    key: AmbushReportCarousel.pagesKey,
    controller: _controller,
    clipBehavior: Clip.none,
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
