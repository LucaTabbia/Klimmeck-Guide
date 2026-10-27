import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/quest_result/quest_end_event.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_result_presenter.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_result_notice.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_pending_quest_results.dart';
import '../../../helpers/fakes/recording_quest_result_acknowledger.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

String _at(int minute) => '2026-10-27T12:0$minute:00.000Z';

QuestResult _success(String id, {int minute = 0}) =>
    questResult(successResultJson(id: id, resolvedAt: _at(minute)));

/// Presenter con i cubit reali della coda e della mappa contro fake e mock
/// (09-10): la subscription live è [live], la lista non confermata [pending].
class _PresenterHarness {
  _PresenterHarness() {
    when(() => repository.watch(any())).thenAnswer((_) => live.stream);
    whenListen(travel, travelStates.stream, initialState: const TravelIdle());
    whenListen(
      character,
      characterStates.stream,
      initialState: CharacterLoading(),
    );
    when(() => preferences.state).thenReturn(NotificationPreferencesState());
  }

  final MockQuestResultRepository repository = MockQuestResultRepository();
  final StreamController<QuestResult> live =
      StreamController<QuestResult>.broadcast();
  final FakePendingQuestResults pending = FakePendingQuestResults();
  final RecordingQuestResultAcknowledger acknowledger =
      RecordingQuestResultAcknowledger();
  final AppLifecycleEventBus lifecycle = AppLifecycleEventBus();
  final ConnectionRestoredBus connectionRestored = ConnectionRestoredBus();
  final UserRefreshRequestBus refreshBus = UserRefreshRequestBus();
  final MapAvailabilityCubit availability = MapAvailabilityCubit();
  final MockTravelCubit travel = MockTravelCubit();
  final MockInAppNotificationsCubit notices = MockInAppNotificationsCubit();
  final MockNotificationPreferencesCubit preferences =
      MockNotificationPreferencesCubit();
  final MockCharacterCubit character = MockCharacterCubit();
  final StreamController<TravelState> travelStates =
      StreamController<TravelState>.broadcast();
  final StreamController<CharacterState> characterStates =
      StreamController<CharacterState>.broadcast();

  /// Creato al primo uso dentro il test: la coda delle conferme nasce nella
  /// zona fake del tester, non in quella reale di `setUp`.
  late final QuestResultsCubit results = QuestResultsCubit(
    characterId: 'c-1',
    repository: repository,
    pending: pending,
    acknowledger: acknowledger,
    lifecycle: lifecycle,
    connectionRestored: connectionRestored,
    userRefresh: refreshBus,
  );

