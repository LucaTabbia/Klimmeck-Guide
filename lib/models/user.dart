import 'package:equatable/equatable.dart';

import 'character/character.dart';
import 'enums/role_type.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.twitchId,
    required this.twitchPoints,
    required this.currentCharacter,
    required this.role,
  });

  final String id;
  final String? twitchId;
  final RoleType? role;
  final int? twitchPoints; // Reso final
  final Character? currentCharacter; // Reso final

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

  User copyWith({
    String? id,
    String? twitchId,
    RoleType? role,
    int? twitchPoints,
    Character? currentCharacter,
  }) {
    return User(
      id: id ?? this.id,
      twitchId: twitchId ?? this.twitchId,
      role: role ?? this.role,
      twitchPoints: twitchPoints ?? this.twitchPoints,
      currentCharacter: currentCharacter ?? this.currentCharacter,
    );
  }

  @override
  List<Object?> get props => [
    id,
    twitchId,
    role,
    twitchPoints,
    currentCharacter,
  ];
}
