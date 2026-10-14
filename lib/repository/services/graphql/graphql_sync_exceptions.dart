/// Errore di uno stream di subscription: porta solo nome operazione e codice,
/// mai il payload (docs/rules/graphql.md).
class SubscriptionStreamException implements Exception {
  const SubscriptionStreamException({required this.operation, this.code});

  final String operation;
  final String? code;

  @override
  String toString() => 'SubscriptionStreamException($operation, code: $code)';
}

/// Il backend nega l'accesso alla risorsa (FORBIDDEN) o non la trova
/// (NOT_FOUND): riprovare non serve.
class GraphQlAccessDeniedException implements Exception {
  const GraphQlAccessDeniedException({
    required this.operation,
    required this.code,
  });

  final String operation;
  final String code;

  @override
  String toString() => 'GraphQlAccessDeniedException($operation, code: $code)';
}
