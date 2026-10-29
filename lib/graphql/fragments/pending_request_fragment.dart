/// Voce della coda del GM (BE 09 §9, 10-CONTEXT D-08/D-10): solo ciò che la
/// carta mostra; niente `user`/`pointsSpent` (nessun twitchId in memoria).
/// Il piano gated 10-11 aggiunge `pendingQuest` sotto `character` (BE-HARD-08).
class PendingRequestFragment {
  static const String fields = '''
    id
    startDate
    quest {
      id
      type
      title
      requiredAdventurers { title count }
    }
    character {
      id
      name
      location
      activeTravel { endTime to }
      awaitingAid { quest aidQuest since }
    }
  ''';
}
