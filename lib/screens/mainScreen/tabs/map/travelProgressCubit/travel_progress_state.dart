part of 'travel_progress_cubit.dart';

sealed class TravelProgressState extends Equatable {
  const TravelProgressState();
}

final class TravelProgressIdle extends TravelProgressState {
  const TravelProgressIdle();

  @override
  List<Object?> get props => [];
}

/// Viaggio in corso sulla mappa (D-06..D-10). `position` nullo solo per una
/// rotta vuota: la pedina resta sulla posizione del personaggio.
final class TravelProgressActive extends TravelProgressState {
  const TravelProgressActive({
    required this.travel,
    required this.route,
    required this.position,
    required this.travelled,
    required this.remaining,
    required this.remainingTime,
    required this.isArriving,
    required this.arrivalRefetchCount,
  });

  final ActiveTravel travel;
  final TravelRoute route;
  final LatLng? position;
  final List<LatLng> travelled;
  final List<LatLng> remaining;
  final Duration remainingTime;

  /// Progresso 1: «In arrivo…» finché il BE non svuota `activeTravel` (D-10).
  final bool isArriving;

  /// Richieste di rilettura silenziosa del personaggio dopo `endTime` (0..2).
  final int arrivalRefetchCount;

  @override
  List<Object?> get props => [
    travel,
    route,
    position,
    travelled,
    remaining,
    remainingTime,
    isArriving,
    arrivalRefetchCount,
  ];
}
