class CityQueries {
  static const String getAllCities = r'''
    query cities {
      cities {
        id
        image
        type
        name
        citySize
        size
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
