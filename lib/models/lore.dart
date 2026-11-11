import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';

class Lore extends Equatable {
  const Lore({
    required this.imagePath,
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.relatedLore,
  });

  final String id;
  final LoreType? type;
  final String? imagePath;
  final String? name;
  final String? description;
  final List<Lore>? relatedLore;

  factory Lore.fromJson(Map<String, dynamic> json) => Lore(
    id: json["id"],
    type: _typeFrom(json['type']),
    name: json["name"],
    description: json["description"],
    relatedLore: json['relatedLore'] != null
        ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
        : [],
    imagePath: json["imagePath"],
  );

  /// Tollerante (D-16): un tipo sconosciuto o assente vale `null` e la voce
  /// resta (nessuna sezione della Biblioteca, «Conoscenza appresa» sul foglio).
  static LoreType? _typeFrom(Object? wire) =>
      wire is String ? LoreType.values.asNameMap()[wire] : null;

  /// Riferimenti a lore `{ id name type }` letti voce per voce: una voce senza
  /// id o senza nome è scartata, ciò che non è una lista vale una lista vuota.
  static List<Lore> lenientRefsFrom(Object? json) {
    if (json is! List) return const [];
    return List<Lore>.unmodifiable(
      json.whereType<Map<String, dynamic>>().map(_refOrNull).nonNulls,
    );
  }

  static Lore? _refOrNull(Map<String, dynamic> json) {
    try {
      final lore = Lore.fromJson(json);
      final name = lore.name;
      return name == null || name.isEmpty ? null : lore;
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.name,
    "name": name,
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "description": description,
    "imagePath": imagePath,
  };

  Lore copyWith({
    String? imagePath,
    String? id,
    LoreType? type,
    String? name,
    String? description,
    List<Lore>? relatedLore,
  }) {
    return Lore(
      imagePath: imagePath ?? this.imagePath,
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      relatedLore: relatedLore ?? this.relatedLore,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    imagePath,
    name,
    description,
    relatedLore,
  ];
}
