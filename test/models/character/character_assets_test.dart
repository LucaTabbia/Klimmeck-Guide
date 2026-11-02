import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character_assets.dart';

import '../../helpers/fixtures/shop_fixtures.dart';

void main() {
  group('CharacterAssets', () {
    test('parses ownedPets beside the equipped pet (D-10)', () {
      final assets = CharacterAssets.fromJson({
        'pet': petJson(),
        'ownedPets': [petJson(), catPetJson()],
      });

      expect(assets.pet?.id, 'pet-travel-horse');
      expect(assets.ownedPets.map((p) => p.id), [
        'pet-travel-horse',
        'pet-cat',
      ]);
    });

    test('defaults ownedPets to an empty list when absent (D-11)', () {
      expect(CharacterAssets.fromJson({}).ownedPets, isEmpty);
    });

    test('lists ownedPets in props so a sale re-renders (D-08)', () {
      expect(
        CharacterAssets.fromJson({
          'ownedPets': [petJson(), catPetJson()],
        }),
        isNot(
          CharacterAssets.fromJson({
            'ownedPets': [petJson()],
          }),
        ),
      );
    });
  });
}
