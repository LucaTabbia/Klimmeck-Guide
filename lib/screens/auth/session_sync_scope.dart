import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/session_terminator.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_watchdog.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/syncCubit/session_sync_cubit.dart';

/// Ambito di sync della sessione (Phase 3): vive sotto la chiave `user.id` di
/// `AuthGate`, quindi logout, revoca, sync persa e cambio account lo smontano e
/// chiudono stream, timer e cubit. Avvia subito (`lazy: false`) l'unico
/// consumer di `userUpdated` e osserva il socket una sola volta per sessione.
class SessionSyncScope extends StatelessWidget {
  const SessionSyncScope({
    super.key,
    required this.graphQl,
    required this.terminator,
    required this.openConnectionStream,
    required this.child,
  });

  final KlimmeckGraphQl graphQl;
  final SessionTerminator terminator;
  final Stream<bool> Function() openConnectionStream;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SyncWatchdog>(
          create: (_) => SyncWatchdog(
            onExpired: () =>
                terminator.terminateSession(UnauthenticatedReason.syncLost),
          ),
          dispose: (watchdog) => watchdog.dispose(),
        ),
        RepositoryProvider<SyncHealth>(
          create: (context) => context.read<SyncWatchdog>(),
        ),
        RepositoryProvider<UserRefreshRequestBus>(
          create: (_) => UserRefreshRequestBus(),
          dispose: (bus) => bus.close(),
        ),
        RepositoryProvider<UserRefreshRequests>(
          create: (context) => context.read<UserRefreshRequestBus>(),
        ),
      ],
      child: BlocProvider<SessionSyncCubit>(
        lazy: false,
        create: (context) => SessionSyncCubit(
          api: graphQl,
          auth: context.read<AuthTokenService>(),
          watchdog: context.read<SyncWatchdog>(),
          connection: openConnectionStream(),
          lifecycle: context.read<AppLifecycleEvents>(),
          userRefreshRequests: context.read<UserRefreshRequestBus>().requests,
        )..start(),
        child: child,
      ),
    );
  }
}
