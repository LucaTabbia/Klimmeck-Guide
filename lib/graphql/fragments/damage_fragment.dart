class DamageFragment {
  static const String name = 'DamageFields';

  static const String definition = '''
    fragment $name on Damage {
      type
      power
    }
  ''';

  static const String fields = '''
    type
    power
  ''';
}

class DamagesFragment {
  static const String name = 'DamagesFields';

  static const String definition = '''
    fragment $name on Damages {
      base {
        ${DamageFragment.fields}
      }
      energy {
        ${DamageFragment.fields}
      }
    }
  ''';

  static const String fields = '''
    base {
      type
      power
    }
    energy {
      type
      power
    }
  ''';
}

