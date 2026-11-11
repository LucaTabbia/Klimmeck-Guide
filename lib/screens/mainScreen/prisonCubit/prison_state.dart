part of 'prison_cubit.dart';

/// Tempo che manca alla fine della prigione, arrotondato per eccesso al
/// minuto; `null` = libero.
class PrisonState extends Equatable {
  const PrisonState(this.remaining);

  final Duration? remaining;

  bool get isImprisoned => remaining != null;

  @override
  List<Object?> get props => [remaining];
}
