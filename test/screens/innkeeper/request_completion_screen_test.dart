import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/participant_override_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_screen.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/pending_request_fixtures.dart';
import '../../helpers/fixtures/quest_result_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

const String _bea = 'char-bea';
const String _cosimo = 'char-cosimo';

final DateTime _now = DateTime.utc(2026, 10, 29, 12);

final Character _beaCharacter = Character.fromJson(
  participantCharacterJson(id: _bea, name: 'Bea'),
);
final Character _cosimoCharacter = Character.fromJson(
  participantCharacterJson(id: _cosimo, name: 'Cosimo'),
);

final RequestCard _card = requestCardsOf(
  worldMissionEntriesJson().map(PendingRequest.fromJson).toList(),
).single;

final RequestCompletionEditing _editing = RequestCompletionEditing(
  drafts: [
    ParticipantDraft.from(_beaCharacter, fallbackName: 'Bea'),
    ParticipantDraft.from(_cosimoCharacter, fallbackName: 'Cosimo'),
  ],
);

final List<QuestResult> _results = [
  QuestResult.fromJson(questResultJson(id: 'result-bea', character: _bea)),
];

const String _genericError =
    'Non è stato possibile completare la richiesta. Riprova.';

Finder get _confirmButton => find.widgetWithText(ElevatedButton, 'Conferma');

Finder get _dialogConfirm => find.descendant(
  of: find.byType(DestructiveConfirmationDialog),
  matching: find.widgetWithText(ElevatedButton, 'Conferma'),
);

