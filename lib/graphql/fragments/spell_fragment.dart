/// Selezioni di una magia; i campi della BE Phase 24 entrano solo al gate
/// 23-07.
class SpellFragment {
  static const String simpleFields = '''
    id
    name
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
    useType
    maxUsages
    recoveryTime
    requiredLearnTime
    energyDamage {
      type
      power
    }
  ''';
}
