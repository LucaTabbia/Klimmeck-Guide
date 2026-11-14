import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Lista dei nemici serviti dal BE, nel suo ordine (D-03, D-19); ricerca e
/// «Mostra tutti» stanno in `EnemySearchBar`. Una lettura fallita senza nemici
/// mostra l'errore e «Riprova», mai una lista vuota muta.
class EnemyPicker extends StatelessWidget {
  const EnemyPicker({super.key, required this.onPick});

  static const String legendaryLabel = 'Leggendario';
  static const Key retryKey = ValueKey('mission.enemies.retry');
  static Key enemyKeyFor(String enemyId) =>
      ValueKey('mission.enemies.row.$enemyId');

  static const double _portraitHeight = 48;
  static const String _unknown = '–';

  final ValueChanged<MissionEnemy> onPick;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MissionEnemiesCubit>();
    return BlocBuilder<MissionEnemiesCubit, MissionEnemiesState>(
      builder: (context, state) {
        final visible = state.visible;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isLoading && visible.isEmpty)
              const KGLoader(height: _portraitHeight),
            if (state.failure case final failure? when state.enemies.isEmpty)
              _failureRow(failure, cubit.load),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (_, index) => _row(visible[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _failureRow(InnkeeperFailure failure, VoidCallback onRetry) {
    return Row(
      children: [
        Expanded(
          child: Text(
            MissionCompletionScreen.failureLineOf(failure),
            style: KlimmeckGuideTheme.instance.bodyMedium,
          ),
        ),
        TextButton(
          key: retryKey,
          onPressed: onRetry,
          child: const Text(MissionCompletionScreen.retryLabel),
        ),
      ],
    );
  }

  Widget _row(MissionEnemy enemy) {
    return ListTile(
      key: enemyKeyFor(enemy.id),
      leading: EnemyPortrait(
        imagePath: enemy.imagePath,
        height: _portraitHeight,
      ),
      title: Text(enemy.name),
      subtitle: Text(
        'PE ${enemy.xp ?? _unknown} · PV ${enemy.lifePoints ?? _unknown}',
      ),
      trailing: enemy.isLegendary ? const Text(legendaryLabel) : null,
      onTap: () => onPick(enemy),
    );
  }
}
