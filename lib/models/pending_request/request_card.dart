import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';

/// Una carta per quest (10-CONTEXT D-05): i partecipanti visibili nell'ordine del BE.
class RequestCard extends Equatable {
  const RequestCard({
    required this.questId,
    required this.questTitle,
    required this.questType,
    required this.pendingQuestId,
    required this.participants,
    required this.entryCount,
    required this.totalSeats,
  });

  final String questId;
  final String questTitle;
  final QuestType? questType;

  /// Id della prima voce: una chiamata chiude la richiesta per tutti (BE 09 §9).
  final String pendingQuestId;
  final List<PendingRequestCharacter> participants;

  /// Tutte le voci della quest, nascosti compresi (C7).
  final int entryCount;
  final int totalSeats;

  bool get hasHiddenParticipants => participants.length < entryCount;

  bool get showsSeats => questType == QuestType.worldMission;

  /// C6: completabile quando nessuno è nascosto e ogni partecipante visibile è presente, arrivato per l'ora del server o in attesa di soccorso.
  bool canComplete(DateTime serverNow) =>
      !hasHiddenParticipants &&
      participants.every(
        (character) => !presenceOf(character, serverNow).blocksCompletion,
      );

  @override
  List<Object?> get props => [
    questId,
    questTitle,
    questType,
    pendingQuestId,
    participants,
    entryCount,
    totalSeats,
  ];
}

/// D-05/D-07/D-09: raggruppa per quest nell'ordine del BE (LinkedHashMap), nasconde la corsia standard occupata; una carta senza partecipanti visibili non c'è (story impegnata; worldMission tutta impegnata: default per veto, 10-CONTEXT D-07 «Amended (C15)»).
List<RequestCard> requestCardsOf(
  List<PendingRequest> requests, {
  Set<String> hiddenQuestIds = const {},
}) {
  final entriesByQuest = <String, List<PendingRequest>>{};
  for (final request in requests) {
    entriesByQuest.putIfAbsent(request.quest.id, () => []).add(request);
  }
  return List.unmodifiable([
    for (final MapEntry(key: questId, value: entries) in entriesByQuest.entries)
      if (!hiddenQuestIds.contains(questId))
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
    questId: first.quest.id,
    questTitle: first.quest.title,
    questType: first.quest.type,
    pendingQuestId: first.id,
    participants: List.unmodifiable(visible),
    entryCount: entries.length,
    totalSeats: first.quest.totalSeats,
  );
}
