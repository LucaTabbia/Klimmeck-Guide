part of 'quest_results_cubit.dart';

/// Conferma del foglio di morte (D-10, D-13): attesa, non best-effort.
enum DeathAcknowledgement { idle, inFlight, failed, done }

/// Rilettura dei risultati non confermati (09-REVIEW WR-03): `failed` quando
/// i tentativi silenziosi si arrendono, `done` quando la lettura è riuscita.
enum PendingRefetch { idle, inFlight, done, failed }

/// Coda dei risultati della shell (D-08..D-13): FIFO per `resolvedAt`, una
/// sola istanza per id; `arrival` è l'ultimo arrivo live (banner o soppressione
/// decisi dal presenter).
class QuestResultsState extends Equatable {
  const QuestResultsState({
    this.queue = const [],
    this.showingGroup = const [],
    this.position = 0,
    this.arrival,
    this.arrivalSerial = 0,
    this.notice,
    this.deathAcknowledgement = DeathAcknowledgement.idle,
    this.pendingRefetch = PendingRefetch.idle,
  });

  final List<QuestResult> queue;

  /// Foglio o carosello aperto (16-CONTEXT D-11): un risultato, o le
  /// imboscate consecutive in testa alla coda.
  final List<QuestResult> showingGroup;

  /// Posizione del foglio corrente nel lotto («k di N», D-08).
  final int position;
  final QuestResult? arrival;
  final int arrivalSerial;
  final QuestResultNotice? notice;
  final DeathAcknowledgement deathAcknowledgement;
  final PendingRefetch pendingRefetch;

  QuestResult? get showing => showingGroup.isEmpty ? null : showingGroup.first;

  QuestResult? get head => queue.isEmpty ? null : queue.first;

  /// Unità da presentare (D-05): la testa da sola, oppure le imboscate
  /// consecutive dalla testa, rivalutate a ogni lettura.
  List<QuestResult> get presentable {
    final head = this.head;
    if (head == null) return const [];
    if (!head.isAmbush) return [head];
    return List.unmodifiable(queue.takeWhile((result) => result.isAmbush));
  }

  /// Una morte in coda apre tutta la coda su qualunque tab (D-08).
  bool get isUnlockedByDeath => queue.any((result) => result.isDeath);

  int get total => position + queue.length;

  /// Dopo la conferma di una morte la shell sta per lasciare il posto alla
  /// creazione (D-13): nessun altro foglio.
  bool get isAcceptingSheets =>
      deathAcknowledgement != DeathAcknowledgement.done;

  /// Nessun foglio in coda o aperto e l'ultima rilettura conclusa: al cold
  /// start di un personaggio non disponibile nessun foglio di morte sta per
  /// arrivare (09-REVIEW WR-03).
  bool get isSettledWithoutSheets =>
      isAcceptingSheets &&
      queue.isEmpty &&
      showing == null &&
      (pendingRefetch == PendingRefetch.done ||
          pendingRefetch == PendingRefetch.failed);

  QuestResultsState copyWith({
    List<QuestResult>? queue,
    List<QuestResult>? showingGroup,
    int? position,
    QuestResult? arrival,
    int? arrivalSerial,
    QuestResultNotice? notice,
    DeathAcknowledgement? deathAcknowledgement,
    PendingRefetch? pendingRefetch,
  }) => QuestResultsState(
    queue: queue ?? this.queue,
    showingGroup: showingGroup ?? this.showingGroup,
    position: position ?? this.position,
    arrival: arrival ?? this.arrival,
    arrivalSerial: arrivalSerial ?? this.arrivalSerial,
    notice: notice ?? this.notice,
    deathAcknowledgement: deathAcknowledgement ?? this.deathAcknowledgement,
    pendingRefetch: pendingRefetch ?? this.pendingRefetch,
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
    pendingRefetch: pendingRefetch,
  );

  @override
  List<Object?> get props => [
    queue,
    showingGroup,
    position,
    arrival,
    arrivalSerial,
    notice,
    deathAcknowledgement,
    pendingRefetch,
  ];
}
