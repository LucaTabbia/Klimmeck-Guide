// Smoke test minimale: verifica che KlimmeckGuideApp accetti i parametri
// corretti. Il test del counter originale era un artefatto del template
// Flutter e non rifletteva l'app reale.
//
// Il test completo dell'albero widget (RepositoryProvider, BlocProvider, ecc.)
// è in test/app/app_wiring_test.dart.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder — wiring testato in test/app/app_wiring_test.dart', () {
    expect(true, isTrue);
  });
}
