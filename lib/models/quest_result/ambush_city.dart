import 'package:equatable/equatable.dart';

/// Città nominata da un report d'imboscata (BE Phase 15 D-14): il FE stampa
/// il nome, non sceglie la città (regola 4).
class AmbushCity extends Equatable {
  const AmbushCity({required this.id, required this.name});

  final String id;
  final String name;

  factory AmbushCity.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    if (name.isEmpty) {
      throw const FormatException('ambush city without a name');
    }
    return AmbushCity(id: json['id'] as String, name: name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  List<Object?> get props => [id, name];
}
