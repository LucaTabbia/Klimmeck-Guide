import 'package:equatable/equatable.dart';

/// Ricarica di una pozione (BE Phase 18, D-13): dopo averla bevuta il
/// personaggio non ne beve altre per [time] millisecondi. [turns] è solo dato
/// per il motore di combattimento: non si mostra.
class LootRecovery extends Equatable {
  const LootRecovery({required this.time, required this.turns});

  final int time;
  final int turns;

  Duration get duration => Duration(milliseconds: time);

  /// Confine di parsing: una ricarica malformata o senza tempo vale `null`
  /// (per il backend una pozione senza tempo non si beve). Solo il tempo
  /// decide: turni assenti o malformati valgono 0 (D-21).
  static LootRecovery? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final time = json['time'];
    final turns = json['turns'];
    if (time is! int || time <= 0) return null;
    return LootRecovery(
      time: time,
      turns: turns is int && turns >= 0 ? turns : 0,
    );
  }

  Map<String, dynamic> toJson() => {'time': time, 'turns': turns};

  @override
  List<Object?> get props => [time, turns];
}
