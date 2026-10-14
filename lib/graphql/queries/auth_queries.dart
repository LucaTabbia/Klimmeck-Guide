import '../fragments/user_fragment.dart';

class AuthQueries {
  static const String getMe =
      r'''
    query GetMe {
      me { ...UserFields }
    }
  ''' +
      UserFragment.definition;
}
