import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/pet.dart';

/// Compagno posseduto (BE Phase 19, D-03): il compagno a catalogo più lo
/// stato che vive sul personaggio. La vita non si mostra (D-18).
class OwnedPet extends Equatable {
  const OwnedPet({
    required this.pet,
    required this.xp,
    required this.currentLifePoints,
  });

  static OwnedPet? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final pet = Pet.tryFromEntryJson(json['pet']);
    final xp = json['xp'];
    final life = json['currentLifePoints'];
    if (pet != null && xp is num && life is num) {
      return OwnedPet(
        pet: pet,
        xp: xp.toInt(),
        currentLifePoints: life.toInt(),
      );
    }
    // Finestra (BE prima della Phase 19): un compagno a catalogo nudo.
    // Ramo cancellato al gate (piano 19-11).
    final bare = Pet.tryFromEntryJson(json);
    return bare == null
        ? null
        : OwnedPet(pet: bare, xp: 0, currentLifePoints: 0);
  }

  final Pet pet;
  final int xp;
  final int currentLifePoints;

  Map<String, dynamic> toJson() => {
    'pet': pet.toJson(),
    'xp': xp,
    'currentLifePoints': currentLifePoints,
  };

  @override
  List<Object?> get props => [pet, xp, currentLifePoints];
}
