import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/authenticated_shell.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:klimmeck_guide/shared/components/kg_notification_banner.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fakes/fake_notification_permission_port.dart';
import '../../helpers/fakes/fake_push_messaging_port.dart';
import '../../helpers/fakes/in_memory_notification_preferences_store.dart';
import '../../helpers/fakes/recording_link_opener.dart';
import '../../helpers/fakes/recording_notification_intent_sink.dart';
import '../../helpers/fakes/recording_sync_health.dart';
import '../../helpers/fixtures/sync_event_fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockSplashCubit splashCubit;
  late RecordingSyncHealth health;
  late AppLifecycleEventBus lifecycle;
  late UserRefreshRequestBus refreshBus;
  late MockKlimmeckGraphQl graphQl;
  late InMemoryNotificationPreferencesStore store;
  late MockAuthCubit authCubit;
  late FakeNotificationPermissionPort permission;
  late FakePushMessagingPort messaging;
  late RecordingNotificationIntentSink sink;
  late RecordingLinkOpener links;

  setUpAll(() => registerFallbackValue(buildTestUser()));

  setUp(() {
    store = InMemoryNotificationPreferencesStore();
    permission = FakeNotificationPermissionPort(
      current: NotificationPermissionStatus.denied,
    );
    messaging = FakePushMessagingPort();
    sink = RecordingNotificationIntentSink();
    links = RecordingLinkOpener();
    authCubit = MockAuthCubit();
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUserWithCharacter(),
        accessToken: testAccessToken,
      ),
    );
    health = RecordingSyncHealth();
    lifecycle = AppLifecycleEventBus();
    refreshBus = UserRefreshRequestBus();
    graphQl = MockKlimmeckGraphQl();
    splashCubit = MockSplashCubit();
    when(() => splashCubit.getImages(any())).thenAnswer((_) async {});
    when(() => splashCubit.startBootstrapWatch()).thenReturn(null);
    when(() => splashCubit.stopBootstrapWatch()).thenReturn(null);
  });

  tearDown(() => messaging.close());

  Future<void> pumpShell(
    WidgetTester tester, {
    required SplashState state,
    Widget Function(BuildContext, String)? mainScreenBuilder,
  }) async {
    whenListen(
      splashCubit,
      const Stream<SplashState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SyncHealth>.value(value: health),
            RepositoryProvider<AppLifecycleEvents>.value(value: lifecycle),
            RepositoryProvider<UserRefreshRequests>.value(value: refreshBus),
            RepositoryProvider<NotificationTapRouter>.value(
              value: NotificationTapRouter(intents: sink, links: links),
            ),
          ],
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: BlocProvider<SplashCubit>.value(
              value: splashCubit,
              child: AuthenticatedShell(
                graphQl: graphQl,
                characterId: testCharacterId,
                notificationPreferencesStore: store,
                userId: testUserId,
                notificationPermission: permission,
                pushMessaging: messaging,
                mainScreenBuilder:
                    mainScreenBuilder ?? (_, id) => Text('main $id'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('preloads images once and shows the splash while loading', (
    tester,
  ) async {
    await pumpShell(tester, state: const SplashInitial());

    verify(() => splashCubit.getImages('main')).called(1);
    final splash = tester.widget<SplashScreen>(find.byType(SplashScreen));
    expect(splash.watchConnection, isFalse);
    expect(find.text('main $testCharacterId'), findsNothing);
    verifyNever(() => splashCubit.startBootstrapWatch());
  });

  testWidgets('enters the main screen once images are ready', (tester) async {
    await pumpShell(tester, state: const SplashData());

    expect(find.text('main $testCharacterId'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('a failed preload does not block the main screen', (
    tester,
  ) async {
    await pumpShell(tester, state: const SplashError('offline'));

    expect(find.text('main $testCharacterId'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('provides the gameplay cubits and closes them on removal', (
    tester,
  ) async {
    late CharacterCubit characterCubit;
    late QuestCubit questCubit;
    await pumpShell(
      tester,
      state: const SplashData(),
      mainScreenBuilder: (context, _) {
        characterCubit = context.read<CharacterCubit>();
        questCubit = context.read<QuestCubit>();
        return const Text('main');
      },
    );

    expect(characterCubit.isClosed, isFalse);

    await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

    expect(characterCubit.isClosed, isTrue);
    expect(questCubit.isClosed, isTrue);
  });

  testWidgets('provides the notification preferences loaded for the user', (
    tester,
  ) async {
    store.values[InMemoryNotificationPreferencesStore.keyOf(
          testUserId,
          NotificationCategory.travelEnd,
        )] =
        false;
    late NotificationPreferencesCubit cubit;
    await pumpShell(
      tester,
      state: const SplashData(),
      mainScreenBuilder: (context, _) {
        cubit = context.read<NotificationPreferencesCubit>();
        return const Text('main');
      },
    );
    await tester.pump();

    expect(store.reads, greaterThanOrEqualTo(1));
    expect(cubit.state.isLoaded, isTrue);
    expect(cubit.state.isEnabled(NotificationCategory.travelEnd), isFalse);
  });

  testWidgets('closes the settings cubits on removal and keeps the store', (
    tester,
  ) async {
    late NotificationPreferencesCubit preferences;
    late CharacterDeletionCubit deletion;
    final key = InMemoryNotificationPreferencesStore.keyOf(
      testUserId,
      NotificationCategory.questEnd,
    );
    store.values[key] = false;
    await pumpShell(
      tester,
      state: const SplashData(),
      mainScreenBuilder: (context, _) {
        preferences = context.read<NotificationPreferencesCubit>();
        deletion = context.read<CharacterDeletionCubit>();
        return const Text('main');
      },
    );
    expect(preferences.isClosed, isFalse);
    expect(deletion.isClosed, isFalse);

    await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

    expect(preferences.isClosed, isTrue);
    expect(deletion.isClosed, isTrue);
    expect(store.values[key], isFalse);
  });

  testWidgets('provides the system permission status read once at mount', (
    tester,
  ) async {
    late NotificationPermissionCubit cubit;
    await pumpShell(
      tester,
      state: const SplashData(),
      mainScreenBuilder: (context, _) {
        cubit = context.read<NotificationPermissionCubit>();
        return const Text('main');
      },
    );
    await tester.pump();

    expect(permission.statusCalls, 1);
    expect(cubit.state.status, NotificationPermissionStatus.denied);
    expect(permission.requestCalls, 0);

    await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

    expect(cubit.isClosed, isTrue);
  });

  group('in-app notifications', () {
    const travelEndData = <String, String>{
      'type': 'travelEnd',
      'title': 'Viaggio completato',
      'body': 'Il tuo personaggio è arrivato a destinazione.',
      'sentAt': '2026-10-18T12:00:00.000Z',
      'id': '6712a0c4e1b2c3d4e5f60718',
    };
    const streamerLiveData = <String, String>{
      'type': 'streamerLive',
      'title': 'Lo streamer è in live',
      'body': 'Unisciti alla diretta.',
      'sentAt': '2026-10-18T12:00:42.123Z',
    };

    Future<void> deliver(WidgetTester tester, Map<String, String> data) async {
      messaging.foreground.add(data);
      await tester.pump();
      await tester.pump();
    }

    Future<void> outlastBanner(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows a foreground push over the game and hides it', (
      tester,
    ) async {
      await pumpShell(tester, state: const SplashData());

      await deliver(tester, travelEndData);

      expect(find.text('Viaggio completato'), findsOneWidget);
      expect(find.text('main $testCharacterId'), findsOneWidget);

      await outlastBanner(tester);

      expect(find.byType(KgNotificationBanner), findsNothing);
    });

    testWidgets('shows nothing when the user disabled the category', (
      tester,
    ) async {
      store.values[InMemoryNotificationPreferencesStore.keyOf(
            testUserId,
            NotificationCategory.travelEnd,
          )] =
          false;
      await pumpShell(tester, state: const SplashData());

      await deliver(tester, travelEndData);

      expect(find.byType(KgNotificationBanner), findsNothing);
    });

    testWidgets('tapping a personal banner lands on the map and hides it', (
      tester,
    ) async {
      await pumpShell(tester, state: const SplashData());
      await deliver(tester, travelEndData);

      await tester.tap(find.byType(KgNotificationBanner));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sink.offered.single.category, NotificationCategory.travelEnd);
      expect(links.opened, isEmpty);
      expect(find.byType(KgNotificationBanner), findsNothing);
    });

    testWidgets('tapping a streamerLive banner opens Twitch', (tester) async {
      await pumpShell(tester, state: const SplashData());
      await deliver(tester, streamerLiveData);

      await tester.tap(find.byType(KgNotificationBanner));
      await tester.pump();

      expect(
        links.opened.single,
        Uri.parse('https://www.twitch.tv/lordreavor'),
      );
      expect(sink.offered, isEmpty);
    });

    testWidgets('the same push twice shows a single banner', (tester) async {
      await pumpShell(tester, state: const SplashData());

      await deliver(tester, travelEndData);
      await deliver(tester, travelEndData);
      expect(find.byType(KgNotificationBanner), findsOneWidget);

      await outlastBanner(tester);

      expect(find.byType(KgNotificationBanner), findsNothing);
    });

    testWidgets('mounts the banner in a top safe area above the game', (
      tester,
    ) async {
      await pumpShell(tester, state: const SplashData());
      await deliver(tester, travelEndData);

      final banner = find.byType(KgNotificationBanner);
      expect(
        find.ancestor(of: banner, matching: find.byType(SafeArea)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: banner, matching: find.byType(Stack)),
        findsWidgets,
      );
      expect(find.byType(SnackBar), findsNothing);
      await outlastBanner(tester);
    });

    testWidgets('closes the in-app notifications cubit on removal', (
      tester,
    ) async {
      late InAppNotificationsCubit cubit;
      await pumpShell(
        tester,
        state: const SplashData(),
        mainScreenBuilder: (context, _) {
          cubit = context.read<InAppNotificationsCubit>();
          return const Text('main');
        },
      );
      expect(cubit.isClosed, isFalse);

      await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

      expect(cubit.isClosed, isTrue);
    });
  });

  group('character deletion hand-over', () {
    late CharacterDeletionCubit deletion;

    Future<void> pumpAndDelete(WidgetTester tester) async {
      await pumpShell(
        tester,
        state: const SplashData(),
        mainScreenBuilder: (context, _) {
          deletion = context.read<CharacterDeletionCubit>();
          return const Text('main');
        },
      );
      await deletion.deleteCharacter();
      await tester.pump();
    }

    setUp(() {
      when(
        () => graphQl.deleteCharacter(),
      ).thenAnswer((_) async => buildTestUser());
    });

    testWidgets('hands the deleted user to the auth cubit once', (
      tester,
    ) async {
      when(() => authCubit.adoptUser(any())).thenReturn(true);

      await pumpAndDelete(tester);

      verify(() => authCubit.adoptUser(buildTestUser())).called(1);
    });

    testWidgets('a refused hand-over surfaces handoverRejected', (
      tester,
    ) async {
      when(() => authCubit.adoptUser(any())).thenReturn(false);

      await pumpAndDelete(tester);

      verify(() => authCubit.adoptUser(buildTestUser())).called(1);
      expect(
        deletion.state,
        const CharacterDeletionState(
          failure: CharacterDeletionFailure.handoverRejected,
        ),
      );
    });
  });

  group('character sync through the shell', () {
    late StreamController<Character> updates;

    setUp(() {
      updates = StreamController<Character>(sync: true);
      when(() => graphQl.getCharacter(testCharacterId)).thenAnswer(
        (_) async => Character.fromJson(
          characterJson(id: testCharacterId, currentLifePoints: 7),
        ),
      );
      when(
        () => graphQl.subscribeToCharacter(testCharacterId),
      ).thenAnswer((_) => updates.stream);
    });

    tearDown(() => updates.close());

    Widget hpBuilder(BuildContext context, String id) =>
        _CharacterLoader(characterId: id);

    testWidgets('a pushed event updates the status on screen (SYNC-07)', (
      tester,
    ) async {
      await pumpShell(
        tester,
        state: const SplashData(),
        mainScreenBuilder: hpBuilder,
      );
      await tester.pump();
      expect(find.text('hp 7'), findsOneWidget);

      updates.add(
        Character.fromJson(
          characterJson(id: testCharacterId, currentLifePoints: 3),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('hp 3'), findsOneWidget);
    });

    testWidgets('removing the shell releases the character stream', (
      tester,
    ) async {
      await pumpShell(
        tester,
        state: const SplashData(),
        mainScreenBuilder: hpBuilder,
      );
      await tester.pump();
      expect(updates.hasListener, isTrue);

      await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

      expect(updates.hasListener, isFalse);
      expect(health.calls, contains('released:characterStream'));
    });
  });
}

class _CharacterLoader extends StatefulWidget {
  const _CharacterLoader({required this.characterId});

  final String characterId;

  @override
  State<_CharacterLoader> createState() => _CharacterLoaderState();
}

class _CharacterLoaderState extends State<_CharacterLoader> {
  @override
  void initState() {
    super.initState();
    context.read<CharacterCubit>().loadCharacter(widget.characterId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CharacterCubit, CharacterState, int?>(
      selector: (state) => state is CharacterLoaded
          ? state.character.status?.currentLifePoints
          : null,
      builder: (_, hp) => Text('hp $hp'),
    );
  }
}
