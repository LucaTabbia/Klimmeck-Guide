import 'package:equatable/equatable.dart';

/// Input di `renamePet` (BE Phase 23, D-19): `id` è il personaggio corrente,
/// `petId` l'id a catalogo del compagno posseduto (D-23). Il nome parte sempre
/// valorizzato: cancellarlo non è offerto (D-31).
class RenamePetRequest extends Equatable {
  const RenamePetRequest({
    required this.id,
    required this.petId,
    required this.name,
  });

  final String id;
  final String petId;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'petId': petId, 'name': name};

  @override
  List<Object?> get props => [id, petId, name];
}
