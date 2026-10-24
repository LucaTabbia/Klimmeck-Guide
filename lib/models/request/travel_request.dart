import 'package:equatable/equatable.dart';

/// Input `TravelRequest` di `travelPreview`/`startTravel` (BE Phase 8).
class TravelRequest extends Equatable {
  const TravelRequest({required this.id, required this.poiId});

  /// Id del personaggio corrente (mai digitato dall'utente).
  final String id;

  /// Id del marker della città di arrivo (`City.markerLocation.id`).
  final String poiId;

  Map<String, dynamic> toJson() => {'id': id, 'poiId': poiId};

  @override
  List<Object?> get props => [id, poiId];
}
