import 'package:equatable/equatable.dart';

/// Contenuto di una notifica di gioco (banner in-app, NOTIF-07): titolo e
/// descrizione.
class KGNotification extends Equatable {
  const KGNotification({required this.title, required this.description});

  factory KGNotification.fromJson(Map<String, dynamic> json) => KGNotification(
    title: json['title'] as String,
    description: json['description'] as String,
  );

  final String title;
  final String description;

  Map<String, dynamic> toJson() => {'title': title, 'description': description};

  @override
  List<Object?> get props => [title, description];
}
