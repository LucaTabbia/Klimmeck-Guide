import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';

/// Esiti dell'accettazione a livello di sessione: banner, rilettura della lista
/// e reset sopravvivono all'uscita dalla Board (D-04, D-20 C1/C5).
class QuestAcceptanceOutcomeListener extends StatelessWidget {
  const QuestAcceptanceOutcomeListener({
    super.key,
    required this.cities,
    required this.child,
  });

  final List<City> cities;
  final Widget child;

  /// Dopo questi rifiuti la lista può essere cambiata sul server; `timedOut`
  /// perché il BE può aver accettato la quest dopo la scadenza client.
  static const Set<QuestAcceptanceFailure> _staleListFailures = {
    QuestAcceptanceFailure.full,
    QuestAcceptanceFailure.alreadyTaken,
    QuestAcceptanceFailure.notFound,
    QuestAcceptanceFailure.timedOut,
  };

  @override
  Widget build(BuildContext context) =>
      BlocListener<QuestAcceptanceCubit, QuestAcceptanceState>(
        listenWhen: (previous, current) =>
            current is QuestAccepted || current is QuestAcceptanceFailed,
        listener: _onOutcome,
        child: child,
      );

  void _onOutcome(BuildContext context, QuestAcceptanceState state) {
    if (state is QuestAcceptanceFailed) {
      _announce(context, state);
      if (_staleListFailures.contains(state.failure)) {
        context.read<QuestCubit>().refreshQuests(
          cityId: _currentCityId(context),
        );
      }
    }
    context.read<QuestAcceptanceCubit>().reset();
  }

  void _announce(BuildContext context, QuestAcceptanceFailed state) {
    final notice = questAcceptanceNoticeFor(
      state.failure,
      type: _questById(context, state.questId)?.infos?.type,
    );
    if (notice == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notice,
      dedupKey: 'quest-acceptance|${state.failure.name}|${state.questId}',
    );
  }

  String? _currentCityId(BuildContext context) {
    final character = context.read<CharacterCubit>().state;
    if (character is! CharacterLoaded) return null;
    return currentCityOf(cities, character.character.status?.location)?.id;
  }

  Quest? _questById(BuildContext context, String questId) {
    final quests = context.read<QuestCubit>().state;
    if (quests is! QuestLoaded) return null;
    for (final quest in quests.quests) {
      if (quest.id == questId) return quest;
    }
    return null;
  }
}
