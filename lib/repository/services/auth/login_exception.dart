import 'package:equatable/equatable.dart';

/// Lanciate da `AuthTokenService.login()`; la firma `Future<void> login()`
/// non cambia (D-02).
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

/// Qualunque altro fallimento, con codice opaco (D-22).
final class LoginFailedException extends LoginException {
  const LoginFailedException(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
