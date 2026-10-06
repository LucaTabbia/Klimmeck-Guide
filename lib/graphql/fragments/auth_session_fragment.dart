class AuthSessionFragment {
  static const String name = 'AuthSessionFields';

  static const String definition =
      '''
    fragment $name on AuthSession {
      accessToken
      accessTokenExpiresAt
      refreshToken
      user { id twitchId twitchPoints role currentCharacter { id } }
    }
  ''';
}
