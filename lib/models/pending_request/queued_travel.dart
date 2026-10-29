import 'package:equatable/equatable.dart';

/// Viaggio libero di un personaggio in coda (selezione `activeTravel { endTime to }`, 10-CONTEXT D-10/C4): mai `ActiveTravel`, che richiede `road` e leggerebbe un viaggiatore come fermo.
class QueuedTravel extends Equatable {
  const QueuedTravel({required this.endTime, required this.destinationId});

  final DateTime endTime;
  final String destinationId;

  factory QueuedTravel.fromJson(Map<String, dynamic> json) => QueuedTravel(
    endTime: DateTime.parse(json['endTime'] as String).toUtc(),
    destinationId: json['to'] as String,
  );

  static QueuedTravel? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return QueuedTravel.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  List<Object?> get props => [endTime, destinationId];
}
