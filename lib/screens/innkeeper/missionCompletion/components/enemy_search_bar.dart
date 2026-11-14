import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ricerca per nome e «Mostra tutti» della lista dei nemici (D-03, D-19): sta
/// accanto al contatore dei passi, così la lista prende tutta l'altezza (UAT
/// 2026-11-14).
class EnemySearchBar extends StatelessWidget {
  const EnemySearchBar({super.key});

  static const String searchLabel = 'Cerca';
  static const String showAllLabel = 'Mostra tutti';
  static const Key searchKey = ValueKey('mission.enemies.search');
  static const Key showAllKey = ValueKey('mission.enemies.showAll');

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MissionEnemiesCubit>();
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: searchKey,
            decoration: const InputDecoration(
              labelText: searchLabel,
              isDense: true,
            ),
            onChanged: cubit.setQuery,
          ),
        ),
        const SizedBox(width: KlimmeckGuideTheme.spacingSm),
        BlocSelector<MissionEnemiesCubit, MissionEnemiesState, bool>(
          selector: (state) => state.showAll,
          builder: (context, showAll) => FilterChip(
            key: showAllKey,
            label: const Text(showAllLabel),
            selected: showAll,
            onSelected: cubit.setShowAll,
          ),
        ),
      ],
    );
  }
}
