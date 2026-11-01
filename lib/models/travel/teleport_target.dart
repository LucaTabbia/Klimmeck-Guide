import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';

/// Personaggio scelto dal GM per il teletrasporto (10-CONTEXT D-15/C3): punto e
/// pedina vengono da `character(id)`; un viaggiatore libero parte dalla città di
/// partenza, perché il BE tiene `status.location` fino all'arrivo (C17).
/// Una carta condivisa muove tutti i suoi partecipanti insieme (UAT
/// 2026-11-01): i [companionIds] seguono il primo nello stesso luogo.
class TeleportTarget extends Equatable {
  const TeleportTarget({
    required this.characterId,
    required this.name,
    required this.location,
    required this.sex,
    this.companionIds = const [],
  });

  final String characterId;
  final String name;
  final PointOfInterest location;
  final SexType sex;
  final List<String> companionIds;

  /// Etichetta della pedina: il nome da soli, «Gruppo · N» in compagnia.
  String get label =>
      companionIds.isEmpty ? name : 'Gruppo · ${companionIds.length + 1}';

  /// `null` se manca il punto sulla mappa o il sesso della pedina.
  static TeleportTarget? fromCharacter(
    Character character, {
    required String fallbackName,
    List<String> companionIds = const [],
  }) {
    final location = character.status?.location;
    final sex = character.infos?.sex;
    if (location?.location == null || sex == null) return null;
    return TeleportTarget(
      characterId: character.id,
      name: character.infos?.name ?? fallbackName,
      location: location!,
      sex: sex,
      companionIds: List.unmodifiable(companionIds),
    );
  }

  @override
  List<Object?> get props => [characterId, name, location, sex, companionIds];
}
