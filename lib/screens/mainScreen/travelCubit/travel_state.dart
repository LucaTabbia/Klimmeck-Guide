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

/// Anteprima del BE pronta, condivisa da conferma e avvio (IN-05): `eta` = ora
/// server stimata + `preview.duration` (C4); `eta`/`previewedAt` nulli finché
/// l'orologio non è sincronizzato (WR-03).
sealed class TravelQuote extends TravelState {
  const TravelQuote({
    required this.destination,
    required this.preview,
    required this.eta,
    required this.previewedAt,
  });

  final City destination;
  final TravelPreview preview;
  final DateTime? eta;

  /// Ora server stimata dell'anteprima: decide «oggi»/«domani» nell'ETA.
  final DateTime? previewedAt;

  /// Stesso stato con l'ETA calcolato su un orologio sincronizzato.
  TravelQuote withEta({required DateTime eta, required DateTime previewedAt});

  @override
  List<Object?> get props => [destination, preview, eta, previewedAt];
}

/// Numeri pronti: "Parti" e "Resta" attivi.
final class TravelConfirming extends TravelQuote {
  const TravelConfirming({
    required super.destination,
    required super.preview,
    required super.eta,
    required super.previewedAt,
  });

  @override
  TravelConfirming withEta({
    required DateTime eta,
    required DateTime previewedAt,
  }) => TravelConfirming(
    destination: destination,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );
}

/// "Parti" premuto: azioni disabilitate finché il BE risponde.
final class TravelStarting extends TravelQuote {
  const TravelStarting({
    required super.destination,
    required super.preview,
    required super.eta,
    required super.previewedAt,
  });

  TravelStarting.from(TravelConfirming confirming)
    : this(
        destination: confirming.destination,
        preview: confirming.preview,
        eta: confirming.eta,
        previewedAt: confirming.previewedAt,
      );

  @override
  TravelStarting withEta({
    required DateTime eta,
    required DateTime previewedAt,
  }) => TravelStarting(
    destination: destination,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );
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
