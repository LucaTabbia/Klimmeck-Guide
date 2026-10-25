import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart';

/// Esiti dell'abbandono a livello di sessione: l'avviso sopravvive alla
/// chiusura del foglio; il successo non mostra nulla (la corsia si svuota).
class QuestAbandonOutcomeListener extends StatelessWidget {
  const QuestAbandonOutcomeListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<QuestAbandonCubit, QuestAbandonState>(
        listenWhen: (_, current) =>
            current is QuestAbandoned || current is QuestAbandonFailed,
        listener: _onOutcome,
        child: child,
      );

  void _onOutcome(BuildContext context, QuestAbandonState state) {
    if (state is QuestAbandonFailed) _announce(context, state);
    context.read<QuestAbandonCubit>().reset();
  }

  void _announce(BuildContext context, QuestAbandonFailed state) {
    final notice = questAbandonNoticeFor(state.failure);
    if (notice == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notice,
      dedupKey: 'quest-abandon|${state.failure.name}|${state.questId}',
    );
  }
}
