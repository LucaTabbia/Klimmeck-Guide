import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/utils/lore_lines.dart';

import '../helpers/fixtures/lore_fixtures.dart';

void main() {
  group('loreUnlockedLine', () {
    test('a knowledge lore reads Conoscenza appresa (D-21)', () {
      final lore = Lore.fromJson(
        loreRefJson(
          id: 'lore-limit',
          name: 'Il limite del corpo',
          type: 'knowledge',
        ),
      );

      expect(loreUnlockedLine(lore), 'Conoscenza appresa: Il limite del corpo');
    });

    test(
      'an enemy, animal or plant lore reads Nuova pagina del Bestiario (D-21)',
      () {
        for (final type in const ['enemy', 'animal', 'plant']) {
          final lore = Lore.fromJson(loreRefJson(type: type));

          expect(
            loreUnlockedLine(lore),
            'Nuova pagina del Bestiario: Goblin',
            reason: type,
          );
        }
      },
    );

    test('a lore of unknown type reads as knowledge (D-21)', () {
      final lore = Lore.fromJson(loreRefJson(name: 'Rito', type: 'rumour'));

      expect(lore.type, isNull);
      expect(loreUnlockedLine(lore), 'Conoscenza appresa: Rito');
    });
  });
}
