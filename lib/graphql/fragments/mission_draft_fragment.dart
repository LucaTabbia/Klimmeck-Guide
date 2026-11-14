import 'coins_fragment.dart';

class MissionEnemyFragment {
  /// Nemico della lista dell'oste (D-03, D-19): solo ciò che la riga mostra.
  static const String fields = '''
    id
    name
    imagePath
    xp
    lifePoints
    legendary
  ''';
}

class MissionDraftFragment {
  /// Bozza del flusso guidato (BE Phase 22 §Q9 + D-17): UNA selezione, un solo
  /// parser. I limiti di ogni scontro (vita, ferite e risorse di partenza)
  /// sono serviti, mai calcolati (D-14); il verdetto è uno per scontro (D-21).
  static String get fields =>
      '''
    id
    quest
    questType
    step
    place
    startedAt
    updatedAt
    participants { character name title maxLifePoints pendingQuest }
    fights {
      verdict
      enemies { quantity enemy { ${MissionEnemyFragment.fields} } }
      outcomes {
        character
        hpBefore
        injuriesBefore
        consumablesAvailable { item quantity }
        spellsAvailable { spell usages }
        simulated { hpAfter injuriesAdded consumablesUsed { item quantity } spellsUsed { spell usages } }
        corrected { hpAfter injuriesAdded consumablesUsed { item quantity } spellsUsed { spell usages } }
      }
    }
    prizes { character xp coins { ${CoinsFragment.fields} } cure { lifePointsShare canHeal } items { item quantity } pet spell }
  ''';
}
