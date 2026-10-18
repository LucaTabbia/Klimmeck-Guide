import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';

class SatchelEntry extends Equatable {
  const SatchelEntry({
    required this.pageIndex,
    required this.label,
    required this.assetPath,
    required this.column,
    required this.row,
    this.rowSpan = 1,
  });

  final int pageIndex;
  final String label;
  final String assetPath;
  final int column;
  final int row;
  final int rowSpan;

  @override
  List<Object?> get props => [
    pageIndex,
    label,
    assetPath,
    column,
    row,
    rowSpan,
  ];
}

/// Unica tabella della borsa: etichette, icone, pagine e geometria (D-01).
abstract final class SatchelLayout {
  static const int columns = 4;
  static const int rows = 2;
  static const double borderWidth = 2;

  /// 150 di etichetta "Chiudi il menù" + 2 di bordo.
  static const double closeColumnWidth = 152;
  static const double maxCellWidth = 152;

  static const List<SatchelEntry> entries = [
    SatchelEntry(
      pageIndex: 0,
      label: 'Mappa',
      assetPath: CloudinaryAssets.map,
      column: 0,
      row: 0,
      rowSpan: 2,
    ),
    SatchelEntry(
      pageIndex: 1,
      label: 'Profilo',
      assetPath: CloudinaryAssets.mirror,
      column: 1,
      row: 0,
    ),
    SatchelEntry(
      pageIndex: 2,
      label: 'Diario',
      assetPath: CloudinaryAssets.journal,
      column: 2,
      row: 0,
    ),
    SatchelEntry(
      pageIndex: 3,
      label: 'Libreria',
      assetPath: CloudinaryAssets.library,
      column: 3,
      row: 0,
    ),
    SatchelEntry(
      pageIndex: 4,
      label: 'Bacheca',
      assetPath: CloudinaryAssets.board,
      column: 1,
      row: 1,
    ),
    SatchelEntry(
      pageIndex: 5,
      label: 'Negozio',
      assetPath: CloudinaryAssets.shop,
      column: 2,
      row: 1,
    ),
    SatchelEntry(
      pageIndex: 6,
      label: 'Impostazioni',
      assetPath: CloudinaryAssets.settings,
      column: 3,
      row: 1,
    ),
  ];

  static double cellWidth(double screenWidth) =>
      math.min(maxCellWidth, (screenWidth - closeColumnWidth) / columns);

  static Offset centerOf(SatchelEntry entry, Size screen) {
    final cellW = cellWidth(screen.width);
    final rowH = screen.height / rows;
    return Offset(
      closeColumnWidth + (entry.column + 0.5) * cellW,
      (entry.row + entry.rowSpan / 2) * rowH,
    );
  }

  /// Punto d'arrivo nel frame di MenuItem (Stack bottomLeft, translate dall'angolo in basso a sinistra).
  static Offset flightEnd(SatchelEntry entry, Size screen, double itemSize) {
    final center = centerOf(entry, screen);
    return Offset(
      center.dx - itemSize / 2,
      -(screen.height - center.dy) + itemSize / 2,
    );
  }
}
