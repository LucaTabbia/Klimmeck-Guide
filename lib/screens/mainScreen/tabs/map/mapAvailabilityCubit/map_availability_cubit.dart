import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'map_availability_state.dart';

/// Quando un foglio esiti può aprirsi sulla mappa (09-CONTEXT D-23). Vive nella
/// shell e lo scrive solo la UI: `MainScreen` (pagina corrente),
/// `QuestResultPresenter` (route sopra la shell, `ModalRoute.isCurrentOf`),
/// `WorldMap` (foglio quest e trascinamento della pedina).
class MapAvailabilityCubit extends Cubit<MapAvailabilityState>
    with SafeEmit<MapAvailabilityState> {
  MapAvailabilityCubit() : super(const MapAvailabilityState());

  void pageChanged({required bool isMapPage}) =>
      emit(state.copyWith(isMapPage: isMapPage));

  void routeCoveredChanged(bool isCovered) =>
      emit(state.copyWith(isRouteCovered: isCovered));

  void questSheetChanged(bool isOpen) =>
      emit(state.copyWith(isQuestSheetOpen: isOpen));

  void pawnDragChanged(bool isDragging) =>
      emit(state.copyWith(isPawnDragging: isDragging));
}
