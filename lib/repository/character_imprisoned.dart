import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

/// Rifiuto di `acceptQuest`, `startTravel`, `travelPreview` e `doTransaction`
/// durante la prigione (quick 261110-cgd, BE §1.6).
const String characterImprisonedCode = 'CHARACTER_IMPRISONED';

/// Chiave di `extensions` con la fine della prigione (stringa ISO 8601 UTC).
const String imprisonedUntilExtension = 'imprisonedUntil';

/// Fine della prigione detta dal server con il rifiuto; `null` per ogni altro
/// codice o per una data illeggibile.
DateTime? imprisonedUntilFrom(OperationException exception) {
  if (graphQlErrorCode(exception) != characterImprisonedCode) return null;
  return graphQlErrorInstant(exception, imprisonedUntilExtension);
}
