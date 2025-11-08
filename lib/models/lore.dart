import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';

class Lore extends Equatable {
  const Lore({
    required this.image,
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.relatedLore,
    required this.unlocked,
  });

  final String id;
  final LoreType? type;
  final String? image;
  final String? name;
  final String? description;
  final List<Lore>? relatedLore;
  final bool? unlocked;

  factory Lore.fromJson(Map<String, dynamic> json) => Lore(
    id: json["id"],
    type: json["type"] != null ? LoreType.values.byName(json["type"]) : null,
    name: json["name"],
    description: json["description"],
    relatedLore: json['relatedLore'] != null
        ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
        : [],
    unlocked: json["unlocked"] ?? false,
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.name,
    "name": name,
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "description": description,
    "unlocked": unlocked,
    "image": image,
  };

  Lore copyWith({
    String? image,
    String? id,
    LoreType? type,
    String? name,
    String? description,
    List<Lore>? relatedLore,
    bool? unlocked,
  }) {
    return Lore(
      image: image ?? this.image,
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      relatedLore: relatedLore ?? this.relatedLore,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    image,
    name,
    description,
    relatedLore,
    unlocked,
  ];
}
