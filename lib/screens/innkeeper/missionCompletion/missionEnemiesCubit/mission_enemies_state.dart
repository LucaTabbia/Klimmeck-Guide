part of 'mission_enemies_cubit.dart';

/// Nemici come li serve il BE, nel suo ordine (D-19); la ricerca per nome
/// cambia solo ciò che si mostra (D-03).
final class MissionEnemiesState extends Equatable {
  const MissionEnemiesState({
    this.enemies = const [],
    this.showAll = false,
    this.query = '',
    this.isLoading = false,
    this.failure,
  });

  final List<MissionEnemy> enemies;

  /// «Mostra tutti»: l'intero bestiario invece della lista del luogo (D-03).
  final bool showAll;
  final String query;
  final bool isLoading;

  /// Ultima lettura fallita: la lista precedente resta.
  final InnkeeperFailure? failure;

  List<MissionEnemy> get visible {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return enemies;
    return List.unmodifiable(
      enemies.where((enemy) => enemy.name.toLowerCase().contains(needle)),
    );
  }

  /// [failure] assente lascia quello attuale; una funzione lo sostituisce.
  MissionEnemiesState copyWith({
    List<MissionEnemy>? enemies,
    bool? showAll,
    String? query,
    bool? isLoading,
    InnkeeperFailure? Function()? failure,
  }) => MissionEnemiesState(
    enemies: enemies ?? this.enemies,
    showAll: showAll ?? this.showAll,
    query: query ?? this.query,
    isLoading: isLoading ?? this.isLoading,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [enemies, showAll, query, isLoading, failure];
}
