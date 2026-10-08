class AuthQueries {
  static const String getMe = r'''
    query GetMe {
      me { id twitchId twitchPoints role currentCharacter { id } }
    }
  ''';
}
