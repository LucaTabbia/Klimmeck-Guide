import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/character_deletion_repository.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/push/foreground_push_events.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';
import 'package:klimmeck_guide/repository/services/push/push_messaging_port.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/repository/storage/cubit/storage_cubit.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/main_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:klimmeck_guide/shared/components/kg_notification_banner.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Sessione autenticata: monta i Cubit gameplay, avvia il preload SVG
/// Cloudinary (REST autenticata, quindi solo ora) ed entra nel MainScreen del
/// personaggio della sessione (D-27).
///
/// I Cubit gameplay vivono qui e si chiudono quando `AuthGate` rimuove la
/// shell (logout/cambio account); usano `SafeEmit`, quindi una risposta
/// ancora in volo alla chiusura viene ignorata.
///
/// `SyncHealth` e `UserRefreshRequests` arrivano dallo scope di sessione
/// (`SessionSyncScope`), `AppLifecycleEvents` dalla radice dell'app, tutti
/// montati sopra la shell. La shell e' chiavata per id personaggio in
/// `SessionHome`: un nuovo id significa un nuovo cubit e mai due stream
/// personaggio vivi insieme (D-08).
///
/// Impostazioni: preferenze notifiche dell'utente di sessione e eliminazione
/// del personaggio (Phase 4), più lo stato del permesso notifiche di sistema
/// per la riga "disattivate" (Phase 5 D-10), chiusi con la shell.
///
/// Banner in-app per gli eventi push in foreground (Phase 5 D-13/D-17): solo
/// qui, quindi solo con un personaggio; la pagina di creazione non ne mostra.
///
/// `showDialog`/`showModalBottomSheet`/`Navigator.push` montano route sul
/// Navigator radice, FUORI da questi provider: passare i Cubit con
/// `BlocProvider.value` o leggerli prima di aprire la route.
class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({
    super.key,
    required this.graphQl,
    required this.characterId,
    required this.notificationPreferencesStore,
    required this.userId,
    required this.notificationPermission,
    required this.pushMessaging,
    this.mainScreenBuilder = _buildMainScreen,
  });

  final KlimmeckGraphQl graphQl;
  final String characterId;
  final NotificationPreferencesStore notificationPreferencesStore;
  final String userId;

  /// Permesso notifiche di sistema per la riga di Impostazioni (D-10).
  final NotificationPermissionPort notificationPermission;

  /// Messaggi push in foreground per i banner in-app (D-13/D-17).
  final PushMessagingPort pushMessaging;

  /// Sostituibile solo nei test, per non montare il MainScreen che fa rete.
  final Widget Function(BuildContext context, String characterId)
  mainScreenBuilder;

  static Widget _buildMainScreen(BuildContext context, String characterId) =>
      MainScreen(characterId: characterId);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StorageCubit>(create: (_) => StorageCubit()),
        BlocProvider<CharacterCubit>(
          create: (context) => CharacterCubit(
            graphQl,
            health: context.read<SyncHealth>(),
            lifecycle: context.read<AppLifecycleEvents>(),
            userRefresh: context.read<UserRefreshRequests>(),
          ),
        ),
        BlocProvider<QuestCubit>(create: (_) => QuestCubit(graphQl)),
        BlocProvider<TransactionCubit>(
          create: (_) => TransactionCubit(graphQl),
        ),
        BlocProvider<MainScreenCubit>(create: (_) => MainScreenCubit(graphQl)),
        BlocProvider<WorldMapCubit>(create: (_) => WorldMapCubit(graphQl)),
        BlocProvider<ShopCubit>(create: (_) => ShopCubit(graphQl)),
        BlocProvider<LibraryCubit>(create: (_) => LibraryCubit(graphQl)),
        BlocProvider<JournalCubit>(create: (_) => JournalCubit(graphQl)),
        BlocProvider<NotificationPreferencesCubit>(
          create: (_) => NotificationPreferencesCubit(
            notificationPreferencesStore,
            userId: userId,
          )..load(),
        ),
        BlocProvider<NotificationPermissionCubit>(
          create: (context) => NotificationPermissionCubit(
            notificationPermission,
            lifecycle: context.read<AppLifecycleEvents>(),
          )..refresh(),
        ),
        BlocProvider<InAppNotificationsCubit>(
          create: (context) => InAppNotificationsCubit(
            events: ForegroundPushEvents(
              messages: pushMessaging.foregroundMessages,
              preferences: notificationPreferencesStore,
              userId: userId,
            ).events,
            router: context.read<NotificationTapRouter>(),
          ),
        ),
        BlocProvider<CharacterDeletionCubit>(
          create: (_) => CharacterDeletionCubit(
            CharacterDeletionRepository(graphQl: graphQl),
          ),
        ),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          BlocListener<CharacterDeletionCubit, CharacterDeletionState>(
            listenWhen: (previous, current) =>
                previous.deletedUser == null && current.deletedUser != null,
            listener: _handOverDeletedUser,
            child: _ShellBody(
              characterId: characterId,
              mainScreenBuilder: mainScreenBuilder,
            ),
          ),
          const _InAppNotificationOverlay(),
        ],
      ),
    );
  }

  /// D-17: la sessione adotta lo User senza personaggio e SessionHome porta
  /// alla creazione; qui e non nel tab, così vale anche se il giocatore ha
  /// lasciato Impostazioni con la mutation in volo. Se l'adozione è
  /// rifiutata il tab lo dice (userUpdated resta il backup).
  static void _handOverDeletedUser(
    BuildContext context,
    CharacterDeletionState state,
  ) {
    final adopted = context.read<AuthCubit>().adoptUser(state.deletedUser!);
    if (!adopted) context.read<CharacterDeletionCubit>().handoverRejected();
  }
}

class _ShellBody extends StatefulWidget {
  const _ShellBody({
    required this.characterId,
    required this.mainScreenBuilder,
  });

  final String characterId;
  final Widget Function(BuildContext context, String characterId)
  mainScreenBuilder;

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  @override
  void initState() {
    super.initState();
    context.read<SplashCubit>().getImages('main');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplashCubit, SplashState>(
      builder: (context, state) => _isPreloadSettled(state)
          ? widget.mainScreenBuilder(context, widget.characterId)
          : const SplashScreen(),
    );
  }

  /// Un preload fallito non blocca: `CachedSvg` ricade sulla rete.
  static bool _isPreloadSettled(SplashState state) =>
      state is SplashData || state is SplashError;
}

/// Banner in alto sopra il gioco (D-17); i dialog sul Navigator radice restano
/// sopra (accettato). Il tap passa solo dal cubit (UI → Cubit → Service, D-19).
/// Gli avvisi locali (Phase 6) usano lo stesso banner; il tap li chiude soltanto.
class _InAppNotificationOverlay extends StatelessWidget {
  const _InAppNotificationOverlay();

  static const Duration _transition = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingSm),
          child: BlocBuilder<InAppNotificationsCubit, InAppNotificationsState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: _transition,
              child: _bannerFor(context, state),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _bannerFor(
    BuildContext context,
    InAppNotificationsState state,
  ) {
    final event = state.current;
    if (event != null) {
      return KgNotificationBanner(
        key: ValueKey(event.dedupKey),
        notification: event.notification,
        onTap: () => context.read<InAppNotificationsCubit>().open(event),
      );
    }
    final notice = state.notice;
    if (notice != null) {
      return KgNotificationBanner(
        key: ValueKey('notice|${notice.dedupKey}'),
        notification: notice.notification,
        onTap: () => context.read<InAppNotificationsCubit>().dismiss(),
      );
    }
    return const SizedBox.shrink();
  }
}