void main() {
  late MockPendingRequestsCubit queue;

  setUpAll(() {
    registerFallbackValue(
      const CompletePendingRequestInput(pendingQuestId: '', outcomes: []),
    );
  });

  setUp(() {
    queue = MockPendingRequestsCubit();
    whenListen(
      queue,
      const Stream<PendingRequestsState>.empty(),
      initialState: PendingRequestsState(serverNow: _now, isLoaded: true),
    );
    when(() => queue.refetch()).thenAnswer((_) async {});
  });

  group('state-driven form', () {
    late MockRequestCompletionCubit cubit;

    setUp(() {
      cubit = MockRequestCompletionCubit();
      when(() => cubit.load()).thenAnswer((_) async {});
      when(() => cubit.submit()).thenAnswer((_) async {});
      when(() => cubit.isClosed).thenReturn(false);
    });

    Future<void> pumpScreen(
      WidgetTester tester,
      RequestCompletionState state, {
      Stream<RequestCompletionState>? stream,
    }) async {
      useLandscapePhone(tester);
      whenListen(
        cubit,
        stream ?? const Stream<RequestCompletionState>.empty(),
        initialState: state,
      );
      await tester.pumpWidget(
        buildTestApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<PendingRequestsCubit>.value(value: queue),
              BlocProvider<RequestCompletionCubit>.value(value: cubit),
            ],
            child: RequestCompletionScreen(card: _card),
          ),
        ),
      );
    }

    testWidgets('loading shows only the loader', (tester) async {
      await pumpScreen(tester, const RequestCompletionLoading());

      expect(find.byType(KGLoader), findsOneWidget);
      expect(find.byType(ParticipantOverrideSection), findsNothing);
    });

    testWidgets('a read failure offers «Riprova», which loads again', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const RequestCompletionLoadFailed(failure: InnkeeperFailure.connection),
      );

      expect(
        find.text('Non è stato possibile leggere i partecipanti'),
        findsOneWidget,
      );
      await tester.tap(find.text('Riprova'));
      verify(() => cubit.load()).called(1);
    });

    testWidgets('the form shows the quest and one section per participant', (
      tester,
    ) async {
      await pumpScreen(tester, _editing);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Completa la richiesta'),
        ),
        findsOneWidget,
      );
      expect(find.text('L\'assedio di Borgo Rovo'), findsOneWidget);
      expect(find.byType(ParticipantOverrideSection), findsNWidgets(2));
      expect(_confirmButton, findsOneWidget);
    });

    testWidgets('a chip tap edits that participant', (tester) async {
      await pumpScreen(tester, _editing);

      final chip = find
          .byKey(const ValueKey('completion.injury.brokenLeftArm'))
          .first;
      await tester.ensureVisible(chip);
      await tester.tap(chip);

      verify(
        () => cubit.toggleInjury(_bea, InjuryType.brokenLeftArm),
      ).called(1);
    });

    testWidgets('«Conferma» asks with the recap and the neutral style', (
      tester,
    ) async {
      await pumpScreen(tester, _editing);

      await tester.tap(_confirmButton);
      await tester.pumpAndSettle();

      expect(find.byType(DestructiveConfirmationDialog), findsOneWidget);
      final dialog = tester.widget<DestructiveConfirmationDialog>(
        find.byType(DestructiveConfirmationDialog),
      );
      expect(dialog.title, 'Completa la richiesta');
      expect(dialog.body, contains('Partecipanti: 2'));
      expect(
        tester.widget<ElevatedButton>(_dialogConfirm).style,
        KlimmeckGuideTheme.primaryButtonStyle,
      );
    });

    testWidgets('dialog «Annulla» sends nothing', (tester) async {
      await pumpScreen(tester, _editing);

      await tester.tap(_confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.submit());
      expect(find.byType(DestructiveConfirmationDialog), findsNothing);
    });

    testWidgets('dialog «Conferma» submits once', (tester) async {
      await pumpScreen(tester, _editing);

      await tester.tap(_confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(_dialogConfirm);
      await tester.pumpAndSettle();

      verify(() => cubit.submit()).called(1);
    });

    testWidgets('while submitting «Conferma» is disabled', (tester) async {
      await pumpScreen(tester, _editing.copyWith(isSubmitting: true));

      expect(tester.widget<ElevatedButton>(_confirmButton).onPressed, isNull);
    });

    Future<void> pushScreen(
      WidgetTester tester,
      RequestCompletionState state,
    ) async {
      useLandscapePhone(tester);
      whenListen(
        cubit,
        const Stream<RequestCompletionState>.empty(),
        initialState: state,
      );
      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<PendingRequestsCubit>.value(value: queue),
                        BlocProvider<RequestCompletionCubit>.value(
                          value: cubit,
                        ),
                      ],
                      child: RequestCompletionScreen(card: _card),
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
    }

    testWidgets('while submitting the system back keeps the form', (
      tester,
    ) async {
      await pushScreen(tester, _editing.copyWith(isSubmitting: true));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(RequestCompletionScreen), findsOneWidget);
    });

    testWidgets('while editing the system back leaves the form', (
      tester,
    ) async {
      await pushScreen(tester, _editing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(RequestCompletionScreen), findsNothing);
    });

    testWidgets('an invalid override shows the form error', (tester) async {
      await pumpScreen(
        tester,
        _editing.copyWith(
          failure: InnkeeperFailure.overrideInvalid,
          failureSerial: 1,
        ),
      );

      expect(
        find.text('Valori non accettati: controlla il modulo'),
        findsOneWidget,
      );
      expect(find.byType(ParticipantOverrideSection), findsNWidgets(2));
    });

    testWidgets('a former participant shows its error and refetches once', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        _editing,
        stream: Stream.value(
          _editing.copyWith(
            failure: InnkeeperFailure.notParticipant,
            failureSerial: 1,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Un partecipante non fa più parte della richiesta'),
        findsOneWidget,
      );
      verify(() => queue.refetch()).called(1);
    });

    for (final failure in [
      InnkeeperFailure.connection,
      InnkeeperFailure.timedOut,
      InnkeeperFailure.unknown,
      InnkeeperFailure.declined,
      InnkeeperFailure.malformed,
      InnkeeperFailure.unauthenticated,
    ]) {
      testWidgets('${failure.name} keeps the form with a retry text', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _editing.copyWith(failure: failure, failureSerial: 1),
        );

        expect(find.text(_genericError), findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(_confirmButton).onPressed,
          isNotNull,
        );
      });
    }
  });

  group('exits through the route', () {
    late MockInnkeeperRepository repository;

    setUp(() {
      repository = MockInnkeeperRepository();
      when(
        () => repository.readCharacter(_bea),
      ).thenAnswer((_) async => _beaCharacter);
      when(
        () => repository.readCharacter(_cosimo),
      ).thenAnswer((_) async => _cosimoCharacter);
      when(() => repository.complete(any())).thenAnswer((_) async => _results);
    });

    Future<List<CompletionExit?>> openForm(WidgetTester tester) async {
      useLandscapePhone(tester);
      final exits = <CompletionExit?>[];
      await tester.pumpWidget(
        buildTestApp(
          home: RepositoryProvider<InnkeeperRepository>.value(
            value: repository,
            child: BlocProvider<PendingRequestsCubit>.value(
              value: queue,
              child: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async =>
                        exits.add(await openRequestCompletion(context, _card)),
                    child: const Text('apri'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return exits;
    }

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(_confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(_dialogConfirm);
      await tester.pumpAndSettle();
    }

    testWidgets('a forbidden read pops with CompletionForbidden', (
      tester,
    ) async {
      when(
        () => repository.readCharacter(_cosimo),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.forbidden));

      final exits = await openForm(tester);
      await tester.pumpAndSettle();

      expect(exits, [const CompletionForbidden()]);
      expect(find.byType(RequestCompletionScreen), findsNothing);
    });

    testWidgets('a missing request at open pops with CompletionGone', (
      tester,
    ) async {
      when(
        () => repository.readCharacter(_bea),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.notFound));

      final exits = await openForm(tester);
      await tester.pumpAndSettle();

      expect(exits, [const CompletionGone()]);
    });

    testWidgets('a connection failure at open stays with «Riprova»', (
      tester,
    ) async {
      when(
        () => repository.readCharacter(_bea),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.connection));

      final exits = await openForm(tester);
      await tester.pumpAndSettle();

      expect(exits, isEmpty);
      expect(find.text('Riprova'), findsOneWidget);
    });

    testWidgets('a success pops with the results', (tester) async {
      final exits = await openForm(tester);
      await tester.pumpAndSettle();

      await confirm(tester);

      expect(exits, [CompletionCompleted(_results)]);
      verify(() => repository.complete(any())).called(1);
    });

    for (final (failure, exit) in [
      (InnkeeperFailure.notFound, const CompletionGone()),
      (InnkeeperFailure.questInProgress, const CompletionBusy()),
      (InnkeeperFailure.forbidden, const CompletionForbidden()),
    ]) {
      testWidgets('${failure.name} at submit pops with ${exit.runtimeType}', (
        tester,
      ) async {
        when(
          () => repository.complete(any()),
        ).thenThrow(InnkeeperException(failure));

        final exits = await openForm(tester);
        await tester.pumpAndSettle();
        await confirm(tester);

        expect(exits, [exit]);
      });
    }
  });
}
