import 'package:equatable/equatable.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String sessionExpiredCode = 'SESSION_EXPIRED';
const String sessionRevokedCode = 'SESSION_REVOKED';
const String loginTicketInvalidCode = 'LOGIN_TICKET_INVALID';
const String unauthenticatedCode = 'UNAUTHENTICATED';
const String badRequestCode = 'BAD_REQUEST';

/// Errori di dominio delle operazioni di auth: portano solo codici, mai token.
sealed class AuthApiException extends Equatable implements Exception {
  const AuthApiException();
}

/// Il backend ha respinto il refresh token (terminale: la sessione va chiusa).
class SessionRejected extends AuthApiException {
  const SessionRejected(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class LoginTicketInvalid extends AuthApiException {
  const LoginTicketInvalid();

  @override
  List<Object?> get props => const [];
}

/// L'access token usato per la chiamata non è accettato dal backend.
class AccessTokenRejected extends AuthApiException {
  const AccessTokenRejected();

  @override
  List<Object?> get props => const [];
}

class AuthRequestRejected extends AuthApiException {
  const AuthRequestRejected(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Fallimento non distruttivo: rete, 5xx, codici ignoti, risposta malformata.
class TransientAuthFailure extends AuthApiException {
  const TransientAuthFailure(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

AuthApiException mapAuthOperationException(OperationException exception) {
  final link = exception.linkException;
  if (link is ServerException && link.statusCode == 401) {
    return const AccessTokenRejected();
  }
  if (link != null) return const TransientAuthFailure('network');

  final code = _firstCode(exception.graphqlErrors);
  return switch (code) {
    sessionExpiredCode || sessionRevokedCode => SessionRejected(code!),
    loginTicketInvalidCode => const LoginTicketInvalid(),
    unauthenticatedCode => const AccessTokenRejected(),
    badRequestCode => AuthRequestRejected(code!),
    _ => TransientAuthFailure(code ?? 'unknown'),
  };
}

String? _firstCode(List<GraphQLError> errors) {
  for (final error in errors) {
    final code = error.extensions?['code'];
    if (code is String) return code;
  }
  return null;
}
