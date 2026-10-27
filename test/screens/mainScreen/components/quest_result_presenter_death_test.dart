import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/quest_result/quest_end_event.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_result_presenter.dart';
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

QuestResult _death({int minute = 0, String character = 'c-1'}) =>
    questResult(deathResultJson(resolvedAt: _at(minute), character: character));

/// Personaggio della shell `c-1`, di nome Aldo.
final Character _aldo = Character.fromJson(travellingCharacterJson());

/// Presenter con i cubit reali della coda e della mappa contro fake e mock
/// (09-10): la subscription live è [live], la lista non confermata [pending].
class _DeathHarness {
  _DeathHarness() {
    when(() => repository.watch(any())).thenAnswer((_) => live.stream);
    whenListen(
      travel,
      const Stream<TravelState>.empty(),
      initialState: const TravelIdle(),
    );
    whenListen(
      character,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(_aldo),
    );
    when(() => preferences.state).thenReturn(NotificationPreferencesState());
    refreshBus.requests.listen((_) => refreshRequests++);
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
  int refreshRequests = 0;

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
          child: const QuestResultPresenter(
            child: Scaffold(body: Text('journal')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> arrive(WidgetTester tester, QuestResult result) async {
    live.add(result);
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    await results.close();
    await availability.close();
    await Future.wait([
      live.close(),
      lifecycle.close(),
      connectionRestored.close(),
      refreshBus.close(),
    ]);
  }
}

final Finder _sheet = find.byType(QuestResultSheet);

String? _header(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(QuestResultSheet.headerKey)).data;

TextButton _button(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(QuestResultSheet.continueKey));

Future<void> _pressButton(WidgetTester tester) async {
  await tester.tap(find.byKey(QuestResultSheet.continueKey));
  await tester.pumpAndSettle();
}

void main() {
  late _DeathHarness h;

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
    h = _DeathHarness();
  });

  tearDown(() => h.dispose());

  group('QuestResultPresenter death gating (D-08, D-13)', () {
    testWidgets('off the map a death opens at once with the shell character '
        'name', (tester) async {
      await h.pump(tester);

      await h.arrive(tester, _death());

      expect(_sheet, findsOneWidget);
      expect(_header(tester), 'È morto');
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.deadNameKey)).data,
        'Aldo',
      );
    });

    testWidgets('a death of another character shows no name line', (
      tester,
    ) async {
      await h.pump(tester);

      await h.arrive(tester, _death(character: 'c-9'));

      expect(_header(tester), 'È morto');
      expect(find.byKey(QuestResultSheet.deadNameKey), findsNothing);
    });

    testWidgets('a death unlocks the queue ahead of it', (tester) async {
      h.pending.results = [_success('result-a'), _death(minute: 1)];

      await h.pump(tester);

      expect(_header(tester), 'Vittoria');
      expect(find.text('1 di 2'), findsOneWidget);

      await _pressButton(tester);

      expect(_header(tester), 'È morto');
      expect(find.text('2 di 2'), findsOneWidget);
    });

    testWidgets('a route above the shell still delays the death', (
      tester,
    ) async {
      await h.pump(tester);
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('journal')),
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();

      await h.arrive(tester, _death());

      expect(_sheet, findsNothing);

      Navigator.of(tester.element(find.text('dialog'))).pop();
      await tester.pumpAndSettle();

      expect(_header(tester), 'È morto');
    });
  });

  group('QuestResultPresenter death acknowledgement (D-10, D-13)', () {
    testWidgets('the death button awaits the acknowledgement', (tester) async {
      final answer = Completer<void>();
      h.acknowledger.hold = answer;
      h.pending.results = [_death()];
      await h.pump(tester);

      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pump();

      expect(_button(tester).onPressed, isNull);
      expect(_sheet, findsOneWidget);

      answer.complete();
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(h.acknowledger.acknowledged, ['result-death']);
      expect(h.acknowledger.calls, ['result-death']);
    });

    testWidgets('a failed death acknowledgement keeps the sheet with a retry', (
      tester,
    ) async {
      h.acknowledger.errorOnce = Exception('offline');
      h.pending.results = [_death()];
      await h.pump(tester);

      await _pressButton(tester);

      expect(find.byKey(QuestResultSheet.acknowledgeErrorKey), findsOneWidget);
      expect(_sheet, findsOneWidget);

      await _pressButton(tester);

      expect(_sheet, findsNothing);
      expect(h.acknowledger.acknowledged, ['result-death']);
    });

    testWidgets('the death ack asks for one user refresh', (tester) async {
      h.acknowledger.errorOnce = Exception('offline');
      h.pending.results = [_death()];
      await h.pump(tester);

      await _pressButton(tester);

      expect(h.refreshRequests, 0);

      await _pressButton(tester);

      expect(h.refreshRequests, 1);
    });

    testWidgets('after the death nothing else opens', (tester) async {
      h.pending.results = [_death(), _success('result-later', minute: 5)];
      h.availability.pageChanged(isMapPage: true);
      await h.pump(tester);

      expect(_header(tester), 'È morto');

      await _pressButton(tester);

      expect(_sheet, findsNothing);
      expect(h.acknowledger.calls, ['result-death']);
    });

    testWidgets('back and scrim do nothing on the death sheet either', (
      tester,
    ) async {
      h.pending.results = [_death()];
      await h.pump(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_header(tester), 'È morto');
      expect(h.acknowledger.calls, isEmpty);
    });
  });
}
