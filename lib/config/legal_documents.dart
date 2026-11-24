/// Documenti legali pubblici (D-08) e versione accettata al login (D-12).
/// Mai aprire URL presi da un payload.
class LegalDocuments {
  LegalDocuments._();

  /// Data provvisoria: l'utente mette quella reale al lancio, insieme alla
  /// data di pubblicazione delle pagine legali (D-12).
  static const String version = '2026-11-24';

  static const String termsUrl =
      'https://lucatabbia.github.io/klimmeck-guide-legal/termini';

  static const String privacyUrl =
      'https://lucatabbia.github.io/klimmeck-guide-legal/privacy';

  static final Uri termsUri = Uri.parse(termsUrl);

  static final Uri privacyUri = Uri.parse(privacyUrl);
}
