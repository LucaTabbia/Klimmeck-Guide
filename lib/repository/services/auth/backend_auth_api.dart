import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/user.dart';

/// Sorgente dell'utente corrente (`me`), usata anche dallo stub dev.
abstract interface class BackendMeSource {
  Future<User> fetchMe(String accessToken);
}

/// Operazioni di sessione del backend. Lanciano solo `AuthApiException`.
abstract interface class BackendAuthApi implements BackendMeSource {
  Future<AuthSession> exchangeLoginTicket({
    required String ticket,
    required String codeVerifier,
  });

  Future<AuthSession> refreshSession(String refreshToken);

  Future<void> logout(String accessToken);
}
