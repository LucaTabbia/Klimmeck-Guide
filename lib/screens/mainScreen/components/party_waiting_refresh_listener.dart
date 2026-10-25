import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';

/// WR-02: il k/N di «In attesa del gruppo» legge la lista quest, che nessuno
/// rilegge sulla mappa. Quando la corsia entra in attesa la lista si rilegge in
/// silenzio; il conteggio resta best-effort finché il BE non lo porta sulla corsia.
class PartyWaitingRefreshListener extends StatelessWidget {
  const PartyWaitingRefreshListener({
    super.key,
    required this.cities,
    required this.child,
  });

  final List<City> cities;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            !_isWaiting(previous) && _isWaiting(current),
        listener: _refreshQuests,
        child: child,
      );

  static bool _isWaiting(CharacterState state) =>
      _pendingLaneOf(state)?.isWaitingForParty ?? false;

  static PendingQuest? _pendingLaneOf(CharacterState state) =>
      state is CharacterLoaded ? state.character.quests?.pendingQuest : null;

  void _refreshQuests(BuildContext context, CharacterState state) {
    final location = (state as CharacterLoaded).character.status?.location;
    context.read<QuestCubit>().refreshQuests(
      cityId: currentCityOf(cities, location)?.id,
    );
  }
}
