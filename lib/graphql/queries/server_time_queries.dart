class ServerTimeQueries {
  /// Ora del server per l'offset device↔server (BE Phase 7 §5).
  static const String getServerTime = r'''
    query GetServerTime {
      serverTime
    }''';
}
