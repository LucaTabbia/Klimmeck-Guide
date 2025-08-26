class CharacterQueries {
  static const String getCharacter = r'''
    query GetCharacter {
      character {
        id
        name
        age
        city {
          id
          name
        }
      }
    }
  ''';

  static const String getCharacters = r'''
    query GetCharacters {
      characters {
        id
        name
        age
      }
    }
  ''';
}
