import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/character_creation_repository.dart';
import 'package:klimmeck_guide/repository/push_device_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/image/image_picker_portrait_picker.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_gate.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';
import 'package:klimmeck_guide/repository/services/push/push_bootstrap.dart';
import 'package:klimmeck_guide/repository/services/push/push_registration_coordinator.dart';
import 'package:klimmeck_guide/repository/services/push/push_services.dart';
import 'package:klimmeck_guide/repository/services/push/url_launcher_link_opener.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/repository/services/rest/rest_client_provider.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/storage/active_user_store.dart';
import 'package:klimmeck_guide/repository/storage/device_identity_store.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';
import 'package:klimmeck_guide/repository/storage/session_store.dart';
import 'package:klimmeck_guide/screens/auth/app_lifecycle_bridge.dart';
import 'package:klimmeck_guide/screens/auth/auth_gate.dart';
import 'package:klimmeck_guide/screens/auth/authenticated_shell.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';
import 'package:klimmeck_guide/screens/auth/session_home.dart';
import 'package:klimmeck_guide/screens/auth/session_sync_scope.dart';
import 'package:klimmeck_guide/screens/characterCreation/character_creation_screen.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  // Phase 5 D-02: senza google-services.json il push resta disabilitato, il gioco no.
  final push = await bootstrapPush();

  late final GraphQLClientHolder graphQlHolder;
  final auth = _buildAuth(onSessionTeardown: () => graphQlHolder.reset());
  graphQlHolder = GraphQLClientHolder(
    connect: () => buildGraphQLConnection(
      authService: auth.service,
      recovery: auth.recovery,
    ),
  );
  final restClient = RestClient(
    authTokenService: auth.service,
    recovery: auth.recovery,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: true,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Il bootstrap della sessione parte da AuthCubit.start() dopo il primo
  // frame (D-33): nessuna chiamata di rete blocca runApp.
  runApp(
    KlimmeckGuideApp(
      authTokenService: auth.service,
      sessionTerminator: auth.terminator,
      openConnectionStream: graphQlHolder.watchConnection,
      restClient: restClient,
      graphQlClient: graphQlHolder.client,
      push: push,
    ),
  );
}

