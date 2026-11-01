import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';

/// Una carta per richiesta; una quest condivisa (worldMission) raggruppa i suoi partecipanti nell'ordine del BE (10-CONTEXT D-05, emendata nella UAT del 2026-11-01: le story di due personaggi non sono collegate).
class RequestCard extends Equatable {
  const RequestCard({
    required this.cardKey,
    required this.questId,
    required this.questTitle,
    required this.questType,
    required this.pendingQuestId,
    required this.participants,
    required this.entryCount,
    required this.totalSeats,
  });

  /// Chiave della carta (vedi [cardKeyOf]): la quest per una worldMission, la richiesta altrimenti.
  final String cardKey;
  final String questId;
  final String questTitle;
  final QuestType? questType;

  /// Id della prima voce: per una quest condivisa una chiamata chiude la richiesta per tutti (BE 09 §9).
  final String pendingQuestId;
  final List<PendingRequestCharacter> participants;

  /// Tutte le voci della quest, nascosti compresi (C7).
  final int entryCount;
  final int totalSeats;

  bool get hasHiddenParticipants => participants.length < entryCount;

  bool get showsSeats => questType == QuestType.worldMission;

  /// Una quest condivisa aspetta tutti i suoi iscritti prima di comparire.
  bool get hasAllSeats => entryCount >= totalSeats;

  /// UAT 2026-11-01: la coda elenca solo le carte su cui il GM può agire ora
  /// (tutti i posti coperti, nessuno nascosto, nessuno in viaggio).
  bool isActionable(DateTime serverNow) =>
      hasAllSeats && canComplete(serverNow);

  /// C6: completabile quando nessuno è nascosto e ogni partecipante visibile è presente, arrivato per l'ora del server o in attesa di soccorso.
  bool canComplete(DateTime serverNow) =>
      !hasHiddenParticipants &&
      participants.every(
        (character) => !presenceOf(character, serverNow).blocksCompletion,
      );

  @override
  List<Object?> get props => [
    cardKey,
    questId,
    questTitle,
    questType,
    pendingQuestId,
    participants,
    entryCount,
    totalSeats,
  ];
}

/// Solo una worldMission è condivisa fra i suoi partecipanti: ogni altra
/// richiesta (story compresa) è una carta a sé e si completa da sola.
String cardKeyOf(PendingRequest request) =>
    request.quest.type == QuestType.worldMission
    ? request.quest.id
    : request.id;

/// D-05/D-07/D-09: raggruppa per [cardKeyOf] nell'ordine del BE (LinkedHashMap), nasconde la corsia standard occupata; una carta senza partecipanti visibili non c'è (story impegnata; worldMission tutta impegnata: default per veto, 10-CONTEXT D-07 «Amended (C15)»).
List<RequestCard> requestCardsOf(
  List<PendingRequest> requests, {
  Set<String> hiddenCardKeys = const {},
}) {
  final entriesByCard = <String, List<PendingRequest>>{};
  for (final request in requests) {
    entriesByCard.putIfAbsent(cardKeyOf(request), () => []).add(request);
  }
  return List.unmodifiable([
    for (final MapEntry(key: cardKey, value: entries) in entriesByCard.entries)
      if (!hiddenCardKeys.contains(cardKey))
        if (_cardOf(entries) case final card?) card,
  ]);
}

RequestCard? _cardOf(List<PendingRequest> entries) {
  final visible = [
    for (final entry in entries)
      if (!entry.character.isBusy) entry.character,
  ];
  if (visible.isEmpty) return null;
  final first = entries.first;
  return RequestCard(
    cardKey: cardKeyOf(first),
    questId: first.quest.id,
    questTitle: first.quest.title,
    questType: first.quest.type,
    pendingQuestId: first.id,
    participants: List.unmodifiable(visible),
    entryCount: entries.length,
    totalSeats: first.quest.totalSeats,
  );
}
