/// URL del backend in chiaro in una build release (D-03b): porta solo i NOMI
/// delle chiavi, mai gli URL.
class InsecureTransportError extends Error {
  InsecureTransportError(List<String> offendingKeys)
    : offendingKeys = List.unmodifiable(offendingKeys);

  final List<String> offendingKeys;

  @override
  String toString() => 'InsecureTransportError(${offendingKeys.join(', ')})';
}
