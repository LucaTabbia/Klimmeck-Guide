import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/stories_step.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/encounters_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/enemy_search_bar.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/correction_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/additions_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/fight_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/place_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/recap_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/mission_fixtures.dart';
import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';
const String _ruins = 'poi-ruins-1';
const String _scar = 'Porta una cicatrice sul volto.';
const String _typed = 'Ha salvato il villaggio.';

final DateTime _now = DateTime.utc(2026, 11, 14, 12);

final List<PendingRequest> _entries = worldMissionEntriesJson(
  names: const ['Aldo', 'Bea'],
).map(PendingRequest.fromJson).toList();

final RequestCard _card = requestCardsOf(_entries).single;

MissionDraft _draftAt(
  String step, {
  List<Map<String, dynamic>> fights = const [],
  Map<String, String> additions = const {},
}) => MissionDraft.tryFromJson(
  missionDraftJson(
    step: step,
    fights: fights,
    backgroundAdditions: [
      for (final MapEntry(:key, :value) in additions.entries)
        {'character': key, 'text': value},
    ],
    participants: [
      missionParticipantJson(),
      missionParticipantJson(
        character: _bea,
        name: 'Bea',
        pendingQuest: 'pq-world-2',
      ),
    ],
  ),
)!;

final MissionDraftReady _ready = MissionDraftReady(draft: _draftAt('teleport'));

/// Scontro simulato con gli esiti di Aldo e Bea.
Map<String, dynamic> _simulatedFight() => missionFightJson(
  verdict: 'success',
  outcomes: [
    missionOutcomeJson(simulated: missionEffectsJson()),
    missionOutcomeJson(character: _bea, simulated: missionEffectsJson()),
  ],
);

/// Due scontri serviti, nessuno simulato.
final MissionDraftReady _twoFightsReady = MissionDraftReady(
  draft: _draftAt('fights', fights: [missionFightJson(), missionFightJson()]),
);

final List<QuestResult> _results = [
  QuestResult.fromJson(questResultJson(id: 'result-aldo', character: _aldo)),
];

/// «Passo k di N · titolo» della pagina: il conto segue le pagine
/// raggiungibili, l'ultima esiste solo con le aggiunte accese.
String _header(MissionPage page, String title, {bool withAdditions = false}) {
  final pageCount = MissionPage.values.length - (withAdditions ? 0 : 1);
  return 'Passo ${page.index + 1} di $pageCount · $title';
}

Finder _headerOf(
  MissionPage page,
  String title, {
  bool withAdditions = false,
}) => find.text(_header(page, title, withAdditions: withAdditions));

Finder get _discardConfirm => find.descendant(
  of: find.byType(DestructiveConfirmationDialog),
  matching: find.widgetWithText(ElevatedButton, 'Scarta la bozza'),
);

