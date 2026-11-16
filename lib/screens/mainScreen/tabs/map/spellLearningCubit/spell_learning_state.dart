part of 'spell_learning_cubit.dart';

/// Tempo che manca alla fine dell'apprendimento, arrotondato per eccesso al
/// minuto; `null` = nessun apprendimento in corso.
class SpellLearningState extends Equatable {
  const SpellLearningState(this.remaining);

  final Duration? remaining;

  bool get isLearning => remaining != null;

  @override
  List<Object?> get props => [remaining];
}
