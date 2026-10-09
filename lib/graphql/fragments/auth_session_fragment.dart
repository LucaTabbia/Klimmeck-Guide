import 'user_fragment.dart';

class AuthSessionFragment {
  static const String name = 'AuthSessionFields';

  static const String definition =
      '''
    fragment $name on AuthSession {
      accessToken
      accessTokenExpiresAt
      refreshToken
      user { ...${UserFragment.name} }
    }
    ${UserFragment.definition}
  ''';
}