  Future<void> pump(WidgetTester tester) async {
    useLandscapePhone(tester);
    results.start();
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<QuestResultsCubit>.value(value: results),
            BlocProvider<MapAvailabilityCubit>.value(value: availability),
            BlocProvider<TravelCubit>.value(value: travel),
            BlocProvider<InAppNotificationsCubit>.value(value: notices),
            BlocProvider<NotificationPreferencesCubit>.value(
              value: preferences,
            ),
            BlocProvider<CharacterCubit>.value(value: character),
          ],
          child: const QuestResultPresenter(child: Scaffold(body: Text('map'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> arrive(WidgetTester tester, QuestResult result) async {
    live.add(result);
    await tester.pumpAndSettle();
  }

  Future<void> enterMap(WidgetTester tester, {bool isMapPage = true}) async {
    availability.pageChanged(isMapPage: isMapPage);
    await tester.pumpAndSettle();
  }

  Future<void> emitTravel(WidgetTester tester, TravelState state) async {
    travelStates.add(state);
    await tester.pumpAndSettle();
  }

  Future<void> emitCharacter(WidgetTester tester, CharacterState state) async {
    characterStates.add(state);
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    await results.close();
    await availability.close();
    await Future.wait([
      live.close(),
      travelStates.close(),
      characterStates.close(),
      lifecycle.close(),
      connectionRestored.close(),
      refreshBus.close(),
    ]);
  }
}

final Finder _sheet = find.byType(QuestResultSheet);

BuildContext _homeContext(WidgetTester tester) =>
    tester.element(find.text('map'));

void main() {
  late _PresenterHarness h;

  setUpAll(() {
    registerFallbackValue(questEndEventOf(_success('fallback')));
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.helmetType,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]);
    h = _PresenterHarness();
  });

  tearDown(() => h.dispose());

  void verifyNoBanner() => verifyNever(() => h.notices.publish(any()));

  void verifyNoSuppression() => verifyNever(() => h.notices.suppress(any()));

  group('QuestResultPresenter gating (D-06, D-07, D-23)', () {
    testWidgets('map free + live success → sheet opens at once without a '
        'banner', (tester) async {
      await h.pump(tester);
      await h.enterMap(tester);

      await h.arrive(tester, _success('result-1'));

      expect(_sheet, findsOneWidget);
      verify(() => h.notices.suppress('questEnd|result-1')).called(1);
      verifyNoBanner();
    });

    testWidgets('away from the map a live result publishes the banner and '
        'waits', (tester) async {
      final result = _success('result-1');
      await h.pump(tester);
      await h.enterMap(tester, isMapPage: false);

      await h.arrive(tester, result);

      expect(_sheet, findsNothing);
      verify(() => h.notices.publish(questEndEventOf(result))).called(1);

      await h.enterMap(tester);

      expect(_sheet, findsOneWidget);
      verifyNoBanner();
    });

    testWidgets('the quest toggle off silences the banner, never the sheet', (
      tester,
    ) async {
      when(() => h.preferences.state).thenReturn(
        NotificationPreferencesState().withCategory(
          NotificationCategory.questEnd,
          enabled: false,
        ),
      );
      await h.pump(tester);

      await h.arrive(tester, _success('result-1'));
      await h.enterMap(tester);

      verifyNoBanner();
      expect(_sheet, findsOneWidget);
    });

    testWidgets('a dialog above the shell delays the sheet', (tester) async {
      await h.pump(tester);
      await h.enterMap(tester);
      unawaited(
        showDialog<void>(
          context: _homeContext(tester),
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();

      await h.arrive(tester, _success('result-1'));

      expect(_sheet, findsNothing);
      expect(h.availability.state.isRouteCovered, isTrue);

      Navigator.of(tester.element(find.text('dialog'))).pop();
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
    });

    testWidgets('an open quest sheet or a pawn drag delays the sheet', (
      tester,
    ) async {
      h.pending.results = [_success('result-a'), _success('result-b')];
      await h.pump(tester);
      h.availability.questSheetChanged(true);
      await h.enterMap(tester);

      expect(_sheet, findsNothing);

      h.availability.questSheetChanged(false);
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);

      h.availability.pawnDragChanged(true);
      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);

      h.availability.pawnDragChanged(false);
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
    });

    testWidgets('a travel flow delays the sheet', (tester) async {
      h.pending.results = [_success('result-1')];
      await h.pump(tester);
      await h.emitTravel(
        tester,
        TravelPreviewing(City.fromJson(travelCityJson(image: null))),
      );

      await h.enterMap(tester);

      expect(_sheet, findsNothing);

      await h.emitTravel(tester, const TravelIdle());

      expect(_sheet, findsOneWidget);
    });

    testWidgets('port results never publish a banner', (tester) async {
      h.pending.results = [_success('result-1')];
      await h.pump(tester);

      expect(_sheet, findsNothing);
      verifyNoBanner();
      verifyNoSuppression();

      await h.enterMap(tester);

      expect(_sheet, findsOneWidget);
      verifyNoBanner();
      verifyNoSuppression();
    });

    testWidgets('a live arrival behind a queued head gets the banner', (
      tester,
    ) async {
      final behind = _success('result-b', minute: 1);
      h.pending.results = [_success('result-a')];
      await h.pump(tester);
      await h.enterMap(tester);
      expect(_sheet, findsOneWidget);

      await h.arrive(tester, behind);

      verify(() => h.notices.publish(questEndEventOf(behind))).called(1);
      verifyNever(() => h.notices.suppress('questEnd|result-b'));
    });
  });

  group('QuestResultPresenter dialog (D-05, COMBAT-06)', () {
    testWidgets('scrim, back and drag do nothing', (tester) async {
      h.pending.results = [_success('result-1')];
      await h.pump(tester);
      await h.enterMap(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.drag(_sheet, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
      expect(h.acknowledger.calls, isEmpty);
    });

    testWidgets('the button closes, acknowledges and opens the next with the '
        'counter', (tester) async {
      h.pending.results = [
        _success('result-a'),
        _success('result-b', minute: 1),
      ];
      await h.pump(tester);
      await h.enterMap(tester);

      expect(find.text('1 di 2'), findsOneWidget);

      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pumpAndSettle();

      expect(h.acknowledger.acknowledged, ['result-a']);
      expect(_sheet, findsOneWidget);
      expect(find.text('2 di 2'), findsOneWidget);
    });

    testWidgets('an external pop requeues without acknowledging', (
      tester,
    ) async {
      h.pending.results = [_success('result-1')];
      await h.pump(tester);
      await h.enterMap(tester);

      Navigator.of(_homeContext(tester)).popUntil((route) => route.isFirst);
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
      expect(h.acknowledger.calls, isEmpty);
    });
  });

  group('QuestResultPresenter side signals (D-11, D-13)', () {
    testWidgets('a character that becomes unavailable triggers a refetch', (
      tester,
    ) async {
      await h.pump(tester);
      final callsBefore = h.pending.calls;

      await h.emitCharacter(tester, const CharacterUnavailable());

      expect(h.pending.calls, callsBefore + 1);
    });

    testWidgets('a refused tap lookup shows the notice', (tester) async {
      when(() => h.repository.fetch('r-9')).thenAnswer(
        (_) async =>
            throw const QuestResultException(QuestResultFailure.notFound),
      );
      await h.pump(tester);

      await h.results.requestFromTap('r-9');
      await tester.pumpAndSettle();

      verify(
        () => h.notices.publishNotice(
          questResultNoticeFor(QuestResultFailure.notFound)!,
          dedupKey: 'questResult|r-9',
        ),
      ).called(1);
    });
  });
}
