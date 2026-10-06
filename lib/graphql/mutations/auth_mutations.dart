import '../fragments/auth_session_fragment.dart';

class AuthMutations {
  static const String exchangeLoginTicket =
      r'''
    mutation ExchangeLoginTicket($ticket: String!, $codeVerifier: String!) {
      exchangeLoginTicket(ticket: $ticket, codeVerifier: $codeVerifier) {
        ...AuthSessionFields
      }
    }
  ''' +
      AuthSessionFragment.definition;

  static const String refreshSession =
      r'''
    mutation RefreshSession($refreshToken: String!) {
      refreshSession(refreshToken: $refreshToken) {
        ...AuthSessionFields
      }
    }
  ''' +
      AuthSessionFragment.definition;

  static const String logout = r'''
    mutation Logout {
      logout
    }
  ''';
}
