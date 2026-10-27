import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/spell_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/spell_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

void main() {
  late MockSpellsCubit spells;
  late MockCharacterCubit characterCubit;
  late MockInAppNotificationsCubit notices;
  late StreamController<SpellsState> spellsStates;
  late StreamController<CharacterState> characterStates;

  final first = spellbookCharacter();
  final equipped = spellbookCharacter(
    activeSpells: [activeSpellJson(spellId: 'spell-1')],
  );

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
    registerFallbackValue(spellbookCharacter());
  });

  setUp(() {
    spells = MockSpellsCubit();
    characterCubit = MockCharacterCubit();
    notices = MockInAppNotificationsCubit();
    spellsStates = StreamController<SpellsState>.broadcast();
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(spellsStates.close);
    addTearDown(characterStates.close);
    whenListen(spells, spellsStates.stream, initialState: const SpellsState());
    whenListen(
      characterCubit,
      characterStates.stream,
      initialState: CharacterLoaded(first),
    );
    when(() => characterCubit.refreshCharacter()).thenAnswer((_) async {});
  });

  Future<void> pumpListener(WidgetTester tester) => tester.pumpWidget(
    buildTestApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SpellsCubit>.value(value: spells),
          BlocProvider<CharacterCubit>.value(value: characterCubit),
          BlocProvider<InAppNotificationsCubit>.value(value: notices),
        ],
        child: const SpellOutcomeListener(child: SizedBox()),
      ),
    ),
  );

  Future<void> emitSpells(WidgetTester tester, SpellsState state) async {
    when(() => spells.state).thenReturn(state);
    spellsStates.add(state);
    await tester.pump();
  }

  Future<void> emitCharacter(WidgetTester tester, CharacterState state) async {
    when(() => characterCubit.state).thenReturn(state);
    characterStates.add(state);
    await tester.pump();
  }

  SpellsState failedWith(
    SpellEquipFailure failure, {
    SpellOperation operation = SpellOperation.equip,
  }) => SpellsState(
    outcome: SpellOutcome(
      sequence: 1,
      spellId: 'spell-a',
      operation: operation,
      kind: SpellOutcomeKind.failed,
      failure: failure,
    ),
  );

  void verifyNoNotice() => verifyNever(
    () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
  );

  group('sync', () {
    testWidgets('a new loaded character is forwarded once', (tester) async {
      await pumpListener(tester);

      await emitCharacter(tester, CharacterLoaded(equipped));

      verify(() => spells.sync(equipped)).called(1);
    });

    testWidgets('the same character again is not forwarded', (tester) async {
      await pumpListener(tester);

      await emitCharacter(tester, CharacterLoaded(first));

      verifyNever(() => spells.sync(any()));
    });

    testWidgets('a state without a character is not forwarded', (tester) async {
      await pumpListener(tester);

      await emitCharacter(tester, CharacterLoading());

      verifyNever(() => spells.sync(any()));
    });
  });

  group('outcomes', () {
    testWidgets('slots full from the server: banner and silent re-read', (
      tester,
    ) async {
      await pumpListener(tester);

      await emitSpells(tester, failedWith(SpellEquipFailure.slotsFull));

      verify(
        () => notices.publishNotice(
          const KGNotification(
            title: 'Magia non equipaggiata',
            description: 'Slot pieni: disequipaggia una magia',
          ),
          dedupKey: 'spell|failed|slotsFull|spell-a',
        ),
      ).called(1);
      verify(() => characterCubit.refreshCharacter()).called(1);
    });

    for (final failure in [
      SpellEquipFailure.alreadyActive,
      SpellEquipFailure.notActive,
    ]) {
      testWidgets('${failure.name}: no banner, silent re-read', (tester) async {
        await pumpListener(tester);

        await emitSpells(tester, failedWith(failure));

        verifyNoNotice();
        verify(() => characterCubit.refreshCharacter()).called(1);
      });
    }

    for (final failure in [
      SpellEquipFailure.notKnown,
      SpellEquipFailure.notFound,
    ]) {
      testWidgets('${failure.name}: banner and silent re-read', (tester) async {
        await pumpListener(tester);

        await emitSpells(tester, failedWith(failure));

        verify(
          () => notices.publishNotice(
            any(),
            dedupKey: 'spell|failed|${failure.name}|spell-a',
          ),
        ).called(1);
        verify(() => characterCubit.refreshCharacter()).called(1);
      });
    }

    testWidgets('timedOut: banner and silent re-read (WR-01)', (tester) async {
      await pumpListener(tester);

      await emitSpells(tester, failedWith(SpellEquipFailure.timedOut));

      verify(
        () => notices.publishNotice(
          const KGNotification(
            title: 'Magia non equipaggiata',
            description:
                'Il server non ha risposto in tempo: '
                'controlla le magie prima di riprovare',
          ),
          dedupKey: 'spell|failed|timedOut|spell-a',
        ),
      ).called(1);
      verify(() => characterCubit.refreshCharacter()).called(1);
    });

    testWidgets('a settle by timeout: no banner, silent re-read (WR-01)', (
      tester,
    ) async {
      await pumpListener(tester);

      await emitSpells(
        tester,
        const SpellsState(
          outcome: SpellOutcome(
            sequence: 1,
            spellId: 'spell-a',
            operation: SpellOperation.unequip,
            kind: SpellOutcomeKind.settledByTimeout,
          ),
        ),
      );

      verifyNoNotice();
      verify(() => characterCubit.refreshCharacter()).called(1);
    });

    testWidgets('connection: banner with the unequip title, no re-read', (
      tester,
    ) async {
      await pumpListener(tester);

      await emitSpells(
        tester,
        failedWith(
          SpellEquipFailure.connection,
          operation: SpellOperation.unequip,
        ),
      );

      verify(
        () => notices.publishNotice(
          const KGNotification(
            title: 'Magia non tolta',
            description: 'Connessione assente, riprova',
          ),
          dedupKey: 'spell|failed|connection|spell-a',
        ),
      ).called(1);
      verifyNever(() => characterCubit.refreshCharacter());
    });

    testWidgets('unauthenticated: nothing at all', (tester) async {
      await pumpListener(tester);

      await emitSpells(tester, failedWith(SpellEquipFailure.unauthenticated));

      verifyNoNotice();
      verifyNever(() => characterCubit.refreshCharacter());
    });

    testWidgets('a slots-full block: banner, no re-read', (tester) async {
      await pumpListener(tester);

      await emitSpells(
        tester,
        const SpellsState(
          outcome: SpellOutcome(
            sequence: 1,
            spellId: 'spell-b',
            operation: SpellOperation.equip,
            kind: SpellOutcomeKind.blockedSlotsFull,
          ),
        ),
      );

      verify(
        () => notices.publishNotice(
          const KGNotification(
            title: 'Magia non equipaggiata',
            description: 'Slot pieni: disequipaggia una magia',
          ),
          dedupKey: 'spell|blockedSlotsFull|-|spell-b',
        ),
      ).called(1);
      verifyNever(() => characterCubit.refreshCharacter());
    });

    testWidgets('a change that keeps the same outcome does nothing', (
      tester,
    ) async {
      final failed = failedWith(SpellEquipFailure.connection);
      await pumpListener(tester);
      await emitSpells(tester, failed);
      clearInteractions(notices);

      await emitSpells(
        tester,
        failed.copyWith(pending: const {'spell-c': SpellOperation.equip}),
      );

      verifyNoNotice();
    });
  });
}
