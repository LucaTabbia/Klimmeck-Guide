import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/backend_identifier.dart';

void main() {
  test('accepts identifiers in the backend alphabet', () {
    expect(validBackendIdentifier('travel-a.1_B'), 'travel-a.1_B');
    expect(validBackendIdentifier('a' * 128), 'a' * 128);
  });

  test('rejects empty, too long, foreign characters and non strings', () {
    expect(validBackendIdentifier(''), isNull);
    expect(validBackendIdentifier('a' * 129), isNull);
    expect(validBackendIdentifier('id with space'), isNull);
    expect(validBackendIdentifier('id/slash'), isNull);
    expect(validBackendIdentifier(42), isNull);
    expect(validBackendIdentifier(null), isNull);
  });
}
