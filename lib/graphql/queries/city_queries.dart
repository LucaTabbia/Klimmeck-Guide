import '../fragments/fragments.dart';

class CityQueries {
  static String get getAllCities => '''
    query cities {
      cities {
        id
        type
        name
        markerLocation {
          ${LocationFragment.fields}
        }
        relatedLore {
          id
          description
        }
      }
    }
  ''';
}