void main() {
  late MockMissionDraftCubit draftCubit;
  late MockMissionParticipantsCubit participantsCubit;
  late MockMissionEnemiesCubit enemiesCubit;
  late MockMissionPrizeOptionsCubit prizeOptionsCubit;
  late MockPendingRequestsCubit queue;
  late MockTeleportModeCubit teleport;
  late StreamController<MissionDraftState> draftStates;
  late StreamController<PendingRequestsState> queueStates;
  late StreamController<TeleportModeState> teleportStates;

  setUpAll(() => registerFallbackValue(MissionDraftStep.fights));

  setUp(() {
    draftCubit = MockMissionDraftCubit();
    participantsCubit = MockMissionParticipantsCubit();
    enemiesCubit = MockMissionEnemiesCubit();
    prizeOptionsCubit = MockMissionPrizeOptionsCubit();
    queue = MockPendingRequestsCubit();
    teleport = MockTeleportModeCubit();
    draftStates = StreamController<MissionDraftState>.broadcast();
    queueStates = StreamController<PendingRequestsState>.broadcast();
    teleportStates = StreamController<TeleportModeState>.broadcast();
    when(() => draftCubit.load()).thenAnswer((_) async {});
    when(() => draftCubit.start()).thenAnswer((_) async {});
    when(() => draftCubit.discard()).thenAnswer((_) async {});
    when(() => participantsCubit.load(any())).thenAnswer((_) async {});
    when(() => participantsCubit.ensureLoaded(any())).thenAnswer((_) async {});
    when(() => enemiesCubit.load()).thenAnswer((_) async {});
    when(() => prizeOptionsCubit.loadAll(any())).thenAnswer((_) async {});
    whenListen(
      prizeOptionsCubit,
      const Stream<MissionPrizeOptionsState>.empty(),
      initialState: const MissionPrizeOptionsState(),
    );
    whenListen(
      enemiesCubit,
      const Stream<MissionEnemiesState>.empty(),
      initialState: const MissionEnemiesState(),
    );
    whenListen(
      participantsCubit,
      const Stream<MissionParticipantsState>.empty(),
      initialState: const MissionParticipantsIdle(),
    );
    whenListen(
      queue,
      queueStates.stream,
      initialState: PendingRequestsState(
        serverNow: _now,
        requests: _entries,
        isLoaded: true,
      ),
    );
    whenListen(
      teleport,
      teleportStates.stream,
      initialState: const TeleportIdle(),
    );
  });

  tearDown(() async {
    await draftStates.close();
    await queueStates.close();
    await teleportStates.close();
  });

  Future<List<CompletionExit?>> openWizard(
    WidgetTester tester,
    MissionDraftState initial, {
    bool opensAtPlace = false,
    bool isStoryAndWoundInputEnabled = false,
  }) async {
    useLandscapePhone(tester);
    seedSvgCache([CloudinaryAssets.arrowDown]);
    whenListen(draftCubit, draftStates.stream, initialState: initial);
    final exits = <CompletionExit?>[];
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => exits.add(
                await Navigator.of(context).push<CompletionExit>(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<PendingRequestsCubit>.value(value: queue),
                        BlocProvider<TeleportModeCubit>.value(value: teleport),
                        BlocProvider<MissionDraftCubit>.value(
                          value: draftCubit,
                        ),
                        BlocProvider<MissionParticipantsCubit>.value(
                          value: participantsCubit,
                        ),
                        BlocProvider<MissionEnemiesCubit>.value(
                          value: enemiesCubit,
                        ),
                        BlocProvider<MissionPrizeOptionsCubit>.value(
                          value: prizeOptionsCubit,
                        ),
                      ],
                      child: MissionCompletionScreen(
                        card: _card,
                        opensAtPlace: opensAtPlace,
                        isStoryAndWoundInputEnabled:
                            isStoryAndWoundInputEnabled,
                      ),
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
    return exits;
  }

  Future<void> emitDraft(WidgetTester tester, MissionDraftState state) async {
    draftStates.add(state);
    await tester.pumpAndSettle();
  }

  group('start and resume', () {
    testWidgets(
      "an absent draft opens the stories of the card's participants and never starts the mission (D-02, D-28)",
      (tester) async {
        await openWizard(tester, const MissionDraftLoading());

        expect(find.byType(KGLoader), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.startKey), findsNothing);

        await emitDraft(tester, const MissionDraftAbsent());

        expect(find.text('Passo 1 di 6 · Storie'), findsOneWidget);
        expect(_headerOf(MissionPage.stories, 'Storie'), findsOneWidget);
        expect(find.byType(Dropdown), findsNWidgets(2));
        expect(find.byKey(ParticipantStory.keyFor(_aldo)), findsOneWidget);
        expect(find.byKey(ParticipantStory.keyFor(_bea)), findsOneWidget);
        expect(find.text('Aldo'), findsOneWidget);
        expect(find.text('Bea'), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.startKey), findsOneWidget);
        expect(find.text(MissionCompletionScreen.startNote), findsOneWidget);
        expect(find.text(MissionCompletionScreen.title), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.discardKey), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        verifyNever(() => draftCubit.start());
      },
    );

    testWidgets(
      "the stories are read with the card's ids while the draft is absent (D-02)",
      (tester) async {
        await openWizard(tester, const MissionDraftAbsent());

        verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
        verifyNever(() => participantsCubit.load(any()));
        verifyNever(() => draftCubit.start());
      },
    );

    testWidgets(
      "a draft found absent after the load reads the stories with the card's ids (D-02)",
      (tester) async {
        await openWizard(tester, const MissionDraftLoading());
        verifyNever(() => participantsCubit.ensureLoaded(any()));

        await emitDraft(tester, const MissionDraftAbsent());
        await emitDraft(tester, const MissionDraftAbsent(isStarting: true));

        verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
      },
    );

    testWidgets(
      'the rank of a card participant follows the name once its character is read (D-03)',
      (tester) async {
        final aldo = participantCharacterJson();
        whenListen(
          participantsCubit,
          const Stream<MissionParticipantsState>.empty(),
          initialState: MissionParticipantsLoaded(
            characters: {
              _aldo: Character.fromJson({
                ...aldo,
                'status': {
                  ...aldo['status'] as Map<String, dynamic>,
                  'title': TitleType.adventurer.name,
                },
              }),
            },
            places: const {},
          ),
        );
        await openWizard(tester, const MissionDraftAbsent());

        expect(find.text('Aldo · Avventuriero'), findsOneWidget);
        expect(find.text('Bea'), findsOneWidget);
      },
    );

    testWidgets(
      '«Inizia la missione» starts the draft once and lands on «Luogo» (D-02, D-28)',
      (tester) async {
        await openWizard(tester, const MissionDraftAbsent());

        await tester.tap(find.byKey(MissionCompletionScreen.startKey));
        await tester.pump();
        verify(() => draftCubit.start()).called(1);
        await emitDraft(tester, _ready);

        expect(find.text('Passo 2 di 6 · Luogo'), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.startKey), findsNothing);
      },
    );

    testWidgets(
      "the participants are asked once more with the draft's ids after the start, through ensureLoaded (no forced reread)",
      (tester) async {
        await openWizard(tester, const MissionDraftAbsent());

        await tester.tap(find.byKey(MissionCompletionScreen.startKey));
        await emitDraft(tester, _ready);

        verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(2);
        verifyNever(() => participantsCubit.load(any()));
      },
    );

    testWidgets('while the start is in flight the button is disabled and the '
        'stories stay readable (D-28)', (tester) async {
      await openWizard(tester, const MissionDraftAbsent(isStarting: true));

      final start = tester.widget<ElevatedButton>(
        find.byKey(MissionCompletionScreen.startKey),
      );
      expect(start.onPressed, isNull);
      expect(find.byType(Dropdown), findsNWidgets(2));
    });

    testWidgets(
      'a failed read on the stories keeps «Inizia la missione» enabled and «Riprova» reads again (D-31)',
      (tester) async {
        whenListen(
          participantsCubit,
          const Stream<MissionParticipantsState>.empty(),
          initialState: const MissionParticipantsFailed(
            failure: InnkeeperFailure.timedOut,
          ),
        );
        await openWizard(tester, const MissionDraftAbsent());

        final start = tester.widget<ElevatedButton>(
          find.byKey(MissionCompletionScreen.startKey),
        );
        expect(start.onPressed, isNotNull);
        expect(
          find.text(MissionCompletionScreen.genericMessage),
          findsNWidgets(3),
        );

        await tester.tap(find.byKey(StoriesStep.retryKey));
        await tester.pump();

        verify(() => participantsCubit.load([_aldo, _bea])).called(1);
        verifyNever(() => draftCubit.start());
      },
    );

    testWidgets('a refused start stays on the stories with the failure line', (
      tester,
    ) async {
      final exits = await openWizard(tester, const MissionDraftAbsent());

      await emitDraft(
        tester,
        const MissionDraftAbsent(
          failure: InnkeeperFailure.connection,
          failureSerial: 1,
        ),
      );

      expect(
        find.text(MissionCompletionScreen.connectionMessage),
        findsOneWidget,
      );
      expect(exits, isEmpty);
      expect(_headerOf(MissionPage.stories, 'Storie'), findsOneWidget);
      expect(find.byKey(MissionCompletionScreen.startKey), findsOneWidget);
    });

    testWidgets(
      'a served draft at step fights reopens on «Scontri» (D-09, D-18)',
      (tester) async {
        await openWizard(tester, const MissionDraftLoading());

        await emitDraft(tester, MissionDraftReady(draft: _draftAt('fights')));

        expect(_headerOf(MissionPage.encounters, 'Scontri'), findsOneWidget);
        verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
      },
    );

    for (final step in ['teleport', 'unknown']) {
      testWidgets('a served draft at step $step reopens on «Luogo» (D-18)', (
        tester,
      ) async {
        await openWizard(tester, const MissionDraftLoading());

        await emitDraft(tester, MissionDraftReady(draft: _draftAt(step)));

        expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
      });
    }

    testWidgets('a served draft at step prizes reopens on «Premi» (D-18)', (
      tester,
    ) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('prizes')));

      expect(_headerOf(MissionPage.prizes, 'Premi'), findsOneWidget);
      verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
    });

    testWidgets('a served draft at step recap reopens on «Riepilogo» (D-18)', (
      tester,
    ) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('recap')));

      expect(_headerOf(MissionPage.recap, 'Riepilogo'), findsOneWidget);
    });

    testWidgets('back from a cancelled teleport the wizard reopens on «Luogo» '
        'whatever the served step (UAT 2026-11-14)', (tester) async {
      await openWizard(
        tester,
        MissionDraftReady(draft: _draftAt('fights')),
        opensAtPlace: true,
      );

      expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
      verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
    });

    testWidgets('a later save never moves the page (D-18)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      await emitDraft(tester, MissionDraftReady(draft: _draftAt('recap')));

      expect(_headerOf(MissionPage.encounters, 'Scontri'), findsOneWidget);
    });

    testWidgets('a ready draft shows the leave note (D-09)', (tester) async {
      await openWizard(tester, _ready);

      expect(find.text(MissionCompletionScreen.leaveNote), findsOneWidget);
      expect(find.byKey(MissionCompletionScreen.discardKey), findsOneWidget);
    });

    testWidgets('«Scontri» puts the enemy search beside the step counter and '
        'drops the leave note (UAT 2026-11-14)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      final header = tester.getRect(
        _headerOf(MissionPage.encounters, 'Scontri'),
      );
      final search = tester.getRect(find.byKey(EnemySearchBar.searchKey));
      expect(search.left, greaterThan(header.right));
      expect(search.top, lessThan(header.bottom));
      expect(search.bottom, greaterThan(header.top));
      expect(find.text(MissionCompletionScreen.leaveNote), findsNothing);
    });

    testWidgets('«Indietro» sits on the same row as the other buttons of the '
        'page, at the bottom (UAT 2026-11-14)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      final back = tester.getRect(find.byKey(MissionCompletionScreen.backKey));
      final next = tester.getRect(find.byKey(MissionCompletionScreen.nextKey));
      final add = tester.getRect(find.byKey(EncountersStep.addFightKey));
      expect(back.center.dy, moreOrLessEquals(next.center.dy, epsilon: 1));
      expect(back.center.dy, moreOrLessEquals(add.center.dy, epsilon: 1));
      expect(back.left, lessThan(add.left));
    });

    testWidgets('the keyboard over «Scontri» never overflows the page '
        '(UAT 2026-11-14)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the keyboard over «Premi» hides the step counter and the '
        'buttons, without overflow (UAT 2026-11-14)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('prizes')));
      expect(_headerOf(MissionPage.prizes, 'Premi'), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 700);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(_headerOf(MissionPage.prizes, 'Premi'), findsNothing);
      expect(find.byKey(MissionCompletionScreen.nextKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the wizard buttons are written in the compact size '
        '(UAT 2026-11-14)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      for (final label in [
        MissionCompletionScreen.backLabel,
        MissionCompletionScreen.nextLabel,
        EncountersStep.addFightLabel,
      ]) {
        final style = DefaultTextStyle.of(
          tester.element(find.text(label)),
        ).style;
        expect(style.fontSize, KlimmeckGuideTheme.mapNoticeFontSize);
      }
    });

    testWidgets(
      '«Indietro» is disabled on the stories and enabled on «Luogo»',
      (tester) async {
        await openWizard(tester, _ready);

        OutlinedButton back() => tester.widget<OutlinedButton>(
          find.byKey(MissionCompletionScreen.backKey),
        );
        expect(back().onPressed, isNotNull);

        await tester.tap(find.byKey(MissionCompletionScreen.backKey));
        await tester.pumpAndSettle();

        expect(back().onPressed, isNull);
      },
    );

    testWidgets(
      '«Indietro» from «Luogo» shows the stories with «Avanti» (D-02)',
      (tester) async {
        await openWizard(tester, _ready);

        await tester.tap(find.byKey(MissionCompletionScreen.backKey));
        await tester.pumpAndSettle();

        expect(find.text('Passo 1 di 6 · Storie'), findsOneWidget);
        expect(find.byType(Dropdown), findsNWidgets(2));
        expect(find.text('Aldo · ${TitleType.paladin.label}'), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.nextKey), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.startKey), findsNothing);
        expect(find.text(MissionCompletionScreen.startNote), findsNothing);
        expect(find.text(MissionCompletionScreen.leaveNote), findsNothing);
        expect(find.byKey(MissionCompletionScreen.discardKey), findsOneWidget);
        verifyNever(() => draftCubit.start());
      },
    );

    testWidgets(
      '«Avanti» on the stories returns to «Luogo» without saving (D-02)',
      (tester) async {
        await openWizard(tester, _ready);
        await tester.tap(find.byKey(MissionCompletionScreen.backKey));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
        await tester.pumpAndSettle();

        expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
        verifyNever(
          () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
        );
        verifyNever(() => participantsCubit.load(any()));
      },
    );

    testWidgets(
      "«Riprova» on the stories of a started mission reads the draft's participants again (D-31)",
      (tester) async {
        whenListen(
          participantsCubit,
          const Stream<MissionParticipantsState>.empty(),
          initialState: const MissionParticipantsFailed(
            failure: InnkeeperFailure.timedOut,
          ),
        );
        await openWizard(tester, _ready);
        await tester.tap(find.byKey(MissionCompletionScreen.backKey));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(StoriesStep.retryKey));
        await tester.pump();

        verify(() => participantsCubit.load([_aldo, _bea])).called(1);
      },
    );

    testWidgets('«Indietro» goes back one page without a call (D-09)', (
      tester,
    ) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
      verifyNever(
        () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
      );
    });

    testWidgets('a load failure offers «Riprova» which loads again', (
      tester,
    ) async {
      final exits = await openWizard(tester, const MissionDraftLoading());

      await emitDraft(
        tester,
        const MissionDraftLoadFailed(failure: InnkeeperFailure.connection),
      );

      expect(exits, isEmpty);
      expect(
        find.text(MissionCompletionScreen.connectionMessage),
        findsOneWidget,
      );
      await tester.tap(find.byKey(MissionCompletionScreen.retryKey));
      await tester.pump();

      verify(() => draftCubit.load()).called(1);
    });
  });

  group('discard', () {
    testWidgets('«Scarta la bozza» confirms then discards (D-11)', (
      tester,
    ) async {
      await openWizard(tester, _ready);

      await tester.tap(find.byKey(MissionCompletionScreen.discardKey));
      await tester.pumpAndSettle();

      expect(find.text(MissionCompletionScreen.discardTitle), findsOneWidget);
      expect(find.text(MissionCompletionScreen.discardBody), findsOneWidget);
      await tester.tap(_discardConfirm);
      await tester.pumpAndSettle();

      verify(() => draftCubit.discard()).called(1);
    });

    testWidgets('cancelling «Scarta la bozza» discards nothing (D-11)', (
      tester,
    ) async {
      await openWizard(tester, _ready);

      await tester.tap(find.byKey(MissionCompletionScreen.discardKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      verifyNever(() => draftCubit.discard());
    });

    testWidgets('discarded leaves the wizard with no exit (D-11)', (
      tester,
    ) async {
      final exits = await openWizard(tester, _ready);

      await emitDraft(tester, const MissionDraftDiscarded());

      expect(exits, [null]);
      expect(find.byType(MissionCompletionScreen), findsNothing);
    });
  });

  group('exits', () {
    for (final (failure, exit) in [
      (InnkeeperFailure.notFound, const CompletionGone()),
      (InnkeeperFailure.questInProgress, const CompletionBusy()),
      (InnkeeperFailure.forbidden, const CompletionForbidden()),
    ]) {
      testWidgets('${failure.name} pops ${exit.runtimeType} (D-25)', (
        tester,
      ) async {
        final exits = await openWizard(tester, _ready);

        await emitDraft(
          tester,
          _ready.copyWith(failure: failure, failureSerial: 1),
        );

        expect(exits, [exit]);
      });
    }

    testWidgets('NOT_FOUND at start pops CompletionGone (D-25)', (
      tester,
    ) async {
      final exits = await openWizard(tester, const MissionDraftAbsent());

      await emitDraft(
        tester,
        const MissionDraftAbsent(
          failure: InnkeeperFailure.notFound,
          failureSerial: 1,
        ),
      );

      expect(exits, [const CompletionGone()]);
    });

    testWidgets('FORBIDDEN at open pops CompletionForbidden (D-25)', (
      tester,
    ) async {
      final exits = await openWizard(tester, const MissionDraftLoading());

      await emitDraft(
        tester,
        const MissionDraftLoadFailed(failure: InnkeeperFailure.forbidden),
      );

      expect(exits, [const CompletionForbidden()]);
    });

    testWidgets(
      'the request leaving the raw queue pops CompletionGone (Pitfall 5)',
      (tester) async {
        final exits = await openWizard(tester, _ready);

        queueStates.add(PendingRequestsState(serverNow: _now, isLoaded: true));
        await tester.pumpAndSettle();

        expect(exits, [const CompletionGone()]);
      },
    );

    testWidgets(
      'the queue losing the request while the completion is in flight '
      'waits for the results (UAT 2026-11-14)',
      (tester) async {
        final exits = await openWizard(
          tester,
          MissionDraftReady(draft: _draftAt('recap'), isSubmitting: true),
        );

        queueStates.add(PendingRequestsState(serverNow: _now, isLoaded: true));
        await tester.pump();
        expect(exits, isEmpty);

        draftStates.add(MissionDraftCompleted(results: _results));
        await tester.pumpAndSettle();

        expect(exits, [CompletionCompleted(_results)]);
      },
    );

    testWidgets('a request gone during a save pops CompletionGone once the '
        'save ends (UAT 2026-11-14)', (tester) async {
      final exits = await openWizard(
        tester,
        _ready.copyWith(isSubmitting: true),
      );

      queueStates.add(PendingRequestsState(serverNow: _now, isLoaded: true));
      await tester.pump();
      expect(exits, isEmpty);

      draftStates.add(_ready);
      await tester.pumpAndSettle();

      expect(exits, [const CompletionGone()]);
    });

    testWidgets(
      'a card only leaving the actionable list does not pop (Pitfall 5)',
      (tester) async {
        final exits = await openWizard(tester, _ready);

        queueStates.add(
          PendingRequestsState(
            serverNow: _now,
            requests: _entries,
            isLoaded: true,
            hiddenCardKeys: {_card.cardKey},
          ),
        );
        await tester.pumpAndSettle();

        expect(exits, isEmpty);
        expect(find.byType(MissionCompletionScreen), findsOneWidget);
      },
    );

    testWidgets('completed pops CompletionCompleted with the results (D-08)', (
      tester,
    ) async {
      final exits = await openWizard(tester, _ready);

      await emitDraft(tester, MissionDraftCompleted(results: _results));

      expect(exits, [CompletionCompleted(_results)]);
    });
  });

  group('failures that stay', () {
    test('an addition too long reads its own line (D-07)', () {
      expect(
        MissionCompletionScreen.failureLineOf(InnkeeperFailure.additionTooLong),
        MissionCompletionScreen.additionTooLongMessage,
      );
      expect(
        MissionCompletionScreen.additionTooLongMessage,
        "Un'aggiunta supera i 1000 caratteri",
      );
    });

    for (final (failure, line) in [
      (
        InnkeeperFailure.additionTooLong,
        MissionCompletionScreen.additionTooLongMessage,
      ),
      (
        InnkeeperFailure.overrideInvalid,
        MissionCompletionScreen.invalidValuesMessage,
      ),
      (
        InnkeeperFailure.notParticipant,
        MissionCompletionScreen.notParticipantMessage,
      ),
      (InnkeeperFailure.connection, MissionCompletionScreen.connectionMessage),
      (InnkeeperFailure.timedOut, MissionCompletionScreen.genericMessage),
    ]) {
      testWidgets(
        'a refused save (${failure.name}) shows «$line» and stays (D-14)',
        (tester) async {
          final exits = await openWizard(tester, _ready);

          await emitDraft(
            tester,
            _ready.copyWith(failure: failure, failureSerial: 1),
          );

          expect(find.text(line), findsOneWidget);
          expect(exits, isEmpty);
          expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'a refused wizard action names fights, corrections and prizes, not a form (D-24)',
      (tester) async {
        await openWizard(tester, _ready);

        await emitDraft(
          tester,
          _ready.copyWith(
            failure: InnkeeperFailure.overrideInvalid,
            failureSerial: 1,
          ),
        );

        expect(
          find.text(
            'Operazione rifiutata: controlla scontri, correzioni e premi',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('back is blocked while a call is in flight', (tester) async {
      await openWizard(tester, _ready.copyWith(isSubmitting: true));

      final scope = tester.widget<PopScope>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      expect(scope.canPop, isFalse);
    });

    testWidgets('back is allowed with no call in flight', (tester) async {
      await openWizard(tester, _ready);

      final scope = tester.widget<PopScope>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      expect(scope.canPop, isTrue);
    });

    testWidgets(
      'a failed teleport preparation shows the Locanda message (D-01)',
      (tester) async {
        await openWizard(tester, _ready);

        teleportStates.add(
          const TeleportPreparationFailed(
            characterId: _aldo,
            failure: InnkeeperFailure.connection,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(InnkeeperPanelScreen.teleportUnavailableMessage),
          findsOneWidget,
        );
      },
    );
  });

  group('place step (Phase 21)', () {
    setUp(() {
      when(
        () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
      ).thenAnswer((_) async {});
      when(
        () => teleport.prepare(
          characterId: any(named: 'characterId'),
          name: any(named: 'name'),
          companionIds: any(named: 'companionIds'),
          resumeCardKey: any(named: 'resumeCardKey'),
        ),
      ).thenAnswer((_) async {});
      whenListen(
        participantsCubit,
        const Stream<MissionParticipantsState>.empty(),
        initialState: MissionParticipantsLoaded(
          characters: {
            _aldo: Character.fromJson(
              participantCharacterJson(locationId: _ruins),
            ),
            _bea: Character.fromJson(
              participantCharacterJson(
                id: _bea,
                name: 'Bea',
                locationId: _ruins,
              ),
            ),
          },
          places: {_ruins: PointOfInterest.fromJson(pointOfInterestJson())},
        ),
      );
    });

    testWidgets('«Luogo» names the place of each participant (D-29)', (
      tester,
    ) async {
      await openWizard(tester, _ready);

      expect(find.text('Aldo · Rovine presso Talmvere'), findsOneWidget);
      expect(find.text('Bea · Rovine presso Talmvere'), findsOneWidget);
    });

    testWidgets(
      '«Teletrasporta il gruppo» prepares the teleport with the card key (D-01, D-28)',
      (tester) async {
        await openWizard(tester, _ready);

        await tester.tap(find.byKey(PlaceStep.teleportKey));
        await tester.pump();

        verify(
          () => teleport.prepare(
            characterId: _aldo,
            name: 'Aldo',
            companionIds: [_bea],
            resumeCardKey: 'quest-world-1',
          ),
        ).called(1);
      },
    );

    testWidgets(
      '«Resta qui» saves step fights with the shared place and opens «Scontri» (D-01, D-18)',
      (tester) async {
        await openWizard(tester, _ready);

        await tester.tap(find.byKey(PlaceStep.stayKey));
        await emitDraft(tester, MissionDraftReady(draft: _draftAt('fights')));

        verify(
          () => draftCubit.saveStep(MissionDraftStep.fights, placeId: _ruins),
        ).called(1);
        expect(_headerOf(MissionPage.encounters, 'Scontri'), findsOneWidget);
      },
    );

    testWidgets('«Riprova» on «Luogo» reads the participants again (D-31)', (
      tester,
    ) async {
      whenListen(
        participantsCubit,
        const Stream<MissionParticipantsState>.empty(),
        initialState: const MissionParticipantsFailed(
          failure: InnkeeperFailure.timedOut,
        ),
      );
      await openWizard(tester, _ready);

      await tester.tap(find.byKey(PlaceStep.retryKey));
      await tester.pump();

      verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
      verify(() => participantsCubit.load([_aldo, _bea])).called(1);
    });

    testWidgets(
      'a draft with no participants teleports nobody and never throws',
      (tester) async {
        await openWizard(
          tester,
          MissionDraftReady(
            draft: MissionDraft.tryFromJson(
              missionDraftJson(participants: const []),
            )!,
          ),
        );

        await tester.tap(find.byKey(PlaceStep.teleportKey));
        await tester.pump();

        expect(tester.takeException(), isNull);
        verifyNever(
          () => teleport.prepare(
            characterId: any(named: 'characterId'),
            name: any(named: 'name'),
            companionIds: any(named: 'companionIds'),
            resumeCardKey: any(named: 'resumeCardKey'),
          ),
        );
      },
    );

    testWidgets('a refused «Resta qui» stays on «Luogo» (T-21-46)', (
      tester,
    ) async {
      when(
        () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
      ).thenAnswer((_) async {
        draftStates.add(
          _ready.copyWith(
            failure: InnkeeperFailure.overrideInvalid,
            failureSerial: 1,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await openWizard(tester, _ready);

      await tester.tap(find.byKey(PlaceStep.stayKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
      expect(
        find.text(MissionCompletionScreen.invalidValuesMessage),
        findsOneWidget,
      );
    });
  });

  group('encounters step (Phase 21)', () {
    setUp(() {
      when(
        () => draftCubit.saveFights(any(), step: any(named: 'step')),
      ).thenAnswer((_) async {});
    });

    testWidgets(
      '«Avanti» on «Scontri» saves the fights with step fights and opens «Scontro 1 di N» (D-02, D-24)',
      (tester) async {
        await openWizard(tester, _twoFightsReady);

        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
        await tester.pumpAndSettle();

        verify(
          () => draftCubit.saveFights(any(), step: MissionDraftStep.fights),
        ).called(1);
        expect(_headerOf(MissionPage.fight, 'Scontro 1 di 2'), findsOneWidget);
      },
    );

    testWidgets(
      'with zero fights it saves step prizes and opens «Premi» (D-24)',
      (tester) async {
        await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
        await tester.pumpAndSettle();

        verify(
          () => draftCubit.saveFights([], step: MissionDraftStep.prizes),
        ).called(1);
        expect(_headerOf(MissionPage.prizes, 'Premi'), findsOneWidget);
      },
    );

    testWidgets('opening «Scontri» loads the enemy list once (D-03)', (
      tester,
    ) async {
      await openWizard(tester, _twoFightsReady);

      verify(() => enemiesCubit.load()).called(1);
    });

    testWidgets('a list already served is not read again (D-03)', (
      tester,
    ) async {
      whenListen(
        enemiesCubit,
        const Stream<MissionEnemiesState>.empty(),
        initialState: MissionEnemiesState(
          enemies: [MissionEnemy.tryFromJson(missionEnemyJson())!],
        ),
      );
      await openWizard(tester, _twoFightsReady);

      verifyNever(() => enemiesCubit.load());
    });

    testWidgets('«Indietro» from «Scontri» goes back to «Luogo»', (
      tester,
    ) async {
      await openWizard(tester, _twoFightsReady);

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.place, 'Luogo'), findsOneWidget);
    });
  });

  group('fight step (Phase 21)', () {
    setUp(() {
      when(
        () => draftCubit.saveFights(any(), step: any(named: 'step')),
      ).thenAnswer((_) async {});
      when(() => draftCubit.simulate(any())).thenAnswer((_) async {});
      when(
        () => draftCubit.saveCorrections(
          any(),
          any(),
          step: any(named: 'step'),
          declaresRemovals: any(named: 'declaresRemovals'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> openFight(
      WidgetTester tester,
      int fightCount, {
      bool isStoryAndWoundInputEnabled = false,
    }) async {
      await openWizard(
        tester,
        MissionDraftReady(
          draft: _draftAt(
            'fights',
            fights: [for (var i = 0; i < fightCount; i++) _simulatedFight()],
          ),
        ),
        isStoryAndWoundInputEnabled: isStoryAndWoundInputEnabled,
      );
      await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
      await tester.pumpAndSettle();
    }

    Future<void> tapNext(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(MissionCompletionScreen.nextKey));
      await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
      await tester.pumpAndSettle();
    }

    testWidgets('«Simula» simulates the fight on show (D-04)', (tester) async {
      await openFight(tester, 2);

      await tester.tap(find.byKey(FightStep.simulateKey));
      await tester.pump();

      verify(() => draftCubit.simulate(0)).called(1);
    });

    testWidgets(
      '«Avanti» on the last fight saves corrections with step prizes and opens «Premi» (D-06)',
      (tester) async {
        await openFight(tester, 1);
        expect(_headerOf(MissionPage.fight, 'Scontro 1 di 1'), findsOneWidget);

        await tapNext(tester);

        final captured = verify(
          () => draftCubit.saveCorrections(
            0,
            captureAny(),
            step: MissionDraftStep.prizes,
          ),
        ).captured;
        expect(
          [
            for (final correction in captured.single as List<MissionCorrection>)
              correction.characterId,
          ],
          [_aldo, _bea],
        );
        expect(_headerOf(MissionPage.prizes, 'Premi'), findsOneWidget);
      },
    );

    testWidgets('with the switch on «Avanti» on a fight saves the corrections '
        'declaring their removals (Q7)', (tester) async {
      await openFight(tester, 2, isStoryAndWoundInputEnabled: true);

      await tapNext(tester);

      verify(
        () => draftCubit.saveCorrections(
          0,
          any(),
          step: null,
          declaresRemovals: true,
        ),
      ).called(1);
    });

    testWidgets('with the switch off it does not declare them (pre-gate)', (
      tester,
    ) async {
      await openFight(tester, 2);

      await tapNext(tester);

      verify(
        () => draftCubit.saveCorrections(
          0,
          any(),
          step: null,
          declaresRemovals: false,
        ),
      ).called(1);
    });

    testWidgets('«Avanti» on fight 1 of 2 opens «Scontro 2 di 2»', (
      tester,
    ) async {
      await openFight(tester, 2);

      await tapNext(tester);

      verify(() => draftCubit.saveCorrections(0, any(), step: null)).called(1);
      expect(_headerOf(MissionPage.fight, 'Scontro 2 di 2'), findsOneWidget);
    });

    testWidgets('«Indietro» from fight 2 goes back to fight 1', (tester) async {
      await openFight(tester, 2);
      await tapNext(tester);

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.fight, 'Scontro 1 di 2'), findsOneWidget);
    });

    testWidgets(
      'unsaved edits of a fight never follow «Indietro» to an identical fight (D-06)',
      (tester) async {
        await openFight(tester, 2);
        await tapNext(tester);
        final aldo = tester.widget<CorrectionSection>(
          find.byType(CorrectionSection).first,
        );
        aldo.onChanged(aldo.correction.withHp(500));
        await tester.pump();

        await tester.tap(find.byKey(MissionCompletionScreen.backKey));
        await tester.pumpAndSettle();
        await tapNext(tester);

        final saved = verify(
          () => draftCubit.saveCorrections(0, captureAny(), step: null),
        ).captured;
        expect((saved.last as List<MissionCorrection>).first.hpAfter, 700);
      },
    );

    testWidgets('«Indietro» from fight 1 goes back to «Scontri»', (
      tester,
    ) async {
      await openFight(tester, 2);

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.encounters, 'Scontri'), findsOneWidget);
    });

    testWidgets('«Indietro» from «Premi» goes back to the last fight', (
      tester,
    ) async {
      await openFight(tester, 2);
      await tapNext(tester);
      await tapNext(tester);
      expect(_headerOf(MissionPage.prizes, 'Premi'), findsOneWidget);

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.fight, 'Scontro 2 di 2'), findsOneWidget);
    });

    testWidgets('«Cambia nemici» goes back to «Scontri» (D-05)', (
      tester,
    ) async {
      await openFight(tester, 2);

      await tester.tap(find.byKey(FightStep.changeEnemiesKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.encounters, 'Scontri'), findsOneWidget);
    });
  });

  group('prizes step (Phase 21)', () {
    setUp(() {
      when(
        () => draftCubit.savePrizes(any(), step: any(named: 'step')),
      ).thenAnswer((_) async {});
    });

    final prizesReady = MissionDraftReady(
      draft: MissionDraft.tryFromJson(
        missionDraftJson(
          step: 'prizes',
          participants: [
            missionParticipantJson(),
            missionParticipantJson(
              character: _bea,
              name: 'Bea',
              pendingQuest: 'pq-world-2',
            ),
          ],
          prizes: [missionPrizeJson()],
        ),
      )!,
    );

    testWidgets('entering «Premi» reads the prize options of everyone (D-22)', (
      tester,
    ) async {
      await openWizard(tester, prizesReady);

      verify(() => prizeOptionsCubit.loadAll([_aldo, _bea])).called(1);
    });

    testWidgets(
      '«Avanti» on «Premi» saves the prizes with step recap and opens «Riepilogo» (D-22)',
      (tester) async {
        await openWizard(tester, prizesReady);

        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
        await tester.pumpAndSettle();

        final captured = verify(
          () =>
              draftCubit.savePrizes(captureAny(), step: MissionDraftStep.recap),
        ).captured;
        expect(
          [
            for (final prize in captured.single as List<MissionPrizeInput>)
              (prize.characterId, prize.xp),
          ],
          [(_aldo, 150), (_bea, 0)],
        );
        expect(_headerOf(MissionPage.recap, 'Riepilogo'), findsOneWidget);
      },
    );

    testWidgets(
      '«Indietro» from «Premi» with zero fights goes to «Scontri» (D-24)',
      (tester) async {
        await openWizard(tester, prizesReady);

        await tester.tap(find.byKey(MissionCompletionScreen.backKey));
        await tester.pumpAndSettle();

        expect(_headerOf(MissionPage.encounters, 'Scontri'), findsOneWidget);
      },
    );
  });

  group('recap step (Phase 21)', () {
    final recapReady = MissionDraftReady(draft: _draftAt('recap'));

    Finder confirmButton() => find.descendant(
      of: find.byType(DestructiveConfirmationDialog),
      matching: find.widgetWithText(ElevatedButton, RecapStep.completeLabel),
    );

    setUp(() => when(() => draftCubit.complete()).thenAnswer((_) async {}));

    testWidgets(
      'a draft reopened on «Riepilogo» reads the prize names (D-22)',
      (tester) async {
        await openWizard(tester, recapReady);

        verify(() => prizeOptionsCubit.loadAll([_aldo, _bea])).called(1);
      },
    );

    testWidgets(
      'completion pops CompletionCompleted with the results for the Phase 10 recap (D-08)',
      (tester) async {
        final exits = await openWizard(tester, recapReady);

        await tester.tap(find.byKey(RecapStep.completeKey));
        await tester.pumpAndSettle();
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();
        verify(() => draftCubit.complete()).called(1);
        await emitDraft(tester, MissionDraftCompleted(results: _results));

        expect(exits, [CompletionCompleted(_results)]);
      },
    );

    testWidgets('«Completa» is disabled while submitting', (tester) async {
      await openWizard(
        tester,
        MissionDraftReady(draft: _draftAt('recap'), isSubmitting: true),
      );

      final complete = tester.widget<ElevatedButton>(
        find.byKey(RecapStep.completeKey),
      );
      expect(complete.onPressed, isNull);
    });

    testWidgets('«Indietro» from «Riepilogo» goes back to «Premi»', (
      tester,
    ) async {
      await openWizard(tester, recapReady);

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerOf(MissionPage.prizes, 'Premi'), findsOneWidget);
    });

    testWidgets(
      'the recap completes as today and the last page does not exist (pre-gate)',
      (tester) async {
        when(() => draftCubit.conclude(any())).thenAnswer((_) async {});
        await openWizard(tester, recapReady);

        expect(find.text('Passo 6 di 6 · Riepilogo'), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.nextKey), findsNothing);

        await tester.tap(find.byKey(RecapStep.completeKey));
        await tester.pumpAndSettle();
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();

        verify(() => draftCubit.complete()).called(1);
        verifyNever(() => draftCubit.conclude(any()));
        verifyNever(
          () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
        );
        expect(find.byType(AdditionsStep), findsNothing);
      },
    );

    testWidgets(
      'a draft served at the step stories opens the recap (pre-gate)',
      (tester) async {
        await openWizard(
          tester,
          MissionDraftReady(
            draft: _draftAt('stories', additions: {_aldo: _scar}),
          ),
        );

        expect(_headerOf(MissionPage.recap, 'Riepilogo'), findsOneWidget);
        expect(find.byKey(RecapStep.completeKey), findsOneWidget);
        expect(find.byType(AdditionsStep), findsNothing);
      },
    );
  });

  group('additions page (Phase 24, input on)', () {
    final recapReady = MissionDraftReady(draft: _draftAt('recap'));
    final storiesReady = MissionDraftReady(draft: _draftAt('stories'));

    setUp(() {
      when(
        () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
      ).thenAnswer((_) async {});
      when(
        () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
      ).thenAnswer((_) async {});
      when(() => draftCubit.conclude(any())).thenAnswer((_) async {});
      when(() => draftCubit.complete()).thenAnswer((_) async {});
    });

    Future<List<CompletionExit?>> openOn(
      WidgetTester tester,
      MissionDraftState initial,
    ) => openWizard(tester, initial, isStoryAndWoundInputEnabled: true);

    Finder additionsHeader() => _headerOf(
      MissionPage.additions,
      MissionCompletionScreen.additionsTitle,
      withAdditions: true,
    );

    Finder recapHeader() =>
        _headerOf(MissionPage.recap, 'Riepilogo', withAdditions: true);

    Future<void> type(WidgetTester tester, String id, String text) async {
      await tester.enterText(find.byKey(AdditionsStep.fieldKeyFor(id)), text);
      await tester.pump();
    }

    Future<void> tapConclude(WidgetTester tester) async {
      await tester.tap(find.byKey(AdditionsStep.concludeKey));
      await tester.pumpAndSettle();
    }

    Future<void> tapBack(WidgetTester tester) async {
      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();
    }

    Finder confirmButton() => find.descendant(
      of: find.byType(DestructiveConfirmationDialog),
      matching: find.widgetWithText(ElevatedButton, RecapStep.completeLabel),
    );

    testWidgets(
      '«Avanti» on the recap saves the step stories and opens the last page (D-05)',
      (tester) async {
        await openOn(tester, recapReady);
        expect(find.byKey(RecapStep.completeKey), findsNothing);
        expect(recapHeader(), findsOneWidget);

        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
        await tester.pumpAndSettle();

        verify(() => draftCubit.saveStep(MissionDraftStep.stories)).called(1);
        expect(
          find.text('Passo 7 di 7 · Aggiunte alle storie'),
          findsOneWidget,
        );
        expect(find.byType(AdditionsStep), findsOneWidget);
        expect(find.byType(Dropdown), findsNWidgets(2));
        verifyNever(() => draftCubit.complete());
      },
    );

    testWidgets('a refused save stays on the recap (T-21-46)', (tester) async {
      when(
        () => draftCubit.saveStep(any(), placeId: any(named: 'placeId')),
      ).thenAnswer((_) async {
        draftStates.add(
          recapReady.copyWith(
            failure: InnkeeperFailure.connection,
            failureSerial: 1,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await openOn(tester, recapReady);

      await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
      await tester.pumpAndSettle();

      expect(recapHeader(), findsOneWidget);
      expect(find.byType(AdditionsStep), findsNothing);
      expect(
        find.text(MissionCompletionScreen.connectionMessage),
        findsOneWidget,
      );
    });

    testWidgets(
      'a draft served at the step stories reopens on the last page with its texts (D-05)',
      (tester) async {
        await openWizard(
          tester,
          const MissionDraftLoading(),
          isStoryAndWoundInputEnabled: true,
        );

        await emitDraft(
          tester,
          MissionDraftReady(
            draft: _draftAt('stories', additions: {_aldo: _scar}),
          ),
        );

        expect(additionsHeader(), findsOneWidget);
        expect(find.text(_scar), findsOneWidget);
        verify(() => participantsCubit.ensureLoaded([_aldo, _bea])).called(1);
      },
    );

    testWidgets(
      'a draft reopened on the last page reads the prize names for the recap behind it (D-22)',
      (tester) async {
        await openOn(tester, storiesReady);

        verify(() => prizeOptionsCubit.loadAll([_aldo, _bea])).called(1);
      },
    );

    testWidgets(
      'the fields start from the additions of the draft, once: a new served draft does not overwrite the typed text (D-05, Pitfall 3)',
      (tester) async {
        await openOn(
          tester,
          MissionDraftReady(
            draft: _draftAt('stories', additions: {_aldo: _scar}),
          ),
        );
        await type(tester, _aldo, _typed);

        await emitDraft(
          tester,
          MissionDraftReady(
            draft: _draftAt('stories', additions: {_aldo: 'Altro', _bea: 'x'}),
          ),
        );

        expect(find.text(_typed), findsOneWidget);
        expect(find.text('Altro'), findsNothing);
        await tapConclude(tester);
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();
        verify(() => draftCubit.conclude({_aldo: _typed})).called(1);
      },
    );

    testWidgets(
      '«Concludi» asks the confirmation with the recap lines and one line per addition (D-05, D-09)',
      (tester) async {
        await openOn(tester, storiesReady);
        await type(tester, _aldo, _typed);
        await type(tester, _bea, '   ');

        await tapConclude(tester);

        final dialog = tester.widget<DestructiveConfirmationDialog>(
          find.byType(DestructiveConfirmationDialog),
        );
        expect(dialog.title, MissionCompletionScreen.title);
        expect(
          dialog.body,
          [
            ...missionRecapLinesOf(
              questTitle: _card.questTitle,
              draft: storiesReady.draft,
            ),
            'Storia di Aldo: una nuova pagina',
          ].join('\n'),
        );
        verifyNever(() => draftCubit.conclude(any()));
      },
    );

    testWidgets('cancelling the confirmation calls nothing (T-24-23)', (
      tester,
    ) async {
      final exits = await openOn(tester, storiesReady);
      await type(tester, _aldo, _typed);

      await tapConclude(tester);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      verifyNever(() => draftCubit.conclude(any()));
      verifyNever(() => draftCubit.complete());
      verifyNever(
        () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
      );
      expect(exits, isEmpty);
      expect(additionsHeader(), findsOneWidget);
    });

    testWidgets(
      'confirming concludes with the typed texts, in one action (D-05, D-06)',
      (tester) async {
        await openOn(tester, storiesReady);
        await type(tester, _aldo, _typed);
        await type(tester, _bea, 'Una bozza');
        await type(tester, _bea, '');

        await tapConclude(tester);
        await tester.tap(confirmButton());
        await tester.pumpAndSettle();

        verify(() => draftCubit.conclude({_aldo: _typed, _bea: ''})).called(1);
        verifyNever(() => draftCubit.complete());
        verifyNever(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        );
      },
    );

    testWidgets('the completed mission leaves the wizard with the results', (
      tester,
    ) async {
      final exits = await openOn(tester, storiesReady);

      await tapConclude(tester);
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();
      await emitDraft(tester, MissionDraftCompleted(results: _results));

      expect(exits, [CompletionCompleted(_results)]);
    });

    testWidgets(
      'an addition refused as too long stays on the page with its line (D-07)',
      (tester) async {
        final exits = await openOn(tester, storiesReady);
        await type(tester, _aldo, _typed);

        await emitDraft(
          tester,
          storiesReady.copyWith(
            failure: InnkeeperFailure.additionTooLong,
            failureSerial: 1,
          ),
        );

        expect(
          find.text(MissionCompletionScreen.additionTooLongMessage),
          findsOneWidget,
        );
        expect(additionsHeader(), findsOneWidget);
        expect(find.text(_typed), findsOneWidget);
        expect(exits, isEmpty);
      },
    );

    testWidgets(
      '«Indietro» from the last page returns to the recap and keeps the texts',
      (tester) async {
        await openOn(tester, storiesReady);
        await type(tester, _aldo, _typed);

        await tapBack(tester);
        expect(recapHeader(), findsOneWidget);
        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
        await tester.pumpAndSettle();

        expect(additionsHeader(), findsOneWidget);
        expect(find.text(_typed), findsOneWidget);
      },
    );

    group('unsaved additions', () {
      void refuseSaveAdditions() {
        when(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        ).thenAnswer((_) async {
          draftStates.add(
            storiesReady.copyWith(
              failure: InnkeeperFailure.connection,
              failureSerial: 1,
            ),
          );
          await Future<void>.delayed(Duration.zero);
        });
      }

      void acceptSaveAdditions() {
        when(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        ).thenAnswer((_) async {});
      }

      Future<void> leave(WidgetTester tester) async {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }

      testWidgets(
        '«Indietro» saves the additions that differ from the draft, then opens the recap (D-05)',
        (tester) async {
          await openOn(tester, storiesReady);
          await type(tester, _aldo, _typed);

          await tapBack(tester);

          verify(() => draftCubit.saveAdditions({_aldo: _typed})).called(1);
          expect(recapHeader(), findsOneWidget);
        },
      );

      testWidgets('«Indietro» without changes saves nothing', (tester) async {
        await openOn(
          tester,
          MissionDraftReady(
            draft: _draftAt('stories', additions: {_aldo: _scar}),
          ),
        );
        await type(tester, _aldo, '$_scar ');
        await type(tester, _bea, '  ');

        await tapBack(tester);

        verifyNever(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        );
        expect(recapHeader(), findsOneWidget);
      });

      testWidgets('a refused save on «Indietro» stays on the page (T-21-46)', (
        tester,
      ) async {
        refuseSaveAdditions();
        await openOn(tester, storiesReady);
        await type(tester, _aldo, _typed);

        await tapBack(tester);

        expect(additionsHeader(), findsOneWidget);
        expect(find.text(_typed), findsOneWidget);
        expect(
          find.text(MissionCompletionScreen.connectionMessage),
          findsOneWidget,
        );
      });

      testWidgets(
        'leaving the wizard with unsaved additions saves them first, then leaves (D-05)',
        (tester) async {
          final exits = await openOn(tester, storiesReady);
          await type(tester, _aldo, _typed);

          await leave(tester);

          verify(() => draftCubit.saveAdditions({_aldo: _typed})).called(1);
          expect(exits, [null]);
          expect(find.byType(MissionCompletionScreen), findsNothing);
        },
      );

      testWidgets(
        'the back arrow of the bar saves the unsaved additions too (D-05)',
        (tester) async {
          final exits = await openOn(tester, storiesReady);
          await type(tester, _aldo, _typed);

          await tester.pageBack();
          await tester.pumpAndSettle();

          verify(() => draftCubit.saveAdditions({_aldo: _typed})).called(1);
          expect(exits, [null]);
        },
      );

      testWidgets('leaving without changes leaves at once', (tester) async {
        final exits = await openOn(tester, storiesReady);

        await leave(tester);

        verifyNever(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        );
        expect(exits, [null]);
      });

      testWidgets(
        'a refused save while leaving keeps the wizard open with the failure line; the next attempt leaves without saving (T-24-26)',
        (tester) async {
          refuseSaveAdditions();
          final exits = await openOn(tester, storiesReady);
          await type(tester, _aldo, _typed);

          await leave(tester);

          expect(exits, isEmpty);
          expect(additionsHeader(), findsOneWidget);
          expect(
            find.text(MissionCompletionScreen.connectionMessage),
            findsOneWidget,
          );

          await leave(tester);

          expect(exits, [null]);
          verify(
            () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
          ).called(1);
        },
      );

      testWidgets('typing again re-arms the save on leave', (tester) async {
        refuseSaveAdditions();
        final exits = await openOn(tester, storiesReady);
        await type(tester, _aldo, _typed);
        await leave(tester);
        acceptSaveAdditions();

        await type(tester, _aldo, '$_typed Due volte.');
        await leave(tester);

        verify(
          () => draftCubit.saveAdditions({_aldo: '$_typed Due volte.'}),
        ).called(1);
        expect(exits, [null]);
      });

      testWidgets('no leave and no save while a call is running', (
        tester,
      ) async {
        final exits = await openOn(
          tester,
          storiesReady.copyWith(isSubmitting: true),
        );
        await type(tester, _aldo, _typed);

        await leave(tester);

        verifyNever(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        );
        expect(exits, isEmpty);
        expect(additionsHeader(), findsOneWidget);
      });

      testWidgets('leaving from «Premi» behaves as before: no save', (
        tester,
      ) async {
        final exits = await openOn(
          tester,
          MissionDraftReady(draft: _draftAt('prizes')),
        );

        await leave(tester);

        verifyNever(
          () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
        );
        expect(exits, [null]);
      });

      testWidgets(
        'on the recap the leave is free again: the additions were saved by «Indietro»',
        (tester) async {
          final exits = await openOn(tester, storiesReady);
          await type(tester, _aldo, _typed);
          await tapBack(tester);
          expect(recapHeader(), findsOneWidget);

          await leave(tester);

          verify(
            () => draftCubit.saveAdditions(any(), step: any(named: 'step')),
          ).called(1);
          expect(exits, [null]);
        },
      );
    });

    testWidgets(
      'in landscape with the keyboard open the header hides, nothing overflows and the focused field is visible (Pitfall 6)',
      (tester) async {
        await openOn(tester, storiesReady);
        final field = find.byKey(AdditionsStep.fieldKeyFor(_bea));
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pump();

        tester.view.viewInsets = const FakeViewPadding(bottom: 600);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        expect(additionsHeader(), findsNothing);
        expect(find.byKey(AdditionsStep.concludeKey), findsNothing);
        expect(tester.takeException(), isNull);
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(tester.getRect(field).overlaps(viewport), isTrue);
        expect(viewport.height, greaterThan(0));
      },
    );

    testWidgets(
      '«Riprova» on the last page reads the participants again (D-31)',
      (tester) async {
        whenListen(
          participantsCubit,
          const Stream<MissionParticipantsState>.empty(),
          initialState: const MissionParticipantsFailed(
            failure: InnkeeperFailure.timedOut,
          ),
        );
        await openOn(tester, storiesReady);

        await tester.tap(find.byKey(AdditionsStep.retryKey));
        await tester.pump();

        verify(() => participantsCubit.load([_aldo, _bea])).called(1);
      },
    );
  });
}
