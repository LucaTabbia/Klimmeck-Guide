import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/travel/travel_path.dart';

/// Anteprima del viaggio libero (`travelPreview`): nessun `startTime`, l'ETA è ora server + duration (BE handoff §4).
class TravelPreview extends Equatable {
  const TravelPreview({
    required this.distance,
    required this.duration,
    required this.road,
  });

  final double distance;

  /// Millisecondi.
  final double duration;
  final TravelPath road;

  factory TravelPreview.fromJson(Map<String, dynamic> json) => TravelPreview(
    distance: (json['distance'] as num).toDouble(),
    duration: (json['duration'] as num).toDouble(),
    road: TravelPath.fromJson(json['road'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'duration': duration,
    'road': road.toJson(),
  };

  @override
  List<Object?> get props => [distance, duration, road];
}
