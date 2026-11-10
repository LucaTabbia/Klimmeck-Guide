import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_gate.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/auth_gate.dart';
import 'package:klimmeck_guide/screens/auth/authenticated_shell.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/auth/session_home.dart';
import 'package:klimmeck_guide/screens/auth/session_sync_scope.dart';
import 'package:klimmeck_guide/screens/auth/syncCubit/session_sync_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/repository/storage/cubit/storage_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fakes/fake_notification_permission_port.dart';
import '../../helpers/fakes/fake_push_messaging_port.dart';
import '../../helpers/fakes/in_memory_library_bookmarks_store.dart';
import '../../helpers/fakes/in_memory_notification_preferences_store.dart';
import '../../helpers/fakes/recording_link_opener.dart';
import '../../helpers/fakes/recording_notification_intent_sink.dart';
import '../../helpers/fixtures/sync_event_fixtures.dart';
import '../../helpers/leak_tracking_bloc_observer.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

class _ProbeCubit extends Cubit<int> {
  _ProbeCubit() : super(0);
}

class _RecordingLeakObserver extends LeakTrackingBlocObserver {
  int creates = 0;
  int closes = 0;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    creates++;
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    closes++;
  }
}

/// Legge ogni cubit e servizio della shell e ne tiene solo riferimenti deboli
/// (Pitfall 6); avvia lo stream del personaggio come fa il MainScreen.
class _ShellProbe extends StatefulWidget {
  const _ShellProbe({required this.characterId, required this.references});

  final String characterId;
  final List<WeakReference<Object>> references;

  @override
  State<_ShellProbe> createState() => _ShellProbeState();
}

class _ShellProbeState extends State<_ShellProbe> {
  @override
  void initState() {
    super.initState();
    widget.references.addAll(
      _sessionObjects(context).map(WeakReference<Object>.new),
    );
    context.read<CharacterCubit>().loadCharacter(widget.characterId);
  }

  static List<Object> _sessionObjects(BuildContext context) => [
    context.read<SessionSyncCubit>(),
    context.read<StorageCubit>(),
    context.read<CharacterCubit>(),
    context.read<QuestCubit>(),
    context.read<TransactionCubit>(),
    context.read<MainScreenCubit>(),
    context.read<WorldMapCubit>(),
    context.read<ShopCubit>(),
    context.read<LibraryCubit>(),
    context.read<JournalCubit>(),
    context.read<NotificationPreferencesCubit>(),
    context.read<NotificationPermissionCubit>(),
    context.read<InAppNotificationsCubit>(),
    context.read<CharacterDeletionCubit>(),
    context.read<QuestAcceptanceCubit>(),
    context.read<QuestAbandonCubit>(),
    context.read<MapFocusCubit>(),
    context.read<MapAvailabilityCubit>(),
    context.read<QuestResultsCubit>(),
    context.read<TeleportModeCubit>(),
    context.read<TravelCubit>(),
    context.read<SpellsCubit>(),
    context.read<CompanionCubit>(),
    context.read<PotionCubit>(),
    context.read<ServerClockService>(),
  ];

  @override
  Widget build(BuildContext context) => Text('main ${widget.characterId}');
}

/// I font Google non sono negli asset: il loro caricamento fallisce appena il
/// test lascia girare l'event loop reale (`tester.runAsync` di `forceGC`).
/// Il tema si costruisce qui una volta sola e i fallimenti restano fuori dai
/// test.
Future<void> _settleThemeFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final settled = Completer<void>();
  runZonedGuarded(() async {
    KlimmeckGuideTheme.instance;
    await GoogleFonts.pendingFonts().catchError((Object _) => const []);
    settled.complete();
  }, (_, _) {});
  await settled.future;
}

/// Il logo `Image.asset` del sign-in può restare in caricamento nella cache
/// immagini di processo a fine test: la sua `ImageStreamCompleterHandle` è
/// del framework, non della sessione.
LeakTesting _shellLeakTesting() => LeakTesting.settings
    .withTrackedAll()
    .withIgnored(classes: ['ImageStreamCompleterHandle']);

List<Type> _retainedTypes(List<WeakReference<Object>> references) => [
  for (final reference in references)
    if (reference.target case final target?) target.runtimeType,
];

