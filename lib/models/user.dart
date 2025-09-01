import 'character/character.dart';
import 'enums/role_type.dart';

class User {
  User({
    required this.id,
    required this.twitchId,
    required this.twitchPoints,
    required this.currentCharacter,
    required this.role,
  });

  final String id;
  final String? twitchId;
  final RoleType? role;
  int? twitchPoints;
  Character? currentCharacter;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    twitchId: json["twitchId"],
    twitchPoints: (json["twitchPoints"] as num?)?.toInt(),
    currentCharacter: json["currentCharacter"] != null
        ? Character.fromJson(json["currentCharacter"])
        : null,
    role: json["role"] != null ? RoleType.values.byName(json["role"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "twitchId": twitchId,
    "twitchPoints": twitchPoints,
    "currentCharacter": currentCharacter?.id,
    "role": role?.name,
  };
}
