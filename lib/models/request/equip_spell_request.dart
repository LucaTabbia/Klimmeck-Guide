import 'package:equatable/equatable.dart';

/// Input `EquipSpellRequest` di `equipSpell`/`unequipSpell` (D-06). Il campo
/// deprecato del BE `usages` non viene mai inviato (BE Phase 4 handoff §0 punto 4).
class EquipSpellRequest extends Equatable {
  const EquipSpellRequest({required this.id, required this.spellId});

  /// Id del personaggio corrente (mai digitato dall'utente).
  final String id;

  /// Id della magia del catalogo.
  final String spellId;

  Map<String, dynamic> toJson() => {'id': id, 'spellId': spellId};

  @override
  List<Object?> get props => [id, spellId];
}