void main() {
  LeakTesting.enable();

  setUpAll(_settleThemeFonts);

  late BlocObserver previousObserver;

  setUp(() {
    previousObserver = Bloc.observer;
    Bloc.observer = const LeakTrackingBlocObserver();
  });

  tearDown(() => Bloc.observer = previousObserver);

  group('LeakTrackingBlocObserver', () {
    late PhaseSettings previousPhase;
    late bool startedHere;

    setUp(() {
      startedHere = !LeakTracking.isStarted;
      if (startedHere) {
        LeakTracking.start(config: LeakTrackingConfig.passive());
      }
      previousPhase = LeakTracking.phase;
      LeakTracking.phase = const PhaseSettings(name: 'observer self-check');
    });

    tearDown(() {
      LeakTracking.phase = previousPhase;
      if (startedHere) LeakTracking.stop();
    });

    test(
      'the observer dispatches one create and one close per cubit (D-05)',
      () async {
        final observer = _RecordingLeakObserver();
        Bloc.observer = observer;

        await _ProbeCubit().close();
        LeakTracking.declareNotDisposedObjectsAsLeaks();
        final leaks = await LeakTracking.collectLeaks();

        expect(observer.creates, 1);
        expect(observer.closes, 1);
        expect(leaks.notDisposed, isEmpty);
      },
    );

    test('an unclosed cubit is reported as notDisposed (D-05)', () async {
      final cubit = _ProbeCubit();

      LeakTracking.declareNotDisposedObjectsAsLeaks();
      final leaks = await LeakTracking.collectLeaks();
      await cubit.close();

      expect(leaks.notDisposed, hasLength(1));
      expect(leaks.notDisposed.single.type, contains('_ProbeCubit'));
    });
  });

  group('authenticated shell logout', () {
    late MockAuthCubit authCubit;
    late StreamController<AuthState> authStates;
    late MockAuthTokenService authService;
    late MockSessionTerminator terminator;
    late MockSplashCubit splashCubit;
    late MockKlimmeckGraphQl graphQl;
    late AppLifecycleEventBus lifecycle;
    late FakePushMessagingPort messaging;
    late StreamController<User> userUpdates;
    late StreamController<bool> connection;
    late StreamController<Character> characterUpdates;
    late StreamController<QuestResult> questResults;
    late List<WeakReference<Object>> references;

    setUpAll(() {
      registerFallbackValue(buildTestUser());
      registerFallbackValue(UnauthenticatedReason.syncLost);
    });

    setUp(() {
      references = [];
      authStates = StreamController<AuthState>.broadcast();
      authCubit = MockAuthCubit();
      whenListen(
        authCubit,
        authStates.stream,
        initialState: AuthAuthenticated(
          user: buildTestUserWithCharacter(),
          accessToken: testAccessToken,
        ),
      );
      authService = MockAuthTokenService();
      when(() => authService.adoptUser(any())).thenReturn(true);
      terminator = MockSessionTerminator();
      when(() => terminator.terminateSession(any())).thenAnswer((_) async {});
      splashCubit = MockSplashCubit();
      whenListen(
        splashCubit,
        const Stream<SplashState>.empty(),
        initialState: const SplashData(),
      );
      when(() => splashCubit.getImages(any())).thenAnswer((_) async {});
      lifecycle = AppLifecycleEventBus();
      messaging = FakePushMessagingPort();
      userUpdates = StreamController<User>.broadcast();
      connection = StreamController<bool>.broadcast();
      characterUpdates = StreamController<Character>.broadcast();
      questResults = StreamController<QuestResult>.broadcast();
      graphQl = MockKlimmeckGraphQl();
      when(
        () => graphQl.subscribeToUser(),
      ).thenAnswer((_) => userUpdates.stream);
      when(() => graphQl.getMe()).thenAnswer((_) async => buildTestUser());
      when(() => graphQl.getCharacter(testCharacterId)).thenAnswer(
        (_) async => Character.fromJson(characterJson(id: testCharacterId)),
      );
      when(
        () => graphQl.subscribeToCharacter(testCharacterId),
      ).thenAnswer((_) => characterUpdates.stream);
      when(
        () => graphQl.subscribeToQuestResults(any()),
      ).thenAnswer((_) => questResults.stream);
      when(
        () => graphQl.getUnacknowledgedQuestResults(),
      ).thenAnswer((_) async => const []);
      when(
        () => graphQl.getServerTime(),
      ).thenAnswer((_) async => DateTime.utc(2026, 11, 9, 10));
    });

    tearDown(() async {
      // Il logo del sign-in resta nella cache immagini di processo (non di
      // sessione): svuotarla qui ne chiude gli oggetti prima del report.
      imageCache
        ..clear()
        ..clearLiveImages();
      await authStates.close();
      await messaging.close();
      await lifecycle.close();
      await userUpdates.close();
      await connection.close();
      await characterUpdates.close();
      await questResults.close();
    });

    Widget shellFor(BuildContext context, User user) => SessionSyncScope(
      graphQl: graphQl,
      terminator: terminator,
      openConnectionStream: () => connection.stream,
      child: SessionHome(
        user: user,
        creationBuilder: (_) => const Text('creation'),
        shellBuilder: (context, characterId) => AuthenticatedShell(
          graphQl: graphQl,
          characterId: characterId,
          notificationPreferencesStore: InMemoryNotificationPreferencesStore(),
          libraryBookmarksStore: InMemoryLibraryBookmarksStore(),
          userId: user.id,
          notificationPermission: FakeNotificationPermissionPort(
            current: NotificationPermissionStatus.granted,
          ),
          pushMessaging: messaging,
          mainScreenBuilder: (context, id) =>
              _ShellProbe(characterId: id, references: references),
        ),
      ),
    );

    Future<void> pumpSession(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthTokenService>.value(value: authService),
            RepositoryProvider<AppLifecycleEvents>.value(value: lifecycle),
            RepositoryProvider<NotificationTapRouter>.value(
              value: NotificationTapRouter(
                intents: RecordingNotificationIntentSink(),
                links: RecordingLinkOpener(),
              ),
            ),
            RepositoryProvider<NotificationPermissionGate>.value(
              value: NotificationPermissionGate(
                FakeNotificationPermissionPort(),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<SplashCubit>.value(value: splashCubit),
            ],
            child: buildTestApp(home: AuthGate(authenticatedBuilder: shellFor)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<void> logOut(WidgetTester tester) async {
      authStates.add(const AuthUnauthenticated());
      await tester.pumpAndSettle();
    }

    List<StreamController<Object?>> liveControllers() => [
      userUpdates,
      connection,
      characterUpdates,
      questResults,
      messaging.foreground,
    ];

    testWidgets(
      'logout leaves no cubit undisposed or reachable (D-05)',
      experimentalLeakTesting: _shellLeakTesting(),
      (tester) async {
        await pumpSession(tester);
        expect(find.text('main $testCharacterId'), findsOneWidget);
        expect(references, hasLength(24));

        await logOut(tester);

        expect(
          references.every(
            (reference) => switch (reference.target) {
              final BlocBase<dynamic> bloc => bloc.isClosed,
              _ => true,
            },
          ),
          isTrue,
        );
        // Le dismissioni asincrone (es. `ServerClockService.dispose`) finiscono
        // solo con l'event loop reale: prima del GC si lasciano concludere.
        await tester.runAsync(pumpEventQueue);
        await tester.runAsync(
          () => forceGC(fullGcCycles: 3, timeout: const Duration(seconds: 10)),
        );
        expect(_retainedTypes(references), isEmpty);
      },
    );

    testWidgets(
      'logout cancels every live subscription of the shell (D-05)',
      experimentalLeakTesting: _shellLeakTesting(),
      (tester) async {
        await pumpSession(tester);
        expect(
          liveControllers().map((controller) => controller.hasListener),
          everyElement(isTrue),
        );

        await logOut(tester);

        expect(
          liveControllers().map((controller) => controller.hasListener),
          everyElement(isFalse),
        );
      },
    );

    testWidgets(
      'logout shows the sign-in screen (D-05)',
      experimentalLeakTesting: _shellLeakTesting(),
      (tester) async {
        await pumpSession(tester);

        await logOut(tester);

        expect(find.byType(SignInScreen), findsOneWidget);
        expect(find.byType(AuthenticatedShell), findsNothing);
      },
    );
  });
}
