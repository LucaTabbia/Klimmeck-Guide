import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/quest_result/quest_end_event.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_intent_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/main_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fakes/fake_pending_quest_results.dart';
import '../../helpers/fakes/recording_quest_result_acknowledger.dart';
import '../../helpers/fixtures/quest_fixtures.dart';
import '../../helpers/fixtures/quest_result_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

final List<City> _cities = [
  City.fromJson({
    'id': 'city-1',
    'markerLocation': {
      'id': 'city-marker-1',
      'location': [1.0, 2.0],
    },
  }),
];

QuestResult _success(String id) => questResult(successResultJson(id: id));

/// `MainScreen` con la coda dei risultati e la disponibilità della mappa
/// reali (Phase 9 D-06..D-13): le pagine sono stub, porte e bus sono fake.
class _MainScreenHarness {
  _MainScreenHarness() {
    when(() => repository.watch(any())).thenAnswer((_) => live.stream);
    when(() => character.loadCharacter(any())).thenAnswer((_) async {});
    when(() => quests.loadQuest()).thenAnswer((_) async {});
    whenListen(
      quests,
      const Stream<QuestState>.empty(),
      initialState: QuestInitial(),
    );
    whenListen(
      acceptance,
      const Stream<QuestAcceptanceState>.empty(),
      initialState: const QuestAcceptanceIdle(),
    );
    whenListen(
      travel,
      const Stream<TravelState>.empty(),
      initialState: const TravelIdle(),
    );
    whenListen(
      spells,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    whenListen(
      preferences,
      const Stream<NotificationPreferencesState>.empty(),
      initialState: NotificationPreferencesState(),
    );
    whenListen(
      transactions,
      const Stream<TransactionState>.empty(),
      initialState: TransactionInitial(),
    );
    whenListen(
      teleport,
      const Stream<TeleportModeState>.empty(),
      initialState: const TeleportIdle(),
    );
    when(() => teleport.cancel()).thenReturn(null);
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUser(role: RoleType.innkeeper),
        accessToken: testAccessToken,
      ),
    );
  }

  final MockQuestResultRepository repository = MockQuestResultRepository();
  final StreamController<QuestResult> live =
      StreamController<QuestResult>.broadcast();
  final StreamController<MainScreenState> screenStates =
      StreamController<MainScreenState>.broadcast();
  final StreamController<AuthState> authStates =
      StreamController<AuthState>.broadcast();
  final FakePendingQuestResults pending = FakePendingQuestResults();
  final RecordingQuestResultAcknowledger acknowledger =
      RecordingQuestResultAcknowledger();
  final AppLifecycleEventBus lifecycle = AppLifecycleEventBus();
  final ConnectionRestoredBus connectionRestored = ConnectionRestoredBus();
  final UserRefreshRequestBus refreshBus = UserRefreshRequestBus();
  final MapAvailabilityCubit availability = MapAvailabilityCubit();
  final MockCharacterCubit character = MockCharacterCubit();
  final MockQuestCubit quests = MockQuestCubit();
  final MockMainScreenCubit mainScreen = MockMainScreenCubit();
  final MockQuestAcceptanceCubit acceptance = MockQuestAcceptanceCubit();
  final MockInAppNotificationsCubit notices = MockInAppNotificationsCubit();
  final MockTravelCubit travel = MockTravelCubit();
  final MockSpellsCubit spells = MockSpellsCubit();
  final MockTransactionCubit transactions = MockTransactionCubit();
  final MockNotificationPreferencesCubit preferences =
      MockNotificationPreferencesCubit();
  final MockTeleportModeCubit teleport = MockTeleportModeCubit();
  final MockAuthCubit auth = MockAuthCubit();

  /// Creati al primo uso dentro il test: la coda delle conferme nasce nella
  /// zona fake del tester, non in quella reale di `setUp`.
  late final NotificationIntentCubit intents = NotificationIntentCubit(
    authStates.stream,
  );
  late final QuestResultsCubit results = QuestResultsCubit(
    characterId: 'c-1',
    repository: repository,
    pending: pending,
    acknowledger: acknowledger,
    lifecycle: lifecycle,
    connectionRestored: connectionRestored,
    userRefresh: refreshBus,
  );

  /// Come la shell: la coda parte con la sessione, prima del MainScreen.
  Future<void> pump(
    WidgetTester tester, {
    required CharacterState characterState,
    required MainScreenState screenState,
  }) async {
    useLandscapePhone(tester);
    whenListen(
      character,
      const Stream<CharacterState>.empty(),
      initialState: characterState,
    );
    whenListen(mainScreen, screenStates.stream, initialState: screenState);
    results.start();
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: character),
            BlocProvider<QuestCubit>.value(value: quests),
            BlocProvider<MainScreenCubit>.value(value: mainScreen),
            BlocProvider<NotificationIntentCubit>.value(value: intents),
            BlocProvider<QuestAcceptanceCubit>.value(value: acceptance),
            BlocProvider<InAppNotificationsCubit>.value(value: notices),
            BlocProvider<TravelCubit>.value(value: travel),
            BlocProvider<SpellsCubit>.value(value: spells),
            BlocProvider<TransactionCubit>.value(value: transactions),
            BlocProvider<MapAvailabilityCubit>.value(value: availability),
            BlocProvider<QuestResultsCubit>.value(value: results),
            BlocProvider<NotificationPreferencesCubit>.value(
              value: preferences,
            ),
            BlocProvider<TeleportModeCubit>.value(value: teleport),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: MainScreen(
            characterId: 'c-1',
            pagesBuilder: (_) => [
              for (final entry in SatchelLayout.entries)
                SizedBox.expand(key: ValueKey('page-${entry.pageIndex}')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> loadPages(WidgetTester tester) async {
    screenStates.add(MainScreenLoadData(_cities));
    await tester.pumpAndSettle();
  }

  Future<void> arrive(WidgetTester tester, QuestResult result) async {
    live.add(result);
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    await results.close();
    await intents.close();
    await availability.close();
    await Future.wait([
      live.close(),
      screenStates.close(),
      authStates.close(),
      lifecycle.close(),
      connectionRestored.close(),
      refreshBus.close(),
    ]);
  }
}

final Character _aldo = Character.fromJson(
  characterWithLanesJson(locationId: 'city-marker-1'),
);

final Finder _sheet = find.byType(QuestResultSheet);

Future<void> _pressContinue(WidgetTester tester) async {
  await tester.tap(find.byKey(QuestResultSheet.continueKey));
  await tester.pumpAndSettle();
}

Future<void> _openSatchelAndTap(WidgetTester tester, int pageIndex) async {
  await tester.tap(find.byType(CachedSvg).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tapAt(
    SatchelLayout.centerOf(
      SatchelLayout.entries[pageIndex],
      const Size(780, 360),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MainScreenHarness h;

  setUpAll(() {
    registerFallbackValue(questEndEventOf(_success('fallback')));
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    seedSvgCache([
      for (final entry in SatchelLayout.entries) entry.assetPath,
      CloudinaryAssets.pouch,
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.helmetType,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]);
    h = _MainScreenHarness();
  });

  tearDown(() => h.dispose());

  group('MainScreen quest results (Phase 9 D-06, D-07, D-13)', () {
    testWidgets('a pending result opens when the map page is shown', (
      tester,
    ) async {
      h.pending.results = [_success('result-1')];
      await h.pump(
        tester,
        characterState: CharacterLoaded(_aldo),
        screenState: MainScreenInitial(),
      );

      expect(find.byType(KGLoader), findsOneWidget);
      expect(_sheet, findsNothing);

      await h.loadPages(tester);

      expect(_sheet, findsOneWidget);

      await _pressContinue(tester);

      expect(_sheet, findsNothing);
      expect(h.acknowledger.acknowledged, ['result-1']);
    });

    testWidgets('a live result on another tab waits for the map', (
      tester,
    ) async {
      final result = _success('result-2');
      await h.pump(
        tester,
        characterState: CharacterLoaded(_aldo),
        screenState: MainScreenLoadData(_cities),
      );
      await _openSatchelAndTap(tester, 1);
      expect(h.availability.state.isMapPage, isFalse);

      await h.arrive(tester, result);

      expect(_sheet, findsNothing);
      verify(() => h.notices.publish(questEndEventOf(result))).called(1);

      await _openSatchelAndTap(
        tester,
        NotificationIntentLanding.worldMapPageIndex,
      );

      expect(h.availability.state.isMapPage, isTrue);
      expect(_sheet, findsOneWidget);
    });

    testWidgets('a dead current character gets its death sheet over the '
        'loader', (tester) async {
      h.pending.results = [questResult(deathResultJson())];
      await h.pump(
        tester,
        characterState: const CharacterUnavailable(),
        screenState: MainScreenInitial(),
      );

      expect(find.byType(KGLoader), findsOneWidget);
      expect(_sheet, findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.headerKey)).data,
        'È morto',
      );

      await _pressContinue(tester);

      expect(h.acknowledger.acknowledged, ['result-death']);
      expect(_sheet, findsNothing);
      expect(find.byType(KGLoader), findsOneWidget);
    });
  });
}
