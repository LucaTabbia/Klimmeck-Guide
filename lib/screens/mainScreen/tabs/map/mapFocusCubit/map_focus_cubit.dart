import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'map_focus_state.dart';

/// Richiesta "centra la camera sulla pedina" del tap su «Viaggio completato»
/// (07-CONTEXT D-15). Latched come `NotificationIntentCubit`: il popup gira
/// nel frame in cui la mappa non è ancora montata (Pitfall 13) e `WorldMap`
/// la consuma a mappa pronta. Vive nella shell, sopra le tab.
class MapFocusCubit extends Cubit<MapFocusState> with SafeEmit<MapFocusState> {
  MapFocusCubit() : super(const MapFocusState());

  void requestCharacterFocus() =>
      emit(const MapFocusState(isCharacterFocusPending: true));

  /// `true` se c'era una richiesta: chi chiama sposta la camera.
  bool consumeCharacterFocus() {
    if (!state.isCharacterFocusPending) return false;
    emit(const MapFocusState());
    return true;
  }
}
