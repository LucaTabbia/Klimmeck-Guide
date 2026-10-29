import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/participant_row.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';
import '../../helpers/fixtures/quest_result_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

final DateTime _now = DateTime.utc(2026, 10, 29, 12);

List<PendingRequest> _queue(List<Map<String, dynamic>> entries) =>
    List.unmodifiable(entries.map(PendingRequest.fromJson));

typedef _CompletionOpener =
    Future<CompletionExit?> Function(BuildContext context, RequestCard card);

ElevatedButton _completeButton(WidgetTester tester, String questId) =>
    tester.widget<ElevatedButton>(
      find.byKey(RequestCardView.completeKeyFor(questId)),
    );

Finder _teleportAction(String characterId) =>
    find.byKey(ValueKey('innkeeper.teleport.$characterId'));

TextButton _teleportButton(WidgetTester tester, String characterId) =>
    tester.widget<TextButton>(_teleportAction(characterId));

Finder _greyedAncestorOf(Finder finder) => find.ancestor(
  of: finder,
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Opacity &&
        widget.opacity == KlimmeckGuideTheme.pendingInkOpacity,
  ),
);

void main() {
  late MockPendingRequestsCubit cubit;
  late MockAuthCubit authCubit;
  late MockTeleportModeCubit teleportCubit;
  late StreamController<TeleportModeState> teleportStates;

  setUp(() {
    cubit = MockPendingRequestsCubit();
    teleportCubit = MockTeleportModeCubit();
    teleportStates = StreamController<TeleportModeState>.broadcast();
    addTearDown(teleportStates.close);
    whenListen(
      teleportCubit,
      teleportStates.stream,
      initialState: const TeleportIdle(),
    );
    when(
      () => teleportCubit.prepare(
        characterId: any(named: 'characterId'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async {});
    authCubit = MockAuthCubit();
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUser(role: RoleType.innkeeper),
        accessToken: testAccessToken,
      ),
    );
  });

  Future<void> pumpPanel(
    WidgetTester tester,
    PendingRequestsState state, {
    _CompletionOpener openCompletion = openRequestCompletion,
    InnkeeperRepository? repository,
  }) async {
    useLandscapePhone(tester);
    whenListen(
      cubit,
      const Stream<PendingRequestsState>.empty(),
      initialState: state,
    );
    final panel = MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<PendingRequestsCubit>.value(value: cubit),
        BlocProvider<TeleportModeCubit>.value(value: teleportCubit),
      ],
      child: InnkeeperPanelScreen(openCompletion: openCompletion),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: repository == null
            ? panel
            : RepositoryProvider<InnkeeperRepository>.value(
                value: repository,
                child: panel,
              ),
      ),
    );
  }

  Future<void> pumpQueue(
    WidgetTester tester,
    List<Map<String, dynamic>> entries, {
    DateTime? serverNow,
    _CompletionOpener openCompletion = openRequestCompletion,
    InnkeeperRepository? repository,
  }) => pumpPanel(
    tester,
    PendingRequestsState(
      serverNow: serverNow ?? _now,
      requests: _queue(entries),
      isLoaded: true,
    ),
    openCompletion: openCompletion,
    repository: repository,
  );

  testWidgets('the AppBar title is «Locanda»', (tester) async {
    await pumpQueue(tester, []);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Locanda')),
      findsOneWidget,
    );
  });

  testWidgets('before the first snapshot only the loader shows', (
    tester,
  ) async {
    await pumpPanel(tester, PendingRequestsState(serverNow: _now));

    expect(find.byType(KGLoader), findsOneWidget);
    expect(find.byType(RequestCardView), findsNothing);
    expect(find.text(InnkeeperPanelScreen.emptyTitle), findsNothing);
  });

  testWidgets('an empty queue shows the empty state without a loader', (
    tester,
  ) async {
    await pumpQueue(tester, []);

    expect(find.text('Nessuna richiesta in attesa'), findsOneWidget);
    expect(find.text('La coda si aggiorna da sola'), findsOneWidget);
    expect(find.byType(KGLoader), findsNothing);
  });

  testWidgets('a story card shows title, type and the present participant', (
    tester,
  ) async {
    await pumpQueue(tester, [pendingRequestJson()]);

    expect(find.byKey(RequestCardView.keyFor(storyQuestId)), findsOneWidget);
    expect(find.text('La cripta di Valantar'), findsOneWidget);
    expect(find.text('Storia'), findsOneWidget);
    expect(find.text('Aldo'), findsOneWidget);
    expect(find.text('Presente'), findsOneWidget);
    expect(find.textContaining('posti'), findsNothing);
  });

  testWidgets('a card shows only the quest, the rows and «Completa» (D-08)', (
    tester,
  ) async {
    await pumpQueue(tester, [pendingRequestJson()]);

    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(RequestCardView.keyFor(storyQuestId)),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toSet();
    expect(texts, {
      'La cripta di Valantar',
      'Storia',
      'Aldo',
      'Presente',
      'Teletrasporta',
      'Completa',
    });
  });

  testWidgets('a worldMission card shows the seats', (tester) async {
    await pumpQueue(tester, worldMissionEntriesJson());

    expect(find.text('Missione mondiale'), findsOneWidget);
    expect(find.text('2/3 posti'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
    expect(find.text('Cosimo'), findsOneWidget);
    expect(find.textContaining('registrati'), findsNothing);
  });

  testWidgets('a hidden busy participant leaves the caption', (tester) async {
    await pumpQueue(
      tester,
      worldMissionEntriesJson(
        names: ['Bea', 'Cosimo', 'Dario'],
        busyLanes: {'Dario': 'quest-standard-1'},
      ),
    );

    expect(find.text('Dario'), findsNothing);
    expect(find.text('3/3 posti'), findsOneWidget);
    expect(find.text('2 presenti su 3 registrati'), findsOneWidget);
    expect(
      find.text('Un partecipante è impegnato in una missione'),
      findsOneWidget,
    );
  });

  testWidgets('a traveller row is greyed with the remaining time', (
    tester,
  ) async {
    await pumpQueue(tester, [
      pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: _now.add(const Duration(minutes: 12)),
        ),
      ),
    ]);

    expect(find.text('In viaggio · 12 min'), findsOneWidget);
    expect(_greyedAncestorOf(find.text('In viaggio · 12 min')), findsOneWidget);
  });

  testWidgets('a present row is not greyed', (tester) async {
    await pumpQueue(tester, [pendingRequestJson()]);

    expect(_greyedAncestorOf(find.text('Presente')), findsNothing);
  });

  testWidgets('after endTime the traveller reads «Arrivato», not greyed', (
    tester,
  ) async {
    await pumpQueue(tester, [
      pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: _now.subtract(const Duration(seconds: 1)),
        ),
      ),
    ]);

    expect(find.text('Arrivato'), findsOneWidget);
    expect(_greyedAncestorOf(find.text('Arrivato')), findsNothing);
  });

  group('«Completa»', () {
    final completeStory = find.byKey(
      RequestCardView.completeKeyFor(storyQuestId),
    );
    final travel = queuedTravelJson(
      endTime: _now.add(const Duration(minutes: 12)),
    );

    setUp(() {
      when(() => cubit.refetch()).thenAnswer((_) async {});
    });

    _CompletionOpener exitWith(CompletionExit? exit) =>
        (_, _) async => exit;

    testWidgets('a story with a present participant can be completed', (
      tester,
    ) async {
      await pumpQueue(tester, [pendingRequestJson()]);

      expect(completeStory, findsOneWidget);
      expect(_completeButton(tester, storyQuestId).onPressed, isNotNull);
    });

    testWidgets('a traveller before endTime disables it', (tester) async {
      await pumpQueue(tester, [pendingRequestJson(activeTravel: travel)]);

      expect(_completeButton(tester, storyQuestId).onPressed, isNull);
    });

    testWidgets('the same traveller after endTime enables it', (tester) async {
      await pumpQueue(tester, [
        pendingRequestJson(activeTravel: travel),
      ], serverNow: _now.add(const Duration(minutes: 13)));

      expect(_completeButton(tester, storyQuestId).onPressed, isNotNull);
    });

    testWidgets('a hidden busy participant disables it', (tester) async {
      await pumpQueue(
        tester,
        worldMissionEntriesJson(
          names: ['Bea', 'Cosimo', 'Dario'],
          busyLanes: {'Dario': 'quest-standard-1'},
        ),
      );

      expect(_completeButton(tester, worldMissionQuestId).onPressed, isNull);
    });

    testWidgets('tapping it opens the completion form', (tester) async {
      final repository = MockInnkeeperRepository();
      when(
        () => repository.readCharacter('char-aldo'),
      ).thenAnswer((_) async => Character.fromJson(participantCharacterJson()));
      await pumpQueue(tester, [pendingRequestJson()], repository: repository);

      await tester.tap(completeStory);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RequestCompletionScreen), findsOneWidget);
    });

    testWidgets('a completion hides the card and shows the results', (
      tester,
    ) async {
      final results = [
        QuestResult.fromJson(
          questResultJson(
            character: 'char-aldo',
            outcome: 'gmCompleted',
            hpBefore: 18,
            hpAfter: 5,
            xpGained: 40,
          ),
        ),
      ];
      await pumpQueue(tester, [
        pendingRequestJson(),
      ], openCompletion: exitWith(CompletionCompleted(results)));

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      verify(() => cubit.markCompleted(storyQuestId)).called(1);
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Richiesta completata'),
        ),
        findsOneWidget,
      );
      for (final text in ['Aldo', 'Missione completata', 'PV 18 → 5']) {
        expect(
          find.descendant(of: dialog, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a vanished request is removed and the queue refetched', (
      tester,
    ) async {
      await pumpQueue(tester, [
        pendingRequestJson(),
      ], openCompletion: exitWith(const CompletionGone()));

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      verify(() => cubit.markCompleted(storyQuestId)).called(1);
      verify(() => cubit.refetch()).called(1);
      expect(find.text('Richiesta non più disponibile'), findsOneWidget);
    });

    testWidgets('a busy participant refetches without hiding the card', (
      tester,
    ) async {
      await pumpQueue(tester, [
        pendingRequestJson(),
      ], openCompletion: exitWith(const CompletionBusy()));

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      verifyNever(() => cubit.markCompleted(any()));
      verify(() => cubit.refetch()).called(1);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Un partecipante è impegnato in una missione'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a forbidden exit closes the panel with the message', (
      tester,
    ) async {
      useLandscapePhone(tester);
      whenListen(
        cubit,
        const Stream<PendingRequestsState>.empty(),
        initialState: PendingRequestsState(
          serverNow: _now,
          requests: _queue([pendingRequestJson()]),
          isLoaded: true,
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<AuthCubit>.value(value: authCubit),
                        BlocProvider<PendingRequestsCubit>.value(value: cubit),
                        BlocProvider<TeleportModeCubit>.value(
                          value: teleportCubit,
                        ),
                      ],
                      child: InnkeeperPanelScreen(
                        openCompletion: exitWith(const CompletionForbidden()),
                      ),
                    ),
                  ),
                ),
                child: const Text('apri'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      expect(find.byType(InnkeeperPanelScreen), findsNothing);
      expect(
        find.text(InnkeeperPanelScreen.unavailableMessage),
        findsOneWidget,
      );
    });

    testWidgets('leaving the form with the back arrow changes nothing', (
      tester,
    ) async {
      await pumpQueue(tester, [
        pendingRequestJson(),
      ], openCompletion: exitWith(null));

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      verifyNever(() => cubit.markCompleted(any()));
      verifyNever(() => cubit.refetch());
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('«Teletrasporta» (10-CONTEXT D-15/D-19)', () {
    testWidgets('every listed row has the action', (tester) async {
      await pumpQueue(
        tester,
        worldMissionEntriesJson(
          names: ['Bea', 'Cosimo', 'Dario'],
          travels: {
            'Cosimo': queuedTravelJson(
              endTime: _now.add(const Duration(minutes: 12)),
            ),
            'Dario': queuedTravelJson(
              endTime: _now.subtract(const Duration(seconds: 1)),
            ),
          },
        ),
      );

      for (final id in ['char-bea', 'char-cosimo', 'char-dario']) {
        expect(_teleportAction(id), findsOneWidget, reason: id);
        expect(_teleportButton(tester, id).onPressed, isNotNull, reason: id);
      }
      expect(find.text(ParticipantRow.teleportLabel), findsNWidgets(3));
    });

    testWidgets('an awaiting-aid row has the action too', (tester) async {
      await pumpQueue(tester, [
        pendingRequestJson(awaitingAid: awaitingAidJson()),
      ]);

      expect(_teleportButton(tester, 'char-aldo').onPressed, isNotNull);
    });

    testWidgets('a traveller keeps the action outside the greyed ink', (
      tester,
    ) async {
      await pumpQueue(tester, [
        pendingRequestJson(
          activeTravel: queuedTravelJson(
            endTime: _now.add(const Duration(minutes: 12)),
          ),
        ),
      ]);

      expect(_greyedAncestorOf(_teleportAction('char-aldo')), findsNothing);
    });

    testWidgets('tapping it reads the character for the teleport', (
      tester,
    ) async {
      await pumpQueue(tester, worldMissionEntriesJson());

      await tester.tap(_teleportAction('char-bea'));
      await tester.pump();

      verify(
        () => teleportCubit.prepare(characterId: 'char-bea', name: 'Bea'),
      ).called(1);
    });

    testWidgets('the read shows a progress on its row and locks the others', (
      tester,
    ) async {
      whenListen(
        teleportCubit,
        teleportStates.stream,
        initialState: const TeleportPreparing(characterId: 'char-bea'),
      );
      await pumpQueue(tester, worldMissionEntriesJson());

      expect(
        find.descendant(
          of: find.byKey(ParticipantRow.keyFor('char-bea')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(_teleportAction('char-bea'), findsNothing);
      expect(_teleportButton(tester, 'char-cosimo').onPressed, isNull);
    });

    testWidgets('a failed read shows the SnackBar and keeps the panel', (
      tester,
    ) async {
      await pumpQueue(tester, worldMissionEntriesJson());

      teleportStates.add(
        const TeleportPreparationFailed(
          characterId: 'char-bea',
          failure: InnkeeperFailure.connection,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(InnkeeperPanelScreen.teleportUnavailableMessage),
        ),
        findsOneWidget,
      );
      expect(
        InnkeeperPanelScreen.teleportUnavailableMessage,
        'Impossibile aprire la mappa per il teletrasporto',
      );
      expect(find.byType(InnkeeperPanelScreen), findsOneWidget);
    });
  });
}
