import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/travel/travel_path.dart';

/// Viaggio in corso del personaggio (`status.activeTravel`, BE Phase 8).
class ActiveTravel extends Equatable {
  const ActiveTravel({
    required this.road,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.to,
  });

  final TravelPath road;
  final DateTime startTime;
  final DateTime endTime;

  /// Millisecondi, = endTime − startTime.
  final double duration;

  /// Id del POI di arrivo, non popolato (C2): per un viaggio automatico è il marker di una quest.
  final String to;

  factory ActiveTravel.fromJson(Map<String, dynamic> json) => ActiveTravel(
    road: TravelPath.fromJson(json['road'] as Map<String, dynamic>),
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    duration: (json['duration'] as num).toDouble(),
    to: json['to'] as String,
  );

  // Confine di parsing: un viaggio malformato vale "nessun viaggio", il BE resta giudice.
  static ActiveTravel? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return ActiveTravel.fromJson(json);
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'road': road.toJson(),
    'startTime': startTime.toUtc().toIso8601String(),
    'endTime': endTime.toUtc().toIso8601String(),
    'duration': duration,
    'to': to,
  };

  @override
  List<Object?> get props => [road, startTime, endTime, duration, to];
}
