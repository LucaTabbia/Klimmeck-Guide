import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/place_step.dart';
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
import '../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';
const String _ruins = 'poi-ruins-1';

final DateTime _now = DateTime.utc(2026, 11, 14, 12);

final List<PendingRequest> _entries = worldMissionEntriesJson(
  names: const ['Aldo', 'Bea'],
).map(PendingRequest.fromJson).toList();

final RequestCard _card = requestCardsOf(_entries).single;

MissionDraft _draftAt(String step) => MissionDraft.tryFromJson(
  missionDraftJson(
    step: step,
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

final List<QuestResult> _results = [
  QuestResult.fromJson(questResultJson(id: 'result-aldo', character: _aldo)),
];

Finder _headerText(String text) => find.text(text);

Finder get _discardConfirm => find.descendant(
  of: find.byType(DestructiveConfirmationDialog),
  matching: find.widgetWithText(ElevatedButton, 'Scarta la bozza'),
);

void main() {
  late MockMissionDraftCubit draftCubit;
  late MockMissionParticipantsCubit participantsCubit;
  late MockPendingRequestsCubit queue;
  late MockTeleportModeCubit teleport;
  late StreamController<MissionDraftState> draftStates;
  late StreamController<PendingRequestsState> queueStates;
  late StreamController<TeleportModeState> teleportStates;

  setUpAll(() => registerFallbackValue(MissionDraftStep.fights));

  setUp(() {
    draftCubit = MockMissionDraftCubit();
    participantsCubit = MockMissionParticipantsCubit();
    queue = MockPendingRequestsCubit();
    teleport = MockTeleportModeCubit();
    draftStates = StreamController<MissionDraftState>.broadcast();
    queueStates = StreamController<PendingRequestsState>.broadcast();
    teleportStates = StreamController<TeleportModeState>.broadcast();
    when(() => draftCubit.load()).thenAnswer((_) async {});
    when(() => draftCubit.start()).thenAnswer((_) async {});
    when(() => draftCubit.discard()).thenAnswer((_) async {});
    when(() => participantsCubit.load(any())).thenAnswer((_) async {});
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
    MissionDraftState initial,
  ) async {
    useLandscapePhone(tester);
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
                      ],
                      child: MissionCompletionScreen(card: _card),
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
      'opening shows the loader, then «Inizia la missione» without a draft (D-28)',
      (tester) async {
        await openWizard(tester, const MissionDraftLoading());

        expect(find.byType(KGLoader), findsOneWidget);
        expect(find.byKey(MissionCompletionScreen.startKey), findsNothing);

        await emitDraft(tester, const MissionDraftAbsent());

        expect(find.byKey(MissionCompletionScreen.startKey), findsOneWidget);
        expect(find.text(MissionCompletionScreen.startNote), findsOneWidget);
        expect(find.text(MissionCompletionScreen.title), findsOneWidget);
        verifyNever(() => draftCubit.start());
      },
    );

    testWidgets('tapping «Inizia la missione» starts the draft (D-11, D-28)', (
      tester,
    ) async {
      await openWizard(tester, const MissionDraftAbsent());

      await tester.tap(find.byKey(MissionCompletionScreen.startKey));
      await tester.pump();

      verify(() => draftCubit.start()).called(1);
    });

    testWidgets(
      'a served draft at step fights reopens on «Scontri» (D-09, D-18)',
      (tester) async {
        await openWizard(tester, const MissionDraftLoading());

        await emitDraft(tester, MissionDraftReady(draft: _draftAt('fights')));

        expect(_headerText('Passo 2 di 5 · Scontri'), findsOneWidget);
        verify(() => participantsCubit.load([_aldo, _bea])).called(1);
      },
    );

    for (final step in ['teleport', 'unknown']) {
      testWidgets('a served draft at step $step reopens on «Luogo» (D-18)', (
        tester,
      ) async {
        await openWizard(tester, const MissionDraftLoading());

        await emitDraft(tester, MissionDraftReady(draft: _draftAt(step)));

        expect(_headerText('Passo 1 di 5 · Luogo'), findsOneWidget);
      });
    }

    testWidgets('a served draft at step prizes reopens on «Premi» (D-18)', (
      tester,
    ) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('prizes')));

      expect(_headerText('Passo 4 di 5 · Premi'), findsOneWidget);
      verify(() => participantsCubit.load([_aldo, _bea])).called(1);
    });

    testWidgets('a served draft at step recap reopens on «Riepilogo» (D-18)', (
      tester,
    ) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('recap')));

      expect(_headerText('Passo 5 di 5 · Riepilogo'), findsOneWidget);
    });

    testWidgets('a later save never moves the page (D-18)', (tester) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      await emitDraft(tester, MissionDraftReady(draft: _draftAt('recap')));

      expect(_headerText('Passo 2 di 5 · Scontri'), findsOneWidget);
    });

    testWidgets('a ready draft shows the leave note (D-09)', (tester) async {
      await openWizard(tester, _ready);

      expect(find.text(MissionCompletionScreen.leaveNote), findsOneWidget);
      expect(find.byKey(MissionCompletionScreen.discardKey), findsOneWidget);
    });

    testWidgets('«Indietro» is disabled on «Luogo»', (tester) async {
      await openWizard(tester, _ready);

      final back = tester.widget<OutlinedButton>(
        find.byKey(MissionCompletionScreen.backKey),
      );
      expect(back.onPressed, isNull);
    });

    testWidgets('«Indietro» goes back one page without a call (D-09)', (
      tester,
    ) async {
      await openWizard(tester, MissionDraftReady(draft: _draftAt('fights')));

      await tester.tap(find.byKey(MissionCompletionScreen.backKey));
      await tester.pumpAndSettle();

      expect(_headerText('Passo 1 di 5 · Luogo'), findsOneWidget);
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
    for (final (failure, line) in [
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
          expect(_headerText('Passo 1 di 5 · Luogo'), findsOneWidget);
        },
      );
    }

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
        expect(find.text('Passo 2 di 5 · Scontri'), findsOneWidget);
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

      expect(find.text('Passo 1 di 5 · Luogo'), findsOneWidget);
      expect(
        find.text(MissionCompletionScreen.invalidValuesMessage),
        findsOneWidget,
      );
    });
  });
}
