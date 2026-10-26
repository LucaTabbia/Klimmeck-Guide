import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';

/// Il k/N di «In attesa del gruppo» segue le accettazioni in tempo reale:
/// finché la corsia aspetta il gruppo la quest è seguita via `questUpdated`;
/// quando parte, si svuota o passa ad altra quest il watch si ferma o cambia.
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
    final awaitedQuestId = _awaitedQuestIdOf(
      context.read<CharacterCubit>().state,
    );
    if (awaitedQuestId != null) _questCubit.watchQuest(awaitedQuestId);
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
            _awaitedQuestIdOf(previous) != _awaitedQuestIdOf(current),
        listener: _follow,
        child: widget.child,
      );

  void _follow(BuildContext context, CharacterState state) {
    final awaitedQuestId = _awaitedQuestIdOf(state);
    if (awaitedQuestId == null) {
      _questCubit.unwatchQuest();
      return;
    }
    _questCubit.watchQuest(awaitedQuestId);
  }

  static String? _awaitedQuestIdOf(CharacterState state) {
    if (state is! CharacterLoaded) return null;
    final lane = state.character.quests?.pendingQuest;
    if (lane == null || !lane.isWaitingForParty) return null;
    return lane.quest?.id;
  }
}
