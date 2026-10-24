part of 'map_focus_cubit.dart';

final class MapFocusState extends Equatable {
  const MapFocusState({this.isCharacterFocusPending = false});

  /// Richiesta di centrare la camera sulla pedina non ancora servita dalla mappa.
  final bool isCharacterFocusPending;

  @override
  List<Object?> get props => [isCharacterFocusPending];
}
