import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';

/// Il wizard vive sul Navigator del pannello come il form di Phase 10:
/// repository, coda e modalità teletrasporto passano con `.value` (Phase 10
/// D-04); i Cubit del wizard nascono e muoiono con la route (D-28).
/// [atPlace]: riapre su «Luogo» dopo un teletrasporto annullato.
Future<CompletionExit?> openMissionCompletion(
  BuildContext panelContext,
  RequestCard card, {
  bool atPlace = false,
}) {
  final repository = panelContext.read<InnkeeperRepository>();
  final queue = panelContext.read<PendingRequestsCubit>();
  final teleport = panelContext.read<TeleportModeCubit>();
  final pendingQuestId = card.pendingQuestId;
  return Navigator.of(panelContext).push<CompletionExit>(
    MaterialPageRoute(
      builder: (_) => RepositoryProvider<InnkeeperRepository>.value(
        value: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PendingRequestsCubit>.value(value: queue),
            BlocProvider<TeleportModeCubit>.value(value: teleport),
            BlocProvider<MissionDraftCubit>(
              create: (_) => MissionDraftCubit(
                repository: repository,
                pendingQuestId: pendingQuestId,
              )..load(),
            ),
            BlocProvider<MissionParticipantsCubit>(
              create: (_) => MissionParticipantsCubit(repository: repository),
            ),
            BlocProvider<MissionEnemiesCubit>(
              create: (_) => MissionEnemiesCubit(
                repository: repository,
                pendingQuestId: pendingQuestId,
              ),
            ),
            BlocProvider<MissionPrizeOptionsCubit>(
              create: (_) => MissionPrizeOptionsCubit(
                repository: repository,
                pendingQuestId: pendingQuestId,
              ),
            ),
          ],
          child: MissionCompletionScreen(card: card, opensAtPlace: atPlace),
        ),
      ),
    ),
  );
}
