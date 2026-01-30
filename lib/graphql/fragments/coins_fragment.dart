class CoinsFragment {
  static const String name = 'CoinsFields';

  static const String definition = '''
    fragment $name on Coins {
      gold
      silver
      copper
    }
  ''';

  static const String fields = '''
    gold
    silver
    copper
  ''';
}

