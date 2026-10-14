import '../fragments/user_fragment.dart';

class UserSubscriptions {
  static const String userUpdated =
      r'''
    subscription OnUserChanged {
      userUpdated { ...UserFields }
    }
  ''' +
      UserFragment.definition;
}
