import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_background.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_intent_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/party_watch_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_menu.dart';
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
import 'package:klimmeck_guide/shared/components/kg_error.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fixtures/quest_fixtures.dart';
import '../../helpers/fixtures/travel_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockQuestCubit questCubit;
  late MockMainScreenCubit mainScreenCubit;
  late MockQuestResultsCubit questResultsCubit;
  late MockNotificationPreferencesCubit preferencesCubit;
  late MockTeleportModeCubit teleportCubit;
  late StreamController<TeleportModeState> teleportStates;
  late MockAuthCubit authCubit;

  setUp(() {
    teleportCubit = MockTeleportModeCubit();
    teleportStates = StreamController<TeleportModeState>.broadcast();
    addTearDown(teleportStates.close);
    whenListen(
      teleportCubit,
      teleportStates.stream,
      initialState: const TeleportIdle(),
    );
    when(() => teleportCubit.cancel()).thenReturn(null);
    authCubit = MockAuthCubit();
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUser(role: RoleType.innkeeper),
        accessToken: testAccessToken,
      ),
    );
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
    mainScreenCubit = MockMainScreenCubit();
    questResultsCubit = MockQuestResultsCubit();
    preferencesCubit = MockNotificationPreferencesCubit();
    whenListen(
      questResultsCubit,
      const Stream<QuestResultsState>.empty(),
      initialState: const QuestResultsState(),
    );
    whenListen(
      preferencesCubit,
      const Stream<NotificationPreferencesState>.empty(),
      initialState: NotificationPreferencesState(),
    );
    whenListen(
      characterCubit,
      Stream<CharacterState>.empty(),
      initialState: CharacterInitial(),
    );
    whenListen(
      questCubit,
      Stream<QuestState>.empty(),
      initialState: QuestInitial(),
    );
    whenListen(
      mainScreenCubit,
      Stream<MainScreenState>.empty(),
      initialState: MainScreenInitial(),
    );
    when(() => characterCubit.loadCharacter(any())).thenAnswer((_) async {});
    when(() => questCubit.loadQuest()).thenAnswer((_) async {});
  });

  testWidgets('loads exactly the character of the session', (tester) async {
    final availability = MapAvailabilityCubit();
    addTearDown(availability.close);
    final travelCubit = MockTravelCubit();
    whenListen(
      travelCubit,
      const Stream<TravelState>.empty(),
      initialState: const TravelIdle(),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
            BlocProvider<MapAvailabilityCubit>.value(value: availability),
            BlocProvider<TravelCubit>.value(value: travelCubit),
            BlocProvider<InAppNotificationsCubit>.value(
              value: MockInAppNotificationsCubit(),
            ),
            BlocProvider<QuestResultsCubit>.value(value: questResultsCubit),
            BlocProvider<NotificationPreferencesCubit>.value(
              value: preferencesCubit,
            ),
            BlocProvider<TeleportModeCubit>.value(value: teleportCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const MainScreen(characterId: 'c-42'),
        ),
      ),
    );
    await tester.pump();

    verify(() => characterCubit.loadCharacter('c-42')).called(1);
    verify(() => questCubit.loadQuest()).called(1);
  });

  group('unavailable character at cold start (09-REVIEW WR-03)', () {
    late UserRefreshRequestBus refreshBus;
    late int refreshRequests;

    setUp(() {
      refreshBus = UserRefreshRequestBus();
      addTearDown(refreshBus.close);
      refreshRequests = 0;
      refreshBus.requests.listen((_) => refreshRequests++);
      whenListen(
        characterCubit,
        Stream<CharacterState>.empty(),
        initialState: const CharacterUnavailable(),
      );
      when(() => questResultsCubit.refetchPending()).thenAnswer((_) async {});
    });

    Future<void> pumpUnavailable(
      WidgetTester tester,
      QuestResultsState results,
    ) async {
      useLandscapePhone(tester);
      final availability = MapAvailabilityCubit();
      addTearDown(availability.close);
      final travelCubit = MockTravelCubit();
      whenListen(
        travelCubit,
        const Stream<TravelState>.empty(),
        initialState: const TravelIdle(),
      );
      whenListen(
        questResultsCubit,
        const Stream<QuestResultsState>.empty(),
        initialState: results,
      );
      await tester.pumpWidget(
        buildTestApp(
          home: RepositoryProvider<UserRefreshRequests>.value(
            value: refreshBus,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<CharacterCubit>.value(value: characterCubit),
                BlocProvider<QuestCubit>.value(value: questCubit),
                BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
                BlocProvider<MapAvailabilityCubit>.value(value: availability),
                BlocProvider<TravelCubit>.value(value: travelCubit),
                BlocProvider<InAppNotificationsCubit>.value(
                  value: MockInAppNotificationsCubit(),
                ),
                BlocProvider<QuestResultsCubit>.value(value: questResultsCubit),
                BlocProvider<NotificationPreferencesCubit>.value(
                  value: preferencesCubit,
                ),
                BlocProvider<TeleportModeCubit>.value(value: teleportCubit),
                BlocProvider<AuthCubit>.value(value: authCubit),
              ],
              child: const MainScreen(characterId: 'c-42'),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final refetch in [PendingRefetch.idle, PendingRefetch.inFlight]) {
      testWidgets('keeps the loader while the read is ${refetch.name}', (
        tester,
      ) async {
        await pumpUnavailable(
          tester,
          QuestResultsState(pendingRefetch: refetch),
        );

        expect(find.byType(KGLoader), findsOneWidget);
        expect(find.byType(KGError), findsNothing);
      });
    }

    for (final refetch in [PendingRefetch.done, PendingRefetch.failed]) {
      testWidgets('a ${refetch.name} read with no sheet offers a retry', (
        tester,
      ) async {
        await pumpUnavailable(
          tester,
          QuestResultsState(pendingRefetch: refetch),
        );

        expect(find.byType(KGLoader), findsNothing);
        expect(find.byType(KGError), findsOneWidget);

        await tester.fling(find.byType(KGError), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        verify(() => questResultsCubit.refetchPending()).called(1);
        expect(refreshRequests, 1);
      });
    }

    testWidgets('a death acknowledged keeps the loader', (tester) async {
      await pumpUnavailable(
        tester,
        const QuestResultsState(
          pendingRefetch: PendingRefetch.done,
          deathAcknowledgement: DeathAcknowledgement.done,
        ),
      );

      expect(find.byType(KGLoader), findsOneWidget);
      expect(find.byType(KGError), findsNothing);
    });
  });

  group('satchel wiring', () {
    final cities = [
      City.fromJson({
        'id': 'city-1',
        'markerLocation': {
          'id': 'city-marker-1',
          'location': [1.0, 2.0],
        },
      }),
    ];

    late MockQuestAcceptanceCubit acceptanceCubit;
    late MockInAppNotificationsCubit noticesCubit;
    late StreamController<QuestAcceptanceState> acceptanceStates;
    late MockTravelCubit travelCubit;
    late StreamController<TravelState> travelStates;
    late MockSpellsCubit spellsCubit;
    late StreamController<SpellsState> spellsStates;
    late MockTransactionCubit transactionCubit;
    late StreamController<TransactionState> transactionStates;
    late MapAvailabilityCubit availability;

    setUp(() {
      availability = MapAvailabilityCubit();
      addTearDown(availability.close);
      registerFallbackValue(const KGNotification(title: '', description: ''));
      acceptanceCubit = MockQuestAcceptanceCubit();
      noticesCubit = MockInAppNotificationsCubit();
      acceptanceStates = StreamController<QuestAcceptanceState>.broadcast();
      addTearDown(acceptanceStates.close);
      whenListen(
        acceptanceCubit,
        acceptanceStates.stream,
        initialState: const QuestAcceptanceIdle(),
      );
      travelCubit = MockTravelCubit();
      travelStates = StreamController<TravelState>.broadcast();
      addTearDown(travelStates.close);
      whenListen(
        travelCubit,
        travelStates.stream,
        initialState: const TravelIdle(),
      );
      spellsCubit = MockSpellsCubit();
      spellsStates = StreamController<SpellsState>.broadcast();
      addTearDown(spellsStates.close);
      whenListen(
        spellsCubit,
        spellsStates.stream,
        initialState: const SpellsState(),
      );
      transactionCubit = MockTransactionCubit();
      transactionStates = StreamController<TransactionState>.broadcast();
      addTearDown(transactionStates.close);
      whenListen(
        transactionCubit,
        transactionStates.stream,
        initialState: TransactionInitial(),
      );
      final svg =
          File('${Directory.systemTemp.createTempSync('kg_svg').path}/i.svg')
            ..writeAsStringSync(
              '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
            );
      for (final entry in SatchelLayout.entries) {
        SvgCache().add(CloudinaryAssets.url(entry.assetPath), svg);
      }
      SvgCache().add(CloudinaryAssets.url(CloudinaryAssets.pouch), svg);
      whenListen(
        mainScreenCubit,
        Stream<MainScreenState>.empty(),
        initialState: MainScreenLoadData(cities),
      );
    });

    Future<void> pumpMainScreen(
      WidgetTester tester,
      String locationId, {
      Map<String, dynamic>? activeTravel,
      Map<String, dynamic>? awaitingAid,
    }) async {
      useLandscapePhone(tester);
      final authStates = StreamController<AuthState>.broadcast();
      final intentCubit = NotificationIntentCubit(authStates.stream);
      addTearDown(() async {
        await intentCubit.close();
        await authStates.close();
      });
      whenListen(
        characterCubit,
        Stream<CharacterState>.empty(),
        initialState: CharacterLoaded(
          Character.fromJson(
            activeTravel == null && awaitingAid == null
                ? characterWithLanesJson(locationId: locationId)
                : travellingCharacterJson(
                    locationId: locationId,
                    activeTravel: activeTravel,
                    awaitingAid: awaitingAid,
                  ),
          ),
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<QuestCubit>.value(value: questCubit),
              BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
              BlocProvider<NotificationIntentCubit>.value(value: intentCubit),
              BlocProvider<QuestAcceptanceCubit>.value(value: acceptanceCubit),
              BlocProvider<InAppNotificationsCubit>.value(value: noticesCubit),
              BlocProvider<TravelCubit>.value(value: travelCubit),
              BlocProvider<SpellsCubit>.value(value: spellsCubit),
              BlocProvider<TransactionCubit>.value(value: transactionCubit),
              BlocProvider<MapAvailabilityCubit>.value(value: availability),
              BlocProvider<QuestResultsCubit>.value(value: questResultsCubit),
              BlocProvider<NotificationPreferencesCubit>.value(
                value: preferencesCubit,
              ),
              BlocProvider<TeleportModeCubit>.value(value: teleportCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
            ],
            child: MainScreen(
              characterId: 'c-1',
              pagesBuilder: (_) => [
                for (final e in SatchelLayout.entries)
                  SizedBox.expand(key: ValueKey('page-${e.pageIndex}')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<PageController> openSatchel(WidgetTester tester) async {
      await tester.tap(find.byType(CachedSvg).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      return tester.widget<PageView>(find.byType(PageView)).controller!;
    }

    Future<PageController> pumpOpenSatchel(
      WidgetTester tester,
      String locationId, {
      Map<String, dynamic>? activeTravel,
      Map<String, dynamic>? awaitingAid,
    }) async {
      await pumpMainScreen(
        tester,
        locationId,
        activeTravel: activeTravel,
        awaitingAid: awaitingAid,
      );
      return openSatchel(tester);
    }

    Future<void> tapItem(WidgetTester tester, int pageIndex) async {
      await tester.tapAt(
        SatchelLayout.centerOf(
          SatchelLayout.entries[pageIndex],
          const Size(780, 360),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('map availability', () {
      late StreamController<MainScreenState> screenStates;

      setUp(() {
        screenStates = StreamController<MainScreenState>.broadcast();
        addTearDown(screenStates.close);
        whenListen(
          mainScreenCubit,
          screenStates.stream,
          initialState: MainScreenInitial(),
        );
      });

      Future<void> loadPages(WidgetTester tester) async {
        screenStates.add(MainScreenLoadData(cities));
        await tester.pump();
        await tester.pump();
      }

      testWidgets('the cold-start loader is never the map page', (
        tester,
      ) async {
        await pumpMainScreen(tester, 'city-marker-1');

        expect(find.byType(PageView), findsNothing);
        expect(availability.state.isMapPage, isFalse);
      });

      testWidgets('the loaded pages open on the map page', (tester) async {
        await pumpMainScreen(tester, 'city-marker-1');
        await loadPages(tester);

        expect(find.byType(PageView), findsOneWidget);
        expect(availability.state.isMapPage, isTrue);
      });

      testWidgets('a removed main screen is no longer the map page', (
        tester,
      ) async {
        await pumpMainScreen(tester, 'city-marker-1');
        await loadPages(tester);

        await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

        expect(availability.state.isMapPage, isFalse);
      });

      testWidgets('the map page follows every satchel navigation', (
        tester,
      ) async {
        await pumpMainScreen(tester, 'city-marker-1');
        await loadPages(tester);
        final controller = await openSatchel(tester);

        await tapItem(tester, 1);
        expect(controller.page!.round(), 1);
        expect(availability.state.isMapPage, isFalse);

        await openSatchel(tester);
        await tapItem(tester, NotificationIntentLanding.worldMapPageIndex);
        expect(controller.page!.round(), 0);
        expect(availability.state.isMapPage, isTrue);
      });

      group('teleport mode (10-CONTEXT D-17)', () {
        const bea = TeleportTarget(
          characterId: 'char-bea',
          name: 'Bea',
          location: PointOfInterest(
            id: 'city-marker-1',
            type: null,
            location: LatLng(1, 2),
            city: null,
            quest: null,
          ),
          sex: SexType.female,
        );

        testWidgets('another tab cancels the teleport mode', (tester) async {
          await pumpMainScreen(tester, 'city-marker-1');
          await loadPages(tester);
          await openSatchel(tester);

          await tapItem(tester, 1);

          verify(() => teleportCubit.cancel()).called(1);
        });

        testWidgets('the map tab does not cancel the teleport mode', (
          tester,
        ) async {
          await pumpMainScreen(tester, 'city-marker-1');
          await loadPages(tester);
          await openSatchel(tester);
          await tapItem(tester, 1);
          clearInteractions(teleportCubit);

          await openSatchel(tester);
          await tapItem(tester, NotificationIntentLanding.worldMapPageIndex);

          verifyNever(() => teleportCubit.cancel());
        });

        testWidgets('entering the mode from another tab lands on the map '
            'without cancelling it (P3)', (tester) async {
          await pumpMainScreen(tester, 'city-marker-1');
          await loadPages(tester);
          final controller = await openSatchel(tester);
          await tapItem(tester, 3);
          clearInteractions(teleportCubit);

          teleportStates.add(const TeleportActive(target: bea));
          await tester.pumpAndSettle();

          expect(controller.page!.round(), 0);
          expect(availability.state.isMapPage, isTrue);
          verifyNever(() => teleportCubit.cancel());
        });
      });
    });

    testWidgets('follows the awaited party', (tester) async {
      await pumpOpenSatchel(tester, 'city-marker-1');

      expect(find.byType(PartyWatchListener), findsOneWidget);
    });

    testWidgets('off a city marker the Bacheca item does nothing', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'poi-9');

      await tapItem(tester, SatchelLayout.boardPageIndex);

      expect(controller.page!.round(), 0);
    });

    testWidgets('off a city marker the Negozio item does nothing', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'poi-9');

      await tapItem(tester, SatchelLayout.shopPageIndex);

      expect(controller.page!.round(), 0);
    });

    testWidgets('off a city marker another item still navigates', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'poi-9');

      await tapItem(tester, 6);

      expect(controller.page!.round(), 6);
    });

    testWidgets(
      'while travelling from a city marker board and shop do nothing',
      (tester) async {
        final controller = await pumpOpenSatchel(
          tester,
          'city-marker-1',
          activeTravel: activeTravelJson(),
        );

        await tapItem(tester, SatchelLayout.boardPageIndex);
        expect(controller.page!.round(), 0);

        await tapItem(tester, SatchelLayout.shopPageIndex);
        expect(controller.page!.round(), 0);
      },
    );

    testWidgets('while travelling the Profilo item still navigates', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(
        tester,
        'city-marker-1',
        activeTravel: activeTravelJson(),
      );

      await tapItem(tester, 1);

      expect(controller.page!.round(), 1);
    });

    testWidgets('awaiting aid on a city marker board and shop do nothing', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(
        tester,
        'city-marker-1',
        awaitingAid: awaitingAidJson(),
      );

      await tapItem(tester, SatchelLayout.boardPageIndex);
      expect(controller.page!.round(), 0);

      await tapItem(tester, SatchelLayout.shopPageIndex);
      expect(controller.page!.round(), 0);
    });

    testWidgets('awaiting aid the board and shop cells look disabled', (
      tester,
    ) async {
      await pumpOpenSatchel(
        tester,
        'city-marker-1',
        awaitingAid: awaitingAidJson(),
      );

      const boardAndShop = {
        SatchelLayout.boardPageIndex,
        SatchelLayout.shopPageIndex,
      };
      expect(
        tester.widget<SatchelMenu>(find.byType(SatchelMenu)).disabledPages,
        boardAndShop,
      );
      expect(
        tester
            .widget<MenuBackground>(find.byType(MenuBackground))
            .disabledPages,
        boardAndShop,
      );
    });

    testWidgets('awaiting aid the Profilo item still navigates', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(
        tester,
        'city-marker-1',
        awaitingAid: awaitingAidJson(),
      );

      await tapItem(tester, 1);

      expect(controller.page!.round(), 1);
    });

    testWidgets('on a city marker the Negozio item opens the shop', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'city-marker-1');

      await tapItem(tester, SatchelLayout.shopPageIndex);

      expect(controller.page!.round(), 5);
    });

    testWidgets('on a city marker the Bacheca item opens the board', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'city-marker-1');

      await tapItem(tester, SatchelLayout.boardPageIndex);

      expect(controller.page!.round(), 4);
    });

    testWidgets(
      'a rejection answered away from the Board still shows the banner',
      (tester) async {
        final controller = await pumpOpenSatchel(tester, 'city-marker-1');
        await tapItem(tester, 5);
        expect(controller.page!.round(), 5);

        acceptanceStates.add(
          const QuestAcceptanceFailed(
            'q-1',
            QuestAcceptanceFailure.notAcceptable,
          ),
        );
        await tester.pump();

        verify(
          () => noticesCubit.publishNotice(
            const KGNotification(
              title: 'Missione non accettata',
              description: 'Missione non disponibile, avvisa il locandiere',
            ),
            dedupKey: 'quest-acceptance|notAcceptable|q-1',
          ),
        ).called(1);
        verify(() => acceptanceCubit.reset()).called(1);
      },
    );

    testWidgets(
      'a travel rejection answered away from the map still shows the banner',
      (tester) async {
        final controller = await pumpOpenSatchel(tester, 'city-marker-1');
        await tapItem(tester, 5);
        expect(controller.page!.round(), 5);

        travelStates.add(
          TravelFailed(
            destination: City.fromJson(travelCityJson()),
            failure: TravelFailure.inProgress,
            stage: TravelStage.start,
          ),
        );
        await tester.pump();

        verify(
          () => noticesCubit.publishNotice(
            const KGNotification(
              title: 'Viaggio non partito',
              description: 'Sei già in viaggio',
            ),
            dedupKey: 'travel|inProgress|city-2',
          ),
        ).called(1);
        verify(() => travelCubit.reset()).called(1);
      },
    );

    testWidgets('a shop refusal answered away from the shop shows the banner '
        '(09-REVIEW IN-05)', (tester) async {
      final controller = await pumpOpenSatchel(tester, 'city-marker-1');
      await tapItem(tester, 1);
      expect(controller.page!.round(), 1);

      transactionStates.add(TransactionError(TransactionFailure.shopNotInCity));
      await tester.pump();

      verify(
        () => noticesCubit.publishNotice(
          const KGNotification(
            title: 'Negozio non disponibile',
            description: 'Il negozio è disponibile solo in città',
          ),
          dedupKey: 'transaction|shopNotInCity',
        ),
      ).called(1);
    });

    testWidgets(
      'a spell rollback answered away from the Journal shows the banner',
      (tester) async {
        final controller = await pumpOpenSatchel(tester, 'city-marker-1');
        expect(controller.page!.round(), 0);

        spellsStates.add(
          const SpellsState(
            outcome: SpellOutcome(
              sequence: 1,
              spellId: 'spell-1',
              operation: SpellOperation.equip,
              kind: SpellOutcomeKind.failed,
              failure: SpellEquipFailure.connection,
            ),
          ),
        );
        await tester.pump();

        verify(
          () => noticesCubit.publishNotice(
            const KGNotification(
              title: 'Magia non equipaggiata',
              description: 'Connessione assente, riprova',
            ),
            dedupKey: 'spell|failed|connection|spell-1',
          ),
        ).called(1);
      },
    );
  });
}
