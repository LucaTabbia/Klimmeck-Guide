import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/generate_quests_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fixtures/mission_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';
import '../../helpers/fixtures/quest_result_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

final DateTime _now = DateTime.utc(2026, 10, 29, 12);

const TeleportTarget _beaTarget = TeleportTarget(
  characterId: 'char-bea',
  name: 'Bea',
  location: PointOfInterest(
    id: 'poi-bea',
    type: null,
    location: null,
    city: null,
  ),
  sex: SexType.female,
);

/// Chiave della carta di una story: la sua richiesta, non la quest.
const String _storyCardKey = 'pq-story-1';

List<PendingRequest> _queue(List<Map<String, dynamic>> entries) =>
    List.unmodifiable(entries.map(PendingRequest.fromJson));

typedef _CompletionOpener =
    Future<CompletionExit?> Function(BuildContext context, RequestCard card);

ElevatedButton _completeButton(WidgetTester tester, String questId) =>
    tester.widget<ElevatedButton>(
      find.byKey(RequestCardView.completeKeyFor(questId)),
    );

Finder _teleportAction(String cardKey) =>
    find.byKey(RequestCardView.teleportKeyFor(cardKey));

TextButton _teleportButton(WidgetTester tester, String cardKey) =>
    tester.widget<TextButton>(_teleportAction(cardKey));

/// Repository letto dal wizard vero (D-28): bozza servita o assente.
MockInnkeeperRepository _wizardRepository({MissionDraft? draft}) {
  final repository = MockInnkeeperRepository();
  when(() => repository.readMissionDraft(any())).thenAnswer((_) async => draft);
  when(
    () => repository.readCharacter(any()),
  ).thenAnswer((_) async => Character.fromJson(participantCharacterJson()));
  when(
    () => repository.listPointsOfInterest(),
  ).thenAnswer((_) async => const []);
  when(
    () => repository.listMissionEnemies(any(), showAll: any(named: 'showAll')),
  ).thenAnswer((_) async => const []);
  return repository;
}

/// Bozza della story di [pendingRequestJson] ferma al passo [step].
MissionDraft _storyDraftAt(String step) => MissionDraft.tryFromJson(
  missionDraftJson(
    quest: storyQuestId,
    questType: 'story',
    step: step,
    participants: [missionParticipantJson(pendingQuest: _storyCardKey)],
  ),
)!;

