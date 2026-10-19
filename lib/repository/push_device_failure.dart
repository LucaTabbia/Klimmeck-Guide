import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String pushInvalidDeviceIdCode = 'PUSH_INVALID_DEVICE_ID';
const String pushInvalidTokenCode = 'PUSH_INVALID_TOKEN';

/// Esiti di registrazione/rimozione del device push (D-07). Solo i transitori si ritentano:
/// gli altri sono bug del FE o sessione finita.
enum PushDeviceFailure {
  invalidDeviceId,
  invalidToken,
  unauthenticated,
  connection,
  unknown;

  bool get isRetryable => this == connection || this == unknown;
}

class PushDeviceException implements Exception {
  const PushDeviceException(this.failure);

  final PushDeviceFailure failure;

  @override
  String toString() => 'PushDeviceException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
PushDeviceFailure pushDeviceFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return PushDeviceFailure.connection;
  }
  return switch (code) {
    pushInvalidDeviceIdCode => PushDeviceFailure.invalidDeviceId,
    pushInvalidTokenCode => PushDeviceFailure.invalidToken,
    unauthenticatedCode => PushDeviceFailure.unauthenticated,
    _ => PushDeviceFailure.unknown,
  };
}
