part of 'map_availability_cubit.dart';

/// «Mappa visibile e libera» (09-CONTEXT D-07/D-23): unico segnale che la coda
/// dei risultati ascolta. Parte fuori dalla mappa finché il MainScreen non la
/// dichiara (la pagina iniziale non chiama onPageChanged, F1).
final class MapAvailabilityState extends Equatable {
  const MapAvailabilityState({
    this.isMapPage = false,
    this.isRouteCovered = false,
    this.isQuestSheetOpen = false,
    this.isPawnDragging = false,
    this.isTeleportMode = false,
  });

  final bool isMapPage;

  /// Una route (foglio, dialog, conferma) sopra la shell sul Navigator radice.
  final bool isRouteCovered;

  /// Foglio quest aperto sulla mappa (overlay in-tree di WorldMap).
  final bool isQuestSheetOpen;

  final bool isPawnDragging;

  /// Modalità teletrasporto del GM sulla Mappa (10-CONTEXT C13): nessun foglio
  /// esiti sopra il flusso.
  final bool isTeleportMode;

  bool get isFree => !isRouteCovered && isFreeBeneathRoutes;

  /// Libera a parte le route sopra la shell: il presenter la usa sotto il
  /// proprio foglio esiti (09-REVIEW IN-03).
  bool get isFreeBeneathRoutes =>
      isMapPage && !isQuestSheetOpen && !isPawnDragging && !isTeleportMode;

  MapAvailabilityState copyWith({
    bool? isMapPage,
    bool? isRouteCovered,
    bool? isQuestSheetOpen,
    bool? isPawnDragging,
    bool? isTeleportMode,
  }) => MapAvailabilityState(
    isMapPage: isMapPage ?? this.isMapPage,
    isRouteCovered: isRouteCovered ?? this.isRouteCovered,
    isQuestSheetOpen: isQuestSheetOpen ?? this.isQuestSheetOpen,
    isPawnDragging: isPawnDragging ?? this.isPawnDragging,
    isTeleportMode: isTeleportMode ?? this.isTeleportMode,
  );

  @override
  List<Object?> get props => [
    isMapPage,
    isRouteCovered,
    isQuestSheetOpen,
    isPawnDragging,
    isTeleportMode,
  ];
}
