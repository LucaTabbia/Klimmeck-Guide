part of 'quest_results_cubit.dart';

/// Conferma del foglio di morte (D-10, D-13): attesa, non best-effort.
enum DeathAcknowledgement { idle, inFlight, failed, done }

/// Coda dei risultati della shell (D-08..D-13): FIFO per `resolvedAt`, una
/// sola istanza per id; `arrival` è l'ultimo arrivo live (banner o soppressione
/// decisi dal presenter).
class QuestResultsState extends Equatable {
  const QuestResultsState({
    this.queue = const [],
    this.showing,
    this.position = 0,
    this.arrival,
    this.arrivalSerial = 0,
    this.notice,
    this.deathAcknowledgement = DeathAcknowledgement.idle,
  });

  final List<QuestResult> queue;
  final QuestResult? showing;

  /// Posizione del foglio corrente nel lotto («k di N», D-08).
  final int position;
  final QuestResult? arrival;
  final int arrivalSerial;
  final QuestResultNotice? notice;
  final DeathAcknowledgement deathAcknowledgement;

  QuestResult? get head => queue.isEmpty ? null : queue.first;

  /// Una morte in coda apre tutta la coda su qualunque tab (D-08).
  bool get isUnlockedByDeath => queue.any((result) => result.isDeath);

  int get total => position + queue.length;

  /// Dopo la conferma di una morte la shell sta per lasciare il posto alla
  /// creazione (D-13): nessun altro foglio.
  bool get isAcceptingSheets =>
      deathAcknowledgement != DeathAcknowledgement.done;

  QuestResultsState copyWith({
    List<QuestResult>? queue,
    QuestResult? showing,
    int? position,
    QuestResult? arrival,
    int? arrivalSerial,
    QuestResultNotice? notice,
    DeathAcknowledgement? deathAcknowledgement,
  }) => QuestResultsState(
    queue: queue ?? this.queue,
    showing: showing ?? this.showing,
    position: position ?? this.position,
    arrival: arrival ?? this.arrival,
    arrivalSerial: arrivalSerial ?? this.arrivalSerial,
    notice: notice ?? this.notice,
    deathAcknowledgement: deathAcknowledgement ?? this.deathAcknowledgement,
  );

  /// Nessun foglio aperto: unico campo che torna `null`.
  QuestResultsState withoutShowing({
    required List<QuestResult> queue,
    required int position,
  }) => QuestResultsState(
    queue: queue,
    position: position,
    arrival: arrival,
    arrivalSerial: arrivalSerial,
    notice: notice,
    deathAcknowledgement: deathAcknowledgement,
  );

  @override
  List<Object?> get props => [
    queue,
    showing,
    position,
    arrival,
    arrivalSerial,
    notice,
    deathAcknowledgement,
  ];
}
