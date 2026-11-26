import 'package:equatable/equatable.dart';

/// Lanciate da `AuthTokenService.login`; dalla Phase 25 la firma porta la
/// versione dei documenti legali accettata (D-19).
sealed class LoginException extends Equatable implements Exception {
  const LoginException();

  @override
  List<Object?> get props => [];
}

/// Cancellazione del browser o diniego `access_denied` (D-21).
final class LoginCancelledException extends LoginException {
  const LoginCancelledException();
}

/// Backend senza chiavi Twitch configurate (D-27).
final class LoginUnavailableException extends LoginException {
  const LoginUnavailableException();
}

/// L'account Twitch non segue il canale dello streamer: il backend non apre
/// la sessione.
final class LoginNotFollowingException extends LoginException {
  const LoginNotFollowingException();
}

/// Il backend ha rifiutato il login: versione dei documenti legali assente o
/// malformata (D-19).
final class LoginTermsNotAcceptedException extends LoginException {
  const LoginTermsNotAcceptedException();
}

/// Qualunque altro fallimento, con codice opaco (D-22).
final class LoginFailedException extends LoginException {
  const LoginFailedException(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
