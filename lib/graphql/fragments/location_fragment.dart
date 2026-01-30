class LocationFragment {
  static const String name = 'LocationFields';

  static const String definition = '''
    fragment $name on Location {
      id
      location
    }
  ''';

  static const String fields = '''
    id
    location
  ''';
}

