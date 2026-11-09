import 'package:equatable/equatable.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String sessionExpiredCode = 'SESSION_EXPIRED';
const String sessionRevokedCode = 'SESSION_REVOKED';
const String loginTicketInvalidCode = 'LOGIN_TICKET_INVALID';
const String unauthenticatedCode = 'UNAUTHENTICATED';
const String badRequestCode = 'BAD_REQUEST';

/// Valori di `extensions.reason` (BE Phase 17 `SessionRevokeReason`) che hanno
/// un avviso dedicato; gli altri valori restano leciti e valgono l'avviso neutro.
const String sessionRevokedReasonNewLogin = 'newLogin';
const String sessionRevokedReasonRoleChanged = 'roleChanged';

/// Errori di dominio delle operazioni di auth: portano solo codici, mai token.
sealed class AuthApiException extends Equatable implements Exception {
  const AuthApiException();
}

/// Il backend ha respinto il refresh token (terminale: la sessione va chiusa).
class SessionRejected extends AuthApiException {
  const SessionRejected(this.code, {this.reason});

  final String code;

  /// Solo per `SESSION_REVOKED` (D-12): null se assente o illeggibile.
  final String? reason;

  @override
  List<Object?> get props => [code, reason];
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

  final error = _firstCodedError(exception.graphqlErrors);
  final code = error?.extensions?['code'] as String?;
  return switch (code) {
    sessionExpiredCode => const SessionRejected(sessionExpiredCode),
    sessionRevokedCode => SessionRejected(
      sessionRevokedCode,
      reason: _revokeReasonOf(error!),
    ),
    loginTicketInvalidCode => const LoginTicketInvalid(),
    unauthenticatedCode => const AccessTokenRejected(),
    badRequestCode => AuthRequestRejected(code!),
    _ => TransientAuthFailure(code ?? 'unknown'),
  };
}

GraphQLError? _firstCodedError(List<GraphQLError> errors) {
  for (final error in errors) {
    if (error.extensions?['code'] is String) return error;
  }
  return null;
}

String? _revokeReasonOf(GraphQLError error) {
  final reason = error.extensions?['reason'];
  return reason is String && reason.isNotEmpty ? reason : null;
}
