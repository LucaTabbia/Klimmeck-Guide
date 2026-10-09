class UserFragment {
  static const String name = 'UserFields';

  static const String definition =
      '''
    fragment $name on User {
      id
      twitchId
      twitchPoints
      role
      currentCharacter { id }
    }
  ''';
}
