/// Lista servita letta voce per voce (Pitfall 8): una voce che non si legge è
/// scartata, ciò che non è una lista vale una lista vuota.
List<T> missionEntriesOf<T>(
  Object? json,
  T? Function(Object? entry) tryParse,
) => json is List
    ? List<T>.unmodifiable(json.map(tryParse).nonNulls)
    : List<T>.unmodifiable(const []);

/// Intero servito o `null` (mai un'eccezione).
int? missionIntOf(Object? json) => json is num ? json.toInt() : null;
