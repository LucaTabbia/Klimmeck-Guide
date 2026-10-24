part of 'travel_cubit.dart';

enum TravelStage { preview, start }

sealed class TravelState extends Equatable {
  const TravelState();
}

final class TravelIdle extends TravelState {
  const TravelIdle();

  @override
  List<Object?> get props => [];
}

/// Foglio aperto con la meta, numeri in arrivo (caricamento discreto nel foglio).
final class TravelPreviewing extends TravelState {
  const TravelPreviewing(this.destination);

  final City destination;

  @override
  List<Object?> get props => [destination];
}

/// Numeri del BE pronti: `eta` = ora server stimata + `preview.duration` (C4).
final class TravelConfirming extends TravelState {
  const TravelConfirming({
    required this.destination,
    required this.preview,
    required this.eta,
    required this.previewedAt,
  });

  final City destination;
  final TravelPreview preview;
  final DateTime eta;

  /// Ora server stimata dell'anteprima: decide «oggi»/«domani» nell'ETA.
  final DateTime previewedAt;

  @override
  List<Object?> get props => [destination, preview, eta, previewedAt];
}

/// "Parti" premuto: azioni disabilitate finché il BE risponde.
final class TravelStarting extends TravelState {
  const TravelStarting({
    required this.destination,
    required this.preview,
    required this.eta,
    required this.previewedAt,
  });

  final City destination;
  final TravelPreview preview;
  final DateTime eta;
  final DateTime previewedAt;

  @override
  List<Object?> get props => [destination, preview, eta, previewedAt];
}

/// `startTravel` riuscito: la rotta d'anteprima resta finché `activeTravel`
/// arriva (Pitfall 4).
final class TravelStarted extends TravelState {
  const TravelStarted({required this.destination, required this.preview});

  final City destination;
  final TravelPreview preview;

  @override
  List<Object?> get props => [destination, preview];
}

final class TravelFailed extends TravelState {
  const TravelFailed({
    required this.destination,
    required this.failure,
    required this.stage,
  });

  final City destination;
  final TravelFailure failure;
  final TravelStage stage;

  @override
  List<Object?> get props => [destination, failure, stage];
}
