/// Voce della coda del GM (BE 09 §9, 10-CONTEXT D-08/D-10): solo ciò che la
/// carta mostra; niente `user`/`pointsSpent` (nessun id Twitch in memoria).
/// `pendingQuest` (BE-HARD-08, BE Phase 10): la corsia standard occupata
/// nasconde il personaggio (D-07).
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
      pendingQuest
    }
  ''';
}
