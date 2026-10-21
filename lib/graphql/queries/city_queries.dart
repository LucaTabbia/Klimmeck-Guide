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

  /// POI della città corrente per il filtro della board (D-20 G2).
  static const String getCity = r'''
    query GetCity($id: String!) {
      city(id: $id) {
        id
        markerLocation {
          id
        }
        pointsOfInterest {
          id
        }
      }
    }
  ''';
}
