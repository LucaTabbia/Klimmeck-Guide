import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/mission/mission_entries.dart';

/// Nemico scelto dall'oste per uno scontro (selezione `{ id name imagePath xp lifePoints legendary }`).
class MissionEnemy extends Equatable {
  const MissionEnemy({
    required this.id,
    required this.name,
    this.imagePath,
    this.xp,
    this.lifePoints,
    this.isLegendary = false,
  });

  final String id;
  final String name;
  final String? imagePath;
  final int? xp;
  final int? lifePoints;

  /// Leggendario: offerto solo nelle worldMission (D-19).
  final bool isLegendary;

  /// Confine di parsing: senza `id` o `name` stringa vale `null`.
  static MissionEnemy? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    final imagePath = json['imagePath'];
    return MissionEnemy(
      id: id,
      name: name,
      imagePath: imagePath is String ? imagePath : null,
      xp: missionIntOf(json['xp']),
      lifePoints: missionIntOf(json['lifePoints']),
      isLegendary: json['legendary'] == true,
    );
  }

  @override
  List<Object?> get props => [id, name, imagePath, xp, lifePoints, isLegendary];
}