/// Composition root dell'auth (D-23): l'unico punto che legge [EnvConfig] per
/// scegliere l'implementazione. Il bypass dev non ha recovery (nessun refresh).
({
  AuthTokenService service,
  UnauthorizedRecovery? recovery,
  SessionTerminator terminator,
})
_buildAuth({required Future<void> Function() onSessionTeardown}) {
  final backendAuthApi = GraphQlBackendAuthApi.forEndpoint(
    EnvConfig.graphqlHttpUrl,
  );
  if (EnvConfig.devAuthEnabled) {
    final devService = DevAuthTokenService(
      meSource: backendAuthApi,
      onSessionTeardown: onSessionTeardown,
    );
    return (service: devService, recovery: null, terminator: devService);
  }
  final service = SessionAuthTokenService(
    api: backendAuthApi,
    store: SecureSessionStore(),
    browser: const FlutterWebAuth2BrowserAuthenticator(),
    backendBaseUrl: Uri.parse(EnvConfig.baseUrl),
    onSessionTeardown: onSessionTeardown,
  );
  return (service: service, recovery: service, terminator: service);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class KlimmeckGuideApp extends StatefulWidget {
  const KlimmeckGuideApp({
    super.key,
    required this.authTokenService,
    required this.sessionTerminator,
    required this.openConnectionStream,
    required this.restClient,
    required this.graphQlClient,
    required this.push,
  });

  final AuthTokenService authTokenService;
  final SessionTerminator sessionTerminator;
  final Stream<bool> Function() openConnectionStream;
  final RestClient restClient;
  final ValueNotifier<GraphQLClient> graphQlClient;

  /// Porte push (abilitate o no-op) composte prima di runApp.
  final PushServices push;

  @override
  State<KlimmeckGuideApp> createState() => _KlimmeckGuideAppState();
}

class _KlimmeckGuideAppState extends State<KlimmeckGuideApp> {
  final AppLifecycleEventBus _lifecycleBus = AppLifecycleEventBus();
  late final KlimmeckRest rest;
  late final KlimmeckGraphQl graphQl = KlimmeckGraphQl(
    resolveClient: () => widget.graphQlClient.value,
  );
  final NotificationPreferencesStore notificationPreferencesStore =
      SharedPreferencesNotificationPreferencesStore();

  /// Registrazione push per tutta la vita del processo (D-07). Con il push disabilitato le
  /// porte no-op non producono token: mantiene solo lo specchio dell'utente attivo.
  late final PushRegistrationCoordinator _pushCoordinator =
      PushRegistrationCoordinator(
        authStates: widget.authTokenService.authStateStream,
        messaging: widget.push.messaging,
        repository: PushDeviceRepository(graphQl: graphQl),
        deviceIdentity: SharedPreferencesDeviceIdentityStore(),
        activeUser: SharedPreferencesActiveUserStore(),
        localNotifications: widget.push.localNotifications,
      );

  /// Tap in attesa sopra AuthGate: sopravvive a splash e sign-in (D-15).
  late final NotificationIntentCubit _notificationIntents =
      NotificationIntentCubit(widget.authTokenService.authStateStream);
  late final NotificationTapRouter _tapRouter = NotificationTapRouter(
    intents: _notificationIntents,
    links: const UrlLauncherLinkOpener(),
  );
  StreamSubscription<NotificationIntent>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    rest = KlimmeckRest(widget.restClient);
    _pushCoordinator.start();
    _tapSubscription = widget.push.localNotifications.taps.listen(
      _tapRouter.handle,
    );
    _routeLaunchTap(widget.push.launchIntent);
    loadSvg();
  }

  /// Tap che ha avviato l'app da killed (D-14): dopo il primo frame, quando esiste
  /// un'Activity per aprire Twitch; i tipi personali restano in attesa nel cubit
  /// fino a MainScreen.
  void _routeLaunchTap(NotificationIntent? intent) {
    if (intent == null) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tapRouter.handle(intent),
    );
  }

  @override
  void dispose() {
    unawaited(_tapSubscription?.cancel());
    unawaited(_notificationIntents.close());
    unawaited(_pushCoordinator.dispose());
    _lifecycleBus.close();
    super.dispose();
  }

  Future<void> loadSvg() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);

      final svgPaths = manifestMap.keys
          .where(
            (String key) =>
                key.startsWith('assets/icons/') && key.endsWith('.svg'),
          )
          .toList();

      await Future.wait(
        svgPaths.map((svgPath) async {
          final loader = SvgAssetLoader(svgPath);
          await svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        }),
      );
    } catch (e, stack) {
      debugPrint('Error during Svg loading: $e\n$stack');
    }
  }

  Future<void> preloadImages(BuildContext context) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final imagePaths = manifestMap.keys
          .where(
            (key) =>
                key.startsWith('assets/images/') &&
                (key.endsWith('.png') ||
                    key.endsWith('.jpg') ||
                    key.endsWith('.jpeg')),
          )
          .toList();

      await Future.wait(
        imagePaths.map((path) => precacheImage(AssetImage(path), context)),
      );

      debugPrint('Precached ${imagePaths.length} images');
    } catch (e, stack) {
      debugPrint('Error during image preloading: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleBridge(
      bus: _lifecycleBus,
      child: RepositoryProvider<AppLifecycleEvents>.value(
        value: _lifecycleBus,
        child: RepositoryProvider<AuthTokenService>(
          create: (_) => widget.authTokenService,
          dispose: (svc) => svc.dispose(),
          // Phase 7 lo usa alla prima conferma di viaggio; Phase 5 non chiede mai il permesso (D-10).
          child: RepositoryProvider<NotificationPermissionGate>(
            create: (_) => NotificationPermissionGate(widget.push.permission),
            child: RepositoryProvider<NotificationTapRouter>.value(
              value: _tapRouter,
              child: BlocProvider<NotificationIntentCubit>.value(
                value: _notificationIntents,
                child: BlocProvider<AuthCubit>(
                  lazy: false,
                  create: (_) => AuthCubit(
                    widget.authTokenService,
                    pushCleanup: _pushCoordinator,
                  )..start(),
                  child: BlocProvider<SplashCubit>(
                    create: (_) => SplashCubit(rest),
                    child: GraphQLProvider(
                      client: widget.graphQlClient,
                      child: AnnotatedRegion<SystemUiOverlayStyle>(
                        value: Platform.isIOS
                            ? SystemUiOverlayStyle.light
                            : const SystemUiOverlayStyle(
                                statusBarColor: Colors.transparent,
                                statusBarIconBrightness: Brightness.light,
                                systemNavigationBarIconBrightness:
                                    Brightness.dark,
                                systemNavigationBarColor: Colors.transparent,
                              ),
                        child: MaterialApp(
                          theme: KlimmeckGuideTheme.instance.materialTheme,
                          color: KlimmeckGuideTheme.deepNight,
                          debugShowCheckedModeBanner: false,
                          title: 'Guida di Klimmeck',
                          navigatorKey: navigatorKey,
                          home: Builder(
                            builder: (context) {
                              preloadImages(context);
                              return AuthGate(
                                // Lo scope copre anche la creazione personaggio: il watchdog
                                // e' di sessione (research Open Question 3, accettato).
                                authenticatedBuilder: (context, user) =>
                                    SessionSyncScope(
                                      graphQl: graphQl,
                                      terminator: widget.sessionTerminator,
                                      openConnectionStream:
                                          widget.openConnectionStream,
                                      child: SessionHome(
                                        user: user,
                                        creationBuilder: (context) =>
                                            BlocProvider<
                                              CharacterCreationCubit
                                            >(
                                              create: (_) => CharacterCreationCubit(
                                                CharacterCreationRepository(
                                                  graphQl: graphQl,
                                                  rest: rest,
                                                  picker:
                                                      ImagePickerPortraitPicker(),
                                                ),
                                              )..loadRaceTraits(),
                                              child:
                                                  const CharacterCreationScreen(),
                                            ),
                                        shellBuilder: (context, characterId) =>
                                            AuthenticatedShell(
                                              graphQl: graphQl,
                                              characterId: characterId,
                                              notificationPreferencesStore:
                                                  notificationPreferencesStore,
                                              userId: user.id,
                                              notificationPermission:
                                                  widget.push.permission,
                                              pushMessaging:
                                                  widget.push.messaging,
                                            ),
                                      ),
                                    ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
