import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Foglio di pergamena che sale dal basso. Prima si apre a schermo intero,
/// poi lascia scorrere le liste che contiene; una lista tirata giù dalla
/// cima riabbassa il foglio.
class PaperSheetModal extends StatefulWidget {
  const PaperSheetModal({super.key, required this.child});

  final Widget child;

  static const Key sheetKey = ValueKey('paper_sheet');

  /// Parte della pergamena (quadrata, larga quanto lo schermo) che si può
  /// mostrare: il rotolo in fondo resta sempre fuori.
  static const double visiblePaperFraction = 0.92;

  /// Spazio fra la fine del contenuto e il bordo inferiore della pergamena.
  static const double contentBottomMargin = 23;

  @override
  State<PaperSheetModal> createState() => _PaperSheetModalState();
}

class _PaperSheetModalState extends State<PaperSheetModal> {
  static const double _initialSize = 0.5;
  static const double _minSize = 0.3;
  static const double _maxSize = 1;

  final DraggableScrollableController _sheet = DraggableScrollableController();

  bool _isFull = false;

  /// Una lista che ha già preso il gesto lo tiene fino al rilascio, anche
  /// mentre il foglio si riabbassa sotto il dito.
  bool _isListDragging = false;

  bool get _areListsUnlocked => _isFull || _isListDragging;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paperHeight = size.width * PaperSheetModal.visiblePaperFraction;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onSheetMoved,
      child: DraggableScrollableSheet(
        controller: _sheet,
        expand: true,
        initialChildSize: _initialSize,
        minChildSize: _minSize,
        maxChildSize: _maxSize,
        builder: (context, scrollController) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                _onListScrolled(notification, scrollController, size.height),
            child: PaperSheetScope(
              areListsUnlocked: _areListsUnlocked,
              child: Container(
                key: PaperSheetModal.sheetKey,
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    height: paperHeight,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: CachedSvg(
                            url: CloudinaryAssets.url(
                              CloudinaryAssets.bottomEmptySheet,
                            ),
                            width: size.width,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width / 7,
                          ),
                          child: SizedBox(
                            height: paperHeight,
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _onSheetMoved(DraggableScrollableNotification notification) {
    final isFull = notification.extent >= notification.maxExtent - 0.001;
    if (isFull != _isFull) setState(() => _isFull = isFull);
    return false;
  }

  /// Solo le liste annidate (profondità > 0): lo scroll del foglio stesso
  /// ha profondità 0.
  bool _onListScrolled(
    ScrollNotification notification,
    ScrollController paper,
    double screenHeight,
  ) {
    if (notification.depth == 0) return false;
    switch (notification) {
      case ScrollStartNotification(dragDetails: _?):
        setState(() => _isListDragging = true);
      case ScrollEndNotification():
        setState(() => _isListDragging = false);
      case OverscrollNotification(:final overscroll, dragDetails: _?)
          when overscroll < 0:
        _pullDown(-overscroll, paper, screenHeight);
      case OverscrollNotification(:final overscroll, dragDetails: _?)
          when overscroll > 0:
        _pushPaperOn(overscroll, paper);
      default:
        break;
    }
    return false;
  }

  /// Un gesto verso il basso oltre la cima di una lista riporta prima in
  /// cima la pergamena, poi abbassa il foglio: un foglio che scende con la
  /// carta ancora scorsa ne taglierebbe l'inizio.
  void _pullDown(double distance, ScrollController paper, double screenHeight) {
    final scrolledPaper = paper.hasClients ? paper.position.pixels : 0.0;
    if (scrolledPaper > 0) {
      paper.position.jumpTo(math.max(0, scrolledPaper - distance));
      return;
    }
    _lowerSheetBy(distance / screenHeight);
  }

  /// Una lista spinta oltre la fine fa avanzare la pergamena, fino al suo
  /// fondo.
  void _pushPaperOn(double distance, ScrollController paper) {
    if (!paper.hasClients) return;
    final position = paper.position;
    position.jumpTo(
      math.min(position.maxScrollExtent, position.pixels + distance),
    );
  }

  void _lowerSheetBy(double fraction) {
    if (!_sheet.isAttached) return;
    _sheet.jumpTo((_sheet.size - fraction).clamp(_minSize, _maxSize));
  }
}

/// Dice alle liste dentro un [PaperSheetModal] se possono scorrere: finché
/// il foglio non è a schermo intero il gesto spetta al foglio.
class PaperSheetScope extends InheritedWidget {
  const PaperSheetScope({
    super.key,
    required this.areListsUnlocked,
    required super.child,
  });

  final bool areListsUnlocked;

  /// Fisica di una lista annidata: ferma mentre il foglio sale, che non
  /// rimbalza in cima (il gesto oltre la cima riabbassa il foglio). Fuori da
  /// un foglio, la fisica di sempre.
  static ScrollPhysics? listPhysicsOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaperSheetScope>();
    if (scope == null) return null;
    return scope.areListsUnlocked
        ? const ClampingScrollPhysics()
        : const NeverScrollableScrollPhysics();
  }

  @override
  bool updateShouldNotify(PaperSheetScope oldWidget) =>
      areListsUnlocked != oldWidget.areListsUnlocked;
}
