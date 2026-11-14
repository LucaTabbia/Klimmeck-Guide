import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';

/// Unico ingresso del pannello (10-CONTEXT D-04/C11): la route vive sul
/// Navigator radice, fuori dai provider della shell, quindi repository,
/// orologio del server e la modalità teletrasporto della shell (D-15) si
/// leggono qui dal chiamante e passano con `.value`. `AppLifecycleEvents` e
/// `AuthCubit` stanno sopra MaterialApp. `QuestGenerationCubit` vive con la
/// route (14-CONTEXT D-10). [resumeCardKey] riapre il completamento di quella
/// carta dopo il teletrasporto (21-CONTEXT D-28).
Future<void> openInnkeeperPanel(BuildContext context, {String? resumeCardKey}) {
  final repository = context.read<InnkeeperRepository>();
  final clock = context.read<ServerClockService>();
  final teleport = context.read<TeleportModeCubit>();
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => RepositoryProvider<InnkeeperRepository>.value(
        value: repository,
        child: BlocProvider<TeleportModeCubit>.value(
          value: teleport,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PendingRequestsCubit>(
                create: (routeContext) => PendingRequestsCubit(
                  repository: repository,
                  clock: clock,
                  lifecycle: routeContext.read<AppLifecycleEvents>(),
                )..start(),
              ),
              BlocProvider<QuestGenerationCubit>(
                create: (_) => QuestGenerationCubit(repository: repository),
              ),
            ],
            child: InnkeeperPanelScreen(resumeCardKey: resumeCardKey),
          ),
        ),
      ),
    ),
  );
}

/// Chiude il pannello e ciò che gli sta sopra (form, dialog) dal suo contesto.
void closeInnkeeperPanel(BuildContext panelContext) {
  final panel = ModalRoute.of(panelContext);
  if (panel == null || !panel.isActive) return;
  final navigator = Navigator.of(panelContext);
  navigator.popUntil((route) => route == panel);
  navigator.pop();
}
