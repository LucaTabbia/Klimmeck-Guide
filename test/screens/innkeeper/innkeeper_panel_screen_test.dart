import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/generate_quests_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
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
    quest: null,
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
    _CompletionOpener openCompletion = openRequestCompletion,
    InnkeeperRepository? repository,
    Stream<PendingRequestsState> states = const Stream.empty(),
    QuestGenerationState generationState = const QuestGenerationIdle(),
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
  });
}
