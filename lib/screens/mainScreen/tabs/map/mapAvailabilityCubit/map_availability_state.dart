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
  });

  final bool isMapPage;

  /// Una route (foglio, dialog, conferma) sopra la shell sul Navigator radice.
  final bool isRouteCovered;

  /// Foglio quest aperto sulla mappa (overlay in-tree di WorldMap).
  final bool isQuestSheetOpen;

  final bool isPawnDragging;

  bool get isFree =>
      isMapPage && !isRouteCovered && !isQuestSheetOpen && !isPawnDragging;

  MapAvailabilityState copyWith({
    bool? isMapPage,
    bool? isRouteCovered,
    bool? isQuestSheetOpen,
    bool? isPawnDragging,
  }) => MapAvailabilityState(
    isMapPage: isMapPage ?? this.isMapPage,
    isRouteCovered: isRouteCovered ?? this.isRouteCovered,
    isQuestSheetOpen: isQuestSheetOpen ?? this.isQuestSheetOpen,
    isPawnDragging: isPawnDragging ?? this.isPawnDragging,
  );

  @override
  List<Object?> get props => [
    isMapPage,
    isRouteCovered,
    isQuestSheetOpen,
    isPawnDragging,
  ];
}
