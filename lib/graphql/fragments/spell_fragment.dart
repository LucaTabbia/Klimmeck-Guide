/// Selezioni di una magia; origine e livello minimo della BE Phase 24
/// selezionati dal gate 23-07.
class SpellFragment {
  static const String simpleFields = '''
    id
    name
    origin
    useType
    energyDamage {
      type
      power
    }
  ''';

  static const String fields = '''
    id
    name
    description
    origin
    useType
    maxUsages
    minLevelToLearn
    recoveryTime
    requiredLearnTime
    energyDamage {
      type
      power
    }
  ''';
}
