class CityQueries {
  static const String getAllCities = r'''
    query cities {
      cities {
        id
        type
        name
        markerLocation {
          latitude
          longitude
        }
        relatedLore {
          id
          description
        }
      }
    }
  ''';
}
