import 'package:equatable/equatable.dart';

import '../enums/title_type.dart';

/// Posto per rango di `requirements.requiredAdventurers` (BE Phase 8 D-28):
/// `title` nullo = qualsiasi rango.
class AdventurerSlot extends Equatable {
  const AdventurerSlot({required this.title, required this.count});

  final TitleType? title;
  final int count;

  factory AdventurerSlot.fromJson(Map<String, dynamic> json) => AdventurerSlot(
    title: json['title'] == null
        ? null
        : TitleType.values.byName(json['title'] as String),
    count: (json['count'] as num).toInt(),
  );

  /// Forma Phase 8 (lista di slot) o Phase 7 (`Int`: un unico slot senza rango).
  static List<AdventurerSlot> listFrom(Object? wire) => switch (wire) {
    final List<dynamic> list => List.unmodifiable(
      list.cast<Map<String, dynamic>>().map(AdventurerSlot.fromJson),
    ),
    final num total when total > 0 => [
      AdventurerSlot(title: null, count: total.toInt()),
    ],
    _ => const [],
  };

  Map<String, dynamic> toJson() => {'title': title?.name, 'count': count};

  @override
  List<Object?> get props => [title, count];
}
