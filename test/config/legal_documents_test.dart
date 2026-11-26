import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/legal_documents.dart';

void main() {
  test('the terms open the public termini page (D-08)', () {
    expect(
      LegalDocuments.termsUri.toString(),
      'https://lucatabbia.github.io/klimmeck-guide-legal/termini',
    );
  });

  test('the privacy opens the public privacy page (D-08)', () {
    expect(
      LegalDocuments.privacyUri.toString(),
      'https://lucatabbia.github.io/klimmeck-guide-legal/privacy',
    );
  });

  test('the version is one non-empty value in the BE format (D-12, D-19)', () {
    final backendFormat = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$');

    expect(backendFormat.hasMatch(LegalDocuments.version), isTrue);
  });
}
