import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';

/// Il k/N di «In attesa del gruppo» segue le accettazioni in tempo reale:
/// dall'accettazione (viaggio compreso) finché la corsia aspetta il gruppo la
/// quest è seguita via `questUpdated`; quando parte, si svuota o passa ad altra
/// quest il watch si ferma o cambia.
class PartyWatchListener extends StatefulWidget {
  const PartyWatchListener({super.key, required this.child});

  final Widget child;

  @override
  State<PartyWatchListener> createState() => _PartyWatchListenerState();
}

class _PartyWatchListenerState extends State<PartyWatchListener> {
  late final QuestCubit _questCubit;

  @override
  void initState() {
    super.initState();
    _questCubit = context.read<QuestCubit>();
    final watchedQuestId = _watchedQuestIdOf(
      context.read<CharacterCubit>().state,
    );
    if (watchedQuestId != null) _questCubit.watchQuest(watchedQuestId);
  }

  @override
  void dispose() {
    _questCubit.unwatchQuest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            _watchedQuestIdOf(previous) != _watchedQuestIdOf(current),
        listener: _follow,
        child: widget.child,
      );

  void _follow(BuildContext context, CharacterState state) {
    final watchedQuestId = _watchedQuestIdOf(state);
    if (watchedQuestId == null) {
      _questCubit.unwatchQuest();
      return;
    }
    _questCubit.watchQuest(watchedQuestId);
  }

  static String? _watchedQuestIdOf(CharacterState state) {
    if (state is! CharacterLoaded) return null;
    final lane = state.character.quests?.pendingQuest;
    if (lane == null || !(lane.isTravelling || lane.isWaitingForParty)) {
      return null;
    }
    return lane.quest?.id;
  }
}
