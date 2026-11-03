import 'package:equatable/equatable.dart';

/// Input di `equipPet` / `unequipPet` (BE D-15, nomi assunti A1, verificati in
/// 13-10): `id` è sempre il personaggio corrente.
class EquipPetRequest extends Equatable {
  const EquipPetRequest({required this.id, required this.petId});

  final String id;

  /// Id di un compagno posseduto (`ownedPets`).
  final String petId;

  Map<String, dynamic> toJson() => {'id': id, 'petId': petId};

  @override
  List<Object?> get props => [id, petId];
}

class UnequipPetRequest extends Equatable {
  const UnequipPetRequest({required this.id});

  final String id;

  Map<String, dynamic> toJson() => {'id': id};

  @override
  List<Object?> get props => [id];
}
