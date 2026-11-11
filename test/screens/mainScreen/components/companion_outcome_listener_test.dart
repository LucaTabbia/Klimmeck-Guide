import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/companion_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

Character _character({String? equipped}) => Character.fromJson({
  'id': 'c-1',
  'assets': {
    'pet': equipped == null ? null : petJson(id: equipped),
    'ownedPets': [ownedPetJson(pet: petJson(id: 'pet-horse'))],
  },
});

void main() {
  late MockCompanionCubit companion;
  late MockCharacterCubit characterCubit;
  late MockInAppNotificationsCubit notices;
  late StreamController<CompanionState> companionStates;
  late StreamController<CharacterState> characterStates;

  final first = _character();

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
    registerFallbackValue(_character());
  });

  setUp(() {
    companion = MockCompanionCubit();
    characterCubit = MockCharacterCubit();
    notices = MockInAppNotificationsCubit();
    companionStates = StreamController<CompanionState>.broadcast();
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(companionStates.close);
    addTearDown(characterStates.close);
    whenListen(
      companion,
      companionStates.stream,
      initialState: const CompanionState(),
    );
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
          BlocProvider<CompanionCubit>.value(value: companion),
          BlocProvider<CharacterCubit>.value(value: characterCubit),
          BlocProvider<InAppNotificationsCubit>.value(value: notices),
        ],
        child: const CompanionOutcomeListener(child: SizedBox()),
      ),
    ),
  );

  Future<void> emitCompanion(WidgetTester tester, CompanionState state) async {
    when(() => companion.state).thenReturn(state);
    companionStates.add(state);
    await tester.pump();
  }

  Future<void> emitCharacter(WidgetTester tester, CharacterState state) async {
    when(() => characterCubit.state).thenReturn(state);
    characterStates.add(state);
    await tester.pump();
  }

  CompanionState outcomeOf(
    CompanionOutcomeKind kind, {
    PetEquipFailure? failure,
  }) => CompanionState(
    outcome: CompanionOutcome(
      sequence: 1,
      petId: 'pet-horse',
      operation: CompanionOperation.equip,
      kind: kind,
      failure: failure,
    ),
  );

  CompanionState failedWith(PetEquipFailure failure) =>
      outcomeOf(CompanionOutcomeKind.failed, failure: failure);

  void verifyNoNotice() => verifyNever(
    () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
  );

  testWidgets('syncs the cubit on every new character (D-10)', (tester) async {
    final equipped = _character(equipped: 'pet-horse');
    await pumpListener(tester);

    await emitCharacter(tester, CharacterLoaded(equipped));
    await emitCharacter(tester, CharacterLoaded(first));

    verify(() => companion.sync(equipped)).called(1);
    verify(() => companion.sync(first)).called(1);
  });

  testWidgets('publishes the banner of a failed outcome with a dedup key '
      '(D-06)', (tester) async {
    await pumpListener(tester);

    await emitCompanion(tester, failedWith(PetEquipFailure.forbidden));

    verify(
      () => notices.publishNotice(
        const KGNotification(
          title: 'Compagno non equipaggiato',
          description: 'Questo personaggio non può farlo',
        ),
        dedupKey: 'companion|failed|forbidden|pet-horse',
      ),
    ).called(1);
    verifyNever(() => characterCubit.refreshCharacter());
  });

  testWidgets('re-reads the character after a stale-view refusal (D-06)', (
    tester,
  ) async {
    for (final failure in [
      PetEquipFailure.notOwned,
      PetEquipFailure.notFound,
    ]) {
      await pumpListener(tester);

      await emitCompanion(tester, failedWith(failure));

      verify(() => characterCubit.refreshCharacter()).called(1);
      verifyNoNotice();
      await emitCompanion(tester, const CompanionState());
    }
  });

  testWidgets('re-reads after a timeout and after a settle by timeout', (
    tester,
  ) async {
    await pumpListener(tester);

    await emitCompanion(tester, failedWith(PetEquipFailure.timedOut));
    verify(() => characterCubit.refreshCharacter()).called(1);
    verify(
      () => notices.publishNotice(
        any(),
        dedupKey: 'companion|failed|timedOut|pet-horse',
      ),
    ).called(1);

    await emitCompanion(
      tester,
      outcomeOf(CompanionOutcomeKind.settledByTimeout),
    );
    verify(() => characterCubit.refreshCharacter()).called(1);
    verifyNoNotice();
  });

  testWidgets('does not re-read after a connection refusal', (tester) async {
    await pumpListener(tester);

    await emitCompanion(tester, failedWith(PetEquipFailure.connection));

    verifyNever(() => characterCubit.refreshCharacter());
    verify(
      () => notices.publishNotice(
        any(),
        dedupKey: 'companion|failed|connection|pet-horse',
      ),
    ).called(1);
  });
}
