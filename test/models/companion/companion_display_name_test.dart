import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/companion/companion_display_name.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';

Pet petNamed(String? species) => Pet(
  id: 'worg',
  name: species,
  buyPrice: null,
  sellPrice: null,
  maxXp: null,
  imagePath: null,
  maxLifePoints: 100,
);

void main() {
  test('the chosen name replaces the species (D-18, D-20)', () {
    final owned = OwnedPet(
      pet: petNamed('Worg'),
      xp: 0,
      currentLifePoints: 10,
      name: 'Fenrir',
    );

    expect(companionDisplayNameOf(owned), 'Fenrir');
  });

  test('without a name the species is the wording (D-20)', () {
    final owned = OwnedPet(pet: petNamed('Worg'), xp: 0, currentLifePoints: 10);

    expect(companionDisplayNameOf(owned), 'Worg');
  });

  test('a blank name falls back to the species (D-20)', () {
    expect(companionDisplayName(name: '   ', pet: petNamed('Worg')), 'Worg');
  });

  test('an unnamed species-less pet reads an empty string (D-20)', () {
    expect(companionDisplayName(name: null, pet: petNamed(null)), '');
  });
}
