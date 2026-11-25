import 'package:klimmeck_guide/repository/storage/legal_consent_store.dart';

/// [LegalConsentStore] in memoria: la versione accettata resta leggibile dai test.
class InMemoryLegalConsentStore implements LegalConsentStore {
  InMemoryLegalConsentStore({
    this.acceptedVersion,
    this.failOnRemember = false,
  });

  String? acceptedVersion;

  /// Se vero, `remember` lancia: simula uno storage di piattaforma guasto.
  bool failOnRemember;

  @override
  Future<String?> readAcceptedVersion() async => acceptedVersion;

  @override
  Future<void> remember(String version) async {
    if (failOnRemember) throw StateError('storage unavailable');
    acceptedVersion = version;
  }

  @override
  Future<void> forget() async => acceptedVersion = null;
}
