import 'package:graphql_flutter/graphql_flutter.dart';

import 'graphql_sync_exceptions.dart';

const String forbiddenCode = 'FORBIDDEN';
const String notFoundCode = 'NOT_FOUND';

/// Codici terminali sui percorsi di sync: lo stream non va ri-sottoscritto
/// (niente hot loop) e in una sessione già caricata la reazione è silenziosa.
const Set<String> accessDeniedCodes = {forbiddenCode, notFoundCode};

/// Estrae `extensions.code` dall'eccezione. La forma reale del backend è un
/// `next` con `errors` (-> `graphqlErrors`); la forma con `SubscriptionError`
/// (payload lista) è interpretata in modo difensivo.
String? graphQlErrorCode(OperationException? exception) {
  if (exception == null) return null;
  for (final error in exception.graphqlErrors) {
    final code = error.extensions?['code'];
    if (code is String) return code;
  }
  final original = exception.linkException?.originalException;
  if (original is SubscriptionError && original.payload is List) {
    for (final item in original.payload as List) {
      final code = _codeOfPayloadItem(item);
      if (code != null) return code;
    }
  }
  return null;
}

String? _codeOfPayloadItem(Object? item) {
  if (item is! Map) return null;
  final extensions = item['extensions'];
  if (extensions is! Map) return null;
  final code = extensions['code'];
  return code is String ? code : null;
}

bool isAccessDeniedError(Object error) => switch (error) {
  SubscriptionStreamException(:final code) => accessDeniedCodes.contains(code),
  GraphQlAccessDeniedException() => true,
  OperationException() => accessDeniedCodes.contains(graphQlErrorCode(error)),
  _ => false,
};
