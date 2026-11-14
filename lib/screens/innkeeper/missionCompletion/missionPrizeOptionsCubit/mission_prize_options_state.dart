part of 'mission_prize_options_cubit.dart';

/// Opzioni di premio servite per personaggio (D-07, D-22), tenute come
/// arrivano: il catalogo è già quello ammesso dal BE.
final class MissionPrizeOptionsState extends Equatable {
  const MissionPrizeOptionsState({
    this.options = const {},
    this.loading = const {},
    this.failures = const {},
  });

  /// Id del personaggio → opzioni servite.
  final Map<String, MissionPrizeOptions> options;

  /// Personaggi con una lettura in volo.
  final Set<String> loading;

  /// Id del personaggio → ultima lettura fallita.
  final Map<String, InnkeeperFailure> failures;

  MissionPrizeOptionsState copyWith({
    Map<String, MissionPrizeOptions>? options,
    Set<String>? loading,
    Map<String, InnkeeperFailure>? failures,
  }) => MissionPrizeOptionsState(
    options: Map.unmodifiable(options ?? this.options),
    loading: Set.unmodifiable(loading ?? this.loading),
    failures: Map.unmodifiable(failures ?? this.failures),
  );

  @override
  List<Object?> get props => [options, loading, failures];
}
