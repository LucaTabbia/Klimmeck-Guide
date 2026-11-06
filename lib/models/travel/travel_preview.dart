import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/travel/travel_path.dart';

import 'travel_food_item.dart';

/// Anteprima del viaggio (`travelPreview` / `questTravelPreview`): nessun `startTime`, l'ETA è ora server + duration (BE handoff §4); cibo e vita persa dal BE (BE Phase 14).
class TravelPreview extends Equatable {
  const TravelPreview({
    required this.distance,
    required this.duration,
    required this.road,
    this.food = const [],
    this.hpLost = 0,
    this.arrivesAlive = true,
  });

  final double distance;

  /// Millisecondi.
  final double duration;
  final TravelPath road;

  /// Cibo che il BE mangerà, nell'ordine del BE (BE Phase 14 D-09); vuoto con un BE più vecchio.
  final List<TravelFoodItem> food;

  /// Vita persa sui km scoperti, calcolata dal BE (FOOD-04): il FE la stampa soltanto.
  final int hpLost;

  /// `false` = il BE rifiuterebbe la partenza per fame (D-02): «Parti» e lo swipe spenti.
  final bool arrivesAlive;

  factory TravelPreview.fromJson(Map<String, dynamic> json) => TravelPreview(
    distance: (json['distance'] as num).toDouble(),
    duration: (json['duration'] as num).toDouble(),
    road: TravelPath.fromJson(json['road'] as Map<String, dynamic>),
    food: TravelFoodItem.listFrom(json['food']),
    hpLost: json['hpLost'] is num ? (json['hpLost'] as num).toInt() : 0,
    arrivesAlive: json['arrivesAlive'] is bool
        ? json['arrivesAlive'] as bool
        : true,
  );

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'duration': duration,
    'road': road.toJson(),
    'food': [for (final entry in food) entry.toJson()],
    'hpLost': hpLost,
    'arrivesAlive': arrivesAlive,
  };

  @override
  List<Object?> get props => [
    distance,
    duration,
    road,
    food,
    hpLost,
    arrivesAlive,
  ];
}
