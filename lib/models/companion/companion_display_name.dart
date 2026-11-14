import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';

/// Il nome scelto, altrimenti la specie: unica parola per il compagno in ogni
/// testo (D-18, D-20).
String companionDisplayName({required String? name, required Pet pet}) {
  final chosen = name?.trim();
  if (chosen != null && chosen.isNotEmpty) return chosen;
  return pet.name ?? '';
}

String companionDisplayNameOf(OwnedPet owned) =>
    companionDisplayName(name: owned.name, pet: owned.pet);