void main() {
  setUpAll(() => registerFallbackValue(<String>[]));

  late MockPendingRequestsCubit cubit;
  late MockAuthCubit authCubit;
  late MockTeleportModeCubit teleportCubit;
  late StreamController<TeleportModeState> teleportStates;
  late MockQuestGenerationCubit generationCubit;
  late StreamController<QuestGenerationState> generationStates;

  setUp(() {
    generationCubit = MockQuestGenerationCubit();
    generationStates = StreamController<QuestGenerationState>.broadcast();
    addTearDown(generationStates.close);
    whenListen(
      generationCubit,
      generationStates.stream,
      initialState: const QuestGenerationIdle(),
    );
    when(() => generationCubit.generate()).thenAnswer((_) async {});
    when(() => generationCubit.isClosed).thenReturn(false);
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
        companionIds: any(named: 'companionIds'),
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
    _CompletionOpener? openCompletion,
    InnkeeperRepository? repository,
    Stream<PendingRequestsState> states = const Stream.empty(),
    QuestGenerationState generationState = const QuestGenerationIdle(),
    String? resumeCardKey,
  }) async {
    useLandscapePhone(tester);
    whenListen(cubit, states, initialState: state);
    if (generationState != const QuestGenerationIdle()) {
      whenListen(
        generationCubit,
        generationStates.stream,
        initialState: generationState,
      );
    }
    final panel = MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<PendingRequestsCubit>.value(value: cubit),
        BlocProvider<TeleportModeCubit>.value(value: teleportCubit),
        BlocProvider<QuestGenerationCubit>.value(value: generationCubit),
      ],
      child: openCompletion == null
          ? InnkeeperPanelScreen(resumeCardKey: resumeCardKey)
          : InnkeeperPanelScreen(
              openCompletion: openCompletion,
              resumeCardKey: resumeCardKey,
            ),
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
    _CompletionOpener? openCompletion,
    InnkeeperRepository? repository,
    Stream<PendingRequestsState> states = const Stream.empty(),
  }) => pumpPanel(
    tester,
    PendingRequestsState(
      serverNow: serverNow ?? _now,
      requests: _queue(entries),
      isLoaded: true,
    ),
    openCompletion: openCompletion,
    repository: repository,
    states: states,
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

    expect(find.byKey(RequestCardView.keyFor(_storyCardKey)), findsOneWidget);
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
            of: find.byKey(RequestCardView.keyFor(_storyCardKey)),
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
    expect(find.text('2/2 posti'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
    expect(find.text('Cosimo'), findsOneWidget);
    expect(find.textContaining('registrati'), findsNothing);
  });

  testWidgets('a worldMission with a busy participant is not listed', (
    tester,
  ) async {
    await pumpQueue(
      tester,
      worldMissionEntriesJson(
        names: ['Bea', 'Cosimo', 'Dario'],
        requiredAdventurers: const [
          {'title': null, 'count': 3},
        ],
        busyLanes: {'Dario': 'quest-standard-1'},
      ),
    );

    expect(find.text('Missione mondiale'), findsNothing);
    expect(find.textContaining('registrati'), findsNothing);
  });

  testWidgets('a worldMission with free seats is not listed', (tester) async {
    await pumpQueue(
      tester,
      worldMissionEntriesJson(
        requiredAdventurers: const [
          {'title': null, 'count': 3},
        ],
      ),
    );

    expect(find.text('Missione mondiale'), findsNothing);
    expect(find.textContaining('posti'), findsNothing);
  });

  testWidgets('a travelling participant hides its card until arrival', (
    tester,
  ) async {
    await pumpQueue(tester, [
      pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: _now.add(const Duration(minutes: 12)),
        ),
      ),
    ]);

    expect(find.byKey(RequestCardView.keyFor(_storyCardKey)), findsNothing);
    expect(find.textContaining('In viaggio'), findsNothing);
  });

  testWidgets('after endTime the traveller reads «Arrivato» and is listed', (
    tester,
  ) async {
    await pumpQueue(tester, [
      pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: _now.subtract(const Duration(seconds: 1)),
        ),
      ),
    ]);

    expect(find.byKey(RequestCardView.keyFor(_storyCardKey)), findsOneWidget);
    expect(find.text('Arrivato'), findsOneWidget);
  });

  group('«Completa»', () {
    final completeStory = find.byKey(
      RequestCardView.completeKeyFor(_storyCardKey),
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
      expect(_completeButton(tester, _storyCardKey).onPressed, isNotNull);
    });

    testWidgets('a traveller before endTime hides the card', (tester) async {
      await pumpQueue(tester, [pendingRequestJson(activeTravel: travel)]);

      expect(completeStory, findsNothing);
    });

    testWidgets('the same traveller after endTime enables it', (tester) async {
      await pumpQueue(tester, [
        pendingRequestJson(activeTravel: travel),
      ], serverNow: _now.add(const Duration(minutes: 13)));

      expect(_completeButton(tester, _storyCardKey).onPressed, isNotNull);
    });

    testWidgets('a hidden busy participant hides the card', (tester) async {
      await pumpQueue(
        tester,
        worldMissionEntriesJson(
          names: ['Bea', 'Cosimo', 'Dario'],
          requiredAdventurers: const [
            {'title': null, 'count': 3},
          ],
          busyLanes: {'Dario': 'quest-standard-1'},
        ),
      );

      expect(
        find.byKey(RequestCardView.completeKeyFor(worldMissionQuestId)),
        findsNothing,
      );
    });

    testWidgets('tapping «Completa» opens the mission wizard (D-25, D-28)', (
      tester,
    ) async {
      final repository = _wizardRepository();
      await pumpQueue(tester, [pendingRequestJson()], repository: repository);

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      expect(find.byType(MissionCompletionScreen), findsOneWidget);
      expect(find.byKey(MissionCompletionScreen.startKey), findsOneWidget);
      verify(() => repository.readMissionDraft(_storyCardKey)).called(1);
    });

    testWidgets('a failed teleport read under the wizard shows its notice once '
        '(D-28)', (tester) async {
      await pumpQueue(tester, [
        pendingRequestJson(),
      ], repository: _wizardRepository(draft: _storyDraftAt('teleport')));
      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      teleportStates.add(
        const TeleportPreparationFailed(
          characterId: 'char-aldo',
          failure: InnkeeperFailure.connection,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      final notice = find.text(InnkeeperPanelScreen.teleportUnavailableMessage);
      expect(notice, findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(notice, findsNothing);
      expect(find.byType(MissionCompletionScreen), findsOneWidget);
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

      verify(() => cubit.markCompleted(_storyCardKey)).called(1);
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

    testWidgets('completing the last card still shows the results', (
      tester,
    ) async {
      final states = StreamController<PendingRequestsState>();
      addTearDown(states.close);
      final exit = Completer<CompletionExit?>();
      final results = [
        QuestResult.fromJson(
          questResultJson(character: 'char-aldo', outcome: 'gmCompleted'),
        ),
      ];
      await pumpQueue(
        tester,
        [pendingRequestJson()],
        openCompletion: (_, _) => exit.future,
        states: states.stream,
      );

      await tester.tap(completeStory);
      await tester.pump();
      states.add(
        PendingRequestsState(serverNow: _now, requests: [], isLoaded: true),
      );
      await tester.pump();
      expect(find.text(InnkeeperPanelScreen.emptyTitle), findsOneWidget);
      exit.complete(CompletionCompleted(results));
      await tester.pumpAndSettle();

      verify(() => cubit.markCompleted(_storyCardKey)).called(1);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Richiesta completata'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a vanished request is removed and the queue refetched', (
      tester,
    ) async {
      await pumpQueue(tester, [
        pendingRequestJson(),
      ], openCompletion: exitWith(const CompletionGone()));

      await tester.tap(completeStory);
      await tester.pumpAndSettle();

      verify(() => cubit.markCompleted(_storyCardKey)).called(1);
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
                        BlocProvider<QuestGenerationCubit>.value(
                          value: generationCubit,
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

  group('draft label (Phase 21)', () {
    Text completeLabel(WidgetTester tester) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(RequestCardView.completeKeyFor(_storyCardKey)),
        matching: find.byType(Text),
      ),
    );

    testWidgets('a card with a started draft reads «Riprendi» (D-17)', (
      tester,
    ) async {
      await pumpQueue(tester, [
        pendingRequestJson()
          ..['missionDraftStartedAt'] = '2026-11-14T10:00:00.000Z',
      ]);

      expect(completeLabel(tester).data, RequestCardView.resumeLabel);
      expect(completeLabel(tester).data, 'Riprendi');
    });

    testWidgets('a card with a started draft reads «Riprendi» and opens the '
        'wizard at the served step (D-17, D-28)', (tester) async {
      await pumpQueue(tester, [
        pendingRequestJson()
          ..['missionDraftStartedAt'] = '2026-11-14T10:00:00.000Z',
      ], repository: _wizardRepository(draft: _storyDraftAt('fights')));
      expect(completeLabel(tester).data, RequestCardView.resumeLabel);

      await tester.tap(
        find.byKey(RequestCardView.completeKeyFor(_storyCardKey)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MissionCompletionScreen), findsOneWidget);
      expect(find.text(MissionCompletionScreen.encountersTitle), findsWidgets);
      expect(find.byKey(MissionCompletionScreen.startKey), findsNothing);
    });

    testWidgets('a card without a draft reads «Completa»', (tester) async {
      await pumpQueue(tester, [pendingRequestJson()]);

      expect(completeLabel(tester).data, RequestCardView.completeLabel);
      expect(completeLabel(tester).data, 'Completa');
    });
  });

  group('resume after the Map (Phase 21)', () {
    late List<RequestCard> opened;
    late StreamController<PendingRequestsState> snapshots;

    setUp(() {
      opened = [];
      snapshots = StreamController<PendingRequestsState>.broadcast();
      addTearDown(snapshots.close);
      when(() => cubit.refetch()).thenAnswer((_) async {});
    });

    Future<CompletionExit?> recordOpening(BuildContext _, RequestCard card) {
      opened.add(card);
      return Future.value();
    }

    PendingRequestsState loaded(
      List<Map<String, dynamic>> entries, {
      DateTime? serverNow,
    }) => PendingRequestsState(
      serverNow: serverNow ?? _now,
      requests: _queue(entries),
      isLoaded: true,
    );

    Future<void> pumpResuming(WidgetTester tester, String? resumeCardKey) =>
        pumpPanel(
          tester,
          PendingRequestsState(serverNow: _now),
          openCompletion: recordOpening,
          states: snapshots.stream,
          resumeCardKey: resumeCardKey,
        );

    Future<void> emitSnapshot(
      WidgetTester tester,
      PendingRequestsState state,
    ) async {
      snapshots.add(state);
      await tester.pumpAndSettle();
    }

    testWidgets('opens the completion of the resumed card after the first '
        'snapshot (D-28, Pitfall 1)', (tester) async {
      await pumpResuming(tester, _storyCardKey);
      expect(opened, isEmpty);

      await emitSnapshot(tester, loaded([pendingRequestJson()]));

      expect(opened.map((card) => card.cardKey), [_storyCardKey]);
    });

    testWidgets('opens it only once across later snapshots (D-28)', (
      tester,
    ) async {
      await pumpResuming(tester, _storyCardKey);

      await emitSnapshot(tester, loaded([pendingRequestJson()]));
      await emitSnapshot(
        tester,
        loaded([
          pendingRequestJson(),
        ], serverNow: _now.add(const Duration(minutes: 1))),
      );

      expect(opened, hasLength(1));
    });

    testWidgets('finds a card that is not actionable in the raw requests '
        '(D-28, Pitfall 5)', (tester) async {
      await pumpResuming(tester, worldMissionQuestId);

      await emitSnapshot(
        tester,
        loaded(
          worldMissionEntriesJson(
            travels: {
              'Cosimo': queuedTravelJson(
                endTime: _now.add(const Duration(minutes: 12)),
              ),
            },
          ),
        ),
      );

      expect(opened.map((card) => card.cardKey), [worldMissionQuestId]);
      expect(
        find.byKey(RequestCardView.keyFor(worldMissionQuestId)),
        findsNothing,
      );
    });

    testWidgets('a card gone from the queue shows «Richiesta non più '
        'disponibile» (D-28)', (tester) async {
      await pumpResuming(tester, 'quest-gone');

      await emitSnapshot(tester, loaded([pendingRequestJson()]));

      expect(opened, isEmpty);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(InnkeeperPanelScreen.goneMessage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the resume after the Map opens the mission wizard (D-28)', (
      tester,
    ) async {
      final repository = _wizardRepository(draft: _storyDraftAt('teleport'));
      await pumpPanel(
        tester,
        PendingRequestsState(serverNow: _now),
        repository: repository,
        states: snapshots.stream,
        resumeCardKey: _storyCardKey,
      );

      await emitSnapshot(tester, loaded([pendingRequestJson()]));

      expect(find.byType(MissionCompletionScreen), findsOneWidget);
      expect(find.text(MissionCompletionScreen.placeTitle), findsWidgets);
      verify(() => repository.readMissionDraft(_storyCardKey)).called(1);
    });

    testWidgets('without a resume key nothing opens (PQ7)', (tester) async {
      await pumpResuming(tester, null);

      await emitSnapshot(tester, loaded([pendingRequestJson()]));

      expect(opened, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('«Teletrasporta» (10-CONTEXT D-15/D-19)', () {
    testWidgets('a listed card has one action, never its rows', (tester) async {
      await pumpQueue(
        tester,
        worldMissionEntriesJson(
          names: ['Bea', 'Cosimo', 'Dario'],
          requiredAdventurers: const [
            {'title': null, 'count': 3},
          ],
          travels: {
            'Dario': queuedTravelJson(
              endTime: _now.subtract(const Duration(seconds: 1)),
            ),
          },
        ),
      );

      expect(_teleportAction(worldMissionQuestId), findsOneWidget);
      expect(_teleportButton(tester, worldMissionQuestId).onPressed, isNotNull);
      expect(find.text(RequestCardView.teleportLabel), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('an awaiting-aid participant hides the card', (tester) async {
      await pumpQueue(tester, [
        pendingRequestJson(awaitingAid: awaitingAidJson()),
      ]);

      expect(_teleportAction(_storyCardKey), findsNothing);
      expect(find.text('In attesa di soccorso'), findsNothing);
    });

    testWidgets('tapping it reads the first participant with the companions', (
      tester,
    ) async {
      await pumpQueue(tester, worldMissionEntriesJson());

      await tester.tap(_teleportAction(worldMissionQuestId));
      await tester.pump();

      final companions = verify(
        () => teleportCubit.prepare(
          characterId: 'char-bea',
          name: 'Bea',
          companionIds: captureAny(named: 'companionIds'),
        ),
      ).captured;
      expect(companions, [
        ['char-cosimo'],
      ]);
    });

    testWidgets('the read shows a progress on its card and locks the others', (
      tester,
    ) async {
      whenListen(
        teleportCubit,
        teleportStates.stream,
        initialState: const TeleportPreparing(characterId: 'char-bea'),
      );
      await pumpQueue(tester, [
        pendingRequestJson(),
        ...worldMissionEntriesJson(),
      ]);

      expect(
        find.descendant(
          of: find.byKey(RequestCardView.keyFor(worldMissionQuestId)),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(_teleportAction(worldMissionQuestId), findsNothing);
      expect(_teleportButton(tester, _storyCardKey).onPressed, isNull);
    });

    // il progresso della lettura gira per sempre: niente pumpAndSettle
    Future<void> settleRoute(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> pushPanel(
      WidgetTester tester,
      TeleportModeState teleportState,
    ) async {
      useLandscapePhone(tester);
      whenListen(
        teleportCubit,
        teleportStates.stream,
        initialState: teleportState,
      );
      whenListen(
        cubit,
        const Stream<PendingRequestsState>.empty(),
        initialState: PendingRequestsState(
          serverNow: _now,
          requests: _queue(worldMissionEntriesJson()),
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
                        BlocProvider<QuestGenerationCubit>.value(
                          value: generationCubit,
                        ),
                      ],
                      child: const InnkeeperPanelScreen(),
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
      await settleRoute(tester);
    }

    testWidgets('leaving the panel during the read cancels it', (tester) async {
      await pushPanel(tester, const TeleportPreparing(characterId: 'char-bea'));

      await tester.binding.handlePopRoute();
      await settleRoute(tester);

      expect(find.byType(InnkeeperPanelScreen), findsNothing);
      verify(() => teleportCubit.cancel()).called(1);
    });

    testWidgets('the landing pop of an active mode keeps it', (tester) async {
      await pushPanel(tester, const TeleportActive(target: _beaTarget));

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .popUntil((route) => route.isFirst);
      await tester.pumpAndSettle();

      expect(find.byType(InnkeeperPanelScreen), findsNothing);
      verifyNever(() => teleportCubit.cancel());
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

  group('«Genera missioni» (D-08..D-10, D-14)', () {
    final generateButton = find.byKey(GenerateQuestsButton.buttonKey);

    DestructiveConfirmationDialog confirmation(WidgetTester tester) =>
        tester.widget<DestructiveConfirmationDialog>(
          find.byType(DestructiveConfirmationDialog),
        );

    testWidgets('shows the button while the queue loads (D-08, D-14)', (
      tester,
    ) async {
      await pumpPanel(tester, PendingRequestsState(serverNow: _now));

      expect(generateButton, findsOneWidget);
      expect(find.byType(KGLoader), findsOneWidget);
    });

    testWidgets('shows the button above the empty queue (D-08)', (
      tester,
    ) async {
      await pumpQueue(tester, []);

      expect(generateButton, findsOneWidget);
      expect(find.text(InnkeeperPanelScreen.emptyTitle), findsOneWidget);
      expect(
        tester.getTopLeft(generateButton).dy,
        lessThan(
          tester.getTopLeft(find.text(InnkeeperPanelScreen.emptyTitle)).dy,
        ),
      );
    });

    testWidgets('sits above the first request card (D-08)', (tester) async {
      await pumpQueue(tester, [pendingRequestJson()]);

      expect(
        tester.getTopLeft(generateButton).dy,
        lessThan(tester.getTopLeft(find.byType(RequestCardView).first).dy),
      );
    });

    testWidgets('asks for confirmation in the neutral style (D-09)', (
      tester,
    ) async {
      await pumpQueue(tester, []);

      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      final dialog = confirmation(tester);
      expect(dialog.title, 'Genera missioni');
      expect(dialog.body, 'Generare nuove missioni nel mondo?');
      expect(dialog.confirmLabel, 'Genera');
      expect(
        dialog.confirmButtonStyle,
        same(KlimmeckGuideTheme.primaryButtonStyle),
      );
    });

    testWidgets('«Annulla» sends nothing (D-09)', (tester) async {
      await pumpQueue(tester, []);

      await tester.tap(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      verifyNever(() => generationCubit.generate());
      expect(find.byType(DestructiveConfirmationDialog), findsNothing);
    });

    testWidgets('«Genera» runs one generation (D-09)', (tester) async {
      await pumpQueue(tester, []);

      await tester.tap(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Genera'));
      await tester.pumpAndSettle();

      verify(() => generationCubit.generate()).called(1);
    });

    testWidgets('the button is disabled while generating (D-09)', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        PendingRequestsState(
          serverNow: _now,
          requests: const [],
          isLoaded: true,
        ),
        generationState: const QuestGenerationSubmitting(),
      );

      expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNull);
    });

    Future<void> emitGeneration(
      WidgetTester tester,
      List<QuestGenerationState> states,
    ) async {
      for (final state in states) {
        generationStates.add(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Finder snackText(String message) => find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(message),
    );

    testWidgets('a success shows «Generate N missioni» (D-09)', (tester) async {
      await pumpQueue(tester, []);

      await emitGeneration(tester, const [
        QuestGenerationSubmitting(),
        QuestGenerationSucceeded(created: 3),
      ]);

      expect(snackText('Generate 3 missioni'), findsOneWidget);
    });

    testWidgets('one created quest reads «Generata 1 missione» (D-09)', (
      tester,
    ) async {
      await pumpQueue(tester, []);

      await emitGeneration(tester, const [
        QuestGenerationSubmitting(),
        QuestGenerationSucceeded(created: 1),
      ]);

      expect(snackText('Generata 1 missione'), findsOneWidget);
    });

    testWidgets('zero created shows «Nessuna missione da generare» (D-09)', (
      tester,
    ) async {
      await pumpQueue(tester, []);

      await emitGeneration(tester, const [
        QuestGenerationSubmitting(),
        QuestGenerationSucceeded(created: 0),
      ]);

      expect(snackText('Nessuna missione da generare'), findsOneWidget);
    });

    for (final failure in [
      InnkeeperFailure.connection,
      InnkeeperFailure.timedOut,
      InnkeeperFailure.unknown,
      InnkeeperFailure.malformed,
    ]) {
      testWidgets(
        'a ${failure.name} failure shows the retry SnackBar and keeps the panel (D-09)',
        (tester) async {
          await pumpQueue(tester, []);

          await emitGeneration(tester, [
            const QuestGenerationSubmitting(),
            QuestGenerationFailed(failure: failure, serial: 1),
          ]);

          expect(
            snackText('Non è stato possibile generare le missioni. Riprova.'),
            findsOneWidget,
          );
          expect(find.byType(InnkeeperPanelScreen), findsOneWidget);
        },
      );
    }

    testWidgets('the same failure twice shows the SnackBar twice (D-10)', (
      tester,
    ) async {
      const retry = 'Non è stato possibile generare le missioni. Riprova.';
      await pumpQueue(tester, []);

      await emitGeneration(tester, const [
        QuestGenerationSubmitting(),
        QuestGenerationFailed(failure: InnkeeperFailure.connection, serial: 1),
      ]);
      expect(snackText(retry), findsOneWidget);

      await emitGeneration(tester, const [
        QuestGenerationSubmitting(),
        QuestGenerationFailed(failure: InnkeeperFailure.connection, serial: 2),
      ]);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(snackText(retry), findsOneWidget);
    });

    testWidgets(
      'FORBIDDEN closes the panel with «La Locanda non è disponibile» (D-09, D-14)',
      (tester) async {
        useLandscapePhone(tester);
        whenListen(
          cubit,
          const Stream<PendingRequestsState>.empty(),
          initialState: PendingRequestsState(
            serverNow: _now,
            requests: const [],
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
                          BlocProvider<PendingRequestsCubit>.value(
                            value: cubit,
                          ),
                          BlocProvider<TeleportModeCubit>.value(
                            value: teleportCubit,
                          ),
                          BlocProvider<QuestGenerationCubit>.value(
                            value: generationCubit,
                          ),
                        ],
                        child: const InnkeeperPanelScreen(),
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

        await emitGeneration(tester, const [
          QuestGenerationSubmitting(),
          QuestGenerationFailed(failure: InnkeeperFailure.forbidden, serial: 1),
        ]);

        expect(find.byType(InnkeeperPanelScreen), findsNothing);
        expect(
          find.text(InnkeeperPanelScreen.unavailableMessage),
          findsOneWidget,
        );
      },
    );
  });
}
