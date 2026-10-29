import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';

/// Unico ingresso del pannello (10-CONTEXT D-04/C11): la route vive sul
/// Navigator radice, fuori dai provider della shell, quindi repository e
/// orologio del server si leggono qui dal chiamante e passano con `.value`.
/// `AppLifecycleEvents` e `AuthCubit` stanno sopra MaterialApp.
Future<void> openInnkeeperPanel(BuildContext context) {
  final repository = context.read<InnkeeperRepository>();
  final clock = context.read<ServerClockService>();
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => RepositoryProvider<InnkeeperRepository>.value(
        value: repository,
        child: BlocProvider<PendingRequestsCubit>(
          create: (routeContext) => PendingRequestsCubit(
            repository: repository,
            clock: clock,
            lifecycle: routeContext.read<AppLifecycleEvents>(),
          )..start(),
          child: const InnkeeperPanelScreen(),
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
