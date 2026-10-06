import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    try {
      return AuthSession(
        accessToken: json['accessToken'] as String,
        accessTokenExpiresAt: DateTime.parse(
          json['accessTokenExpiresAt'] as String,
        ),
        refreshToken: json['refreshToken'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
    } on TypeError {
      throw const FormatException('Invalid AuthSession payload');
    }
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final User user;

  @override
  List<Object?> get props => [
    accessToken,
    accessTokenExpiresAt,
    refreshToken,
    user,
  ];

  @override
  bool get stringify => false;

  @override
  String toString() =>
      'AuthSession(user: ${user.id}, expiresAt: $accessTokenExpiresAt)';
}
