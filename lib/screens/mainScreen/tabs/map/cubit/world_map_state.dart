part of 'world_map_cubit.dart';

@immutable
abstract class WorldMapState {}

class WorldMapInitial extends WorldMapState {}

class WorldMapLoadData extends WorldMapState {
  final Lore lore;

  WorldMapLoadData(this.lore);
}

class WorldMapLoading extends WorldMapState {}

class WorldMapError extends WorldMapState {
  final String errorMessage;

  WorldMapError(this.errorMessage);
}
