import 'damage_fragment.dart';

class SpellFragment {
  static const String name = 'SpellFields';

  static const String definition = '''
    fragment $name on Spell {
      id
      name
      description
      useType
      maxUsages
      minXpToLearn
      recoveryTime
      requiredLearnTime
      energyDamage {
        ${DamageFragment.fields}
      }
    }
  ''';

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
    minXpToLearn
    recoveryTime
    requiredLearnTime
    energyDamage {
      type
      power
    }
  ''';
}

