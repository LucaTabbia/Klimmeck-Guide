import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest_result/ambush_city.dart';

/// Report di un'imboscata (BE Phase 15 D-13/D-14): istante, città del POI
/// più vicino e, dopo una sconfitta, la città raggiunta. Rigido dentro,
/// tollerante solo sull'assenza di `reachedCity` (vittoria).
class AmbushReport extends Equatable {
  const AmbushReport({
    required this.at,
    required this.nearCity,
    this.reachedCity,
    this.isOnFoot = false,
  });

  final DateTime at;
  final AmbushCity nearCity;

  /// `null` in vittoria: il viaggio non cambia (16-CONTEXT D-04).
  final AmbushCity? reachedCity;

  /// Il compagno da cavalcatura è caduto: si prosegue a piedi (BE Phase 23,
  /// D-28); assente o illeggibile vale false.
  final bool isOnFoot;

  factory AmbushReport.fromJson(Map<String, dynamic> json) {
    final reached = json['reachedCity'];
    return AmbushReport(
      at: DateTime.parse(json['at'] as String).toUtc(),
      nearCity: AmbushCity.fromJson(json['nearCity'] as Map<String, dynamic>),
      reachedCity: reached == null
          ? null
          : AmbushCity.fromJson(reached as Map<String, dynamic>),
      isOnFoot: json['onFoot'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'nearCity': nearCity.toJson(),
    'reachedCity': reachedCity?.toJson(),
    'onFoot': isOnFoot,
  };

  @override
  List<Object?> get props => [at, nearCity, reachedCity, isOnFoot];
}
