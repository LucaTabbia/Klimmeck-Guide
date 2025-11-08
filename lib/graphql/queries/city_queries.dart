class CityQueries {
  static const String getAllCities = r'''
    query cities {
      cities {
        id
        type
        name
        markerLocation {
          id
          location
        }
        relatedLore {
          id
          description
        }
      }
    }
  ''';
}
