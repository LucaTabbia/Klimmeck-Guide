part of 'world_map_cubit.dart';

@immutable
abstract class WorldMapState extends Equatable {
  const WorldMapState();

  @override
  List<Object?> get props => [];
}

class WorldMapInitial extends WorldMapState {}

class WorldMapLoadData extends WorldMapState {
  final Lore lore;

  const WorldMapLoadData(this.lore);

  @override
  List<Object?> get props => [lore];
}

class WorldMapLoading extends WorldMapState {}

class WorldMapError extends WorldMapState {
  final String errorMessage;

  const WorldMapError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
