class CityQueries {
  static const String getAllCities = r'''
    query GetAllCities {
      allCities {
        id
        name
      }
    }
  ''';
}
