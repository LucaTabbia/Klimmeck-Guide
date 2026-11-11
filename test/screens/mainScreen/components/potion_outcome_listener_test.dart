import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/potion_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../helpers/fixtures/potion_fixtures.dart';
import '../../../helpers/fixtures/spell_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

const String _herb = 'l-herb';

void main() {
  late MockPotionCubit potion;
  late MockCharacterCubit characterCubit;
  late MockInAppNotificationsCubit notices;
  late FakeServerClockService clock;
  late StreamController<PotionState> potionStates;

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    potion = MockPotionCubit();
    characterCubit = MockCharacterCubit();
    notices = MockInAppNotificationsCubit();
    clock = FakeServerClockService(spellFixtureNow);
    potionStates = StreamController<PotionState>.broadcast();
    addTearDown(potionStates.close);
    addTearDown(clock.dispose);
    when(() => characterCubit.refreshCharacter()).thenAnswer((_) async {});
  });

  Future<void> pumpListener(
    WidgetTester tester, {
    PotionState initialState = const PotionIdle(),
  }) {
    whenListen(potion, potionStates.stream, initialState: initialState);
    return tester.pumpWidget(
      buildTestApp(
        home: RepositoryProvider<ServerClockService>.value(
          value: clock,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PotionCubit>.value(value: potion),
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<InAppNotificationsCubit>.value(value: notices),
            ],
            child: const PotionOutcomeListener(child: SizedBox()),
          ),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, PotionState state) async {
    when(() => potion.state).thenReturn(state);
    potionStates.add(state);
    await tester.pump();
  }

  PotionRefused refused(
    ItemUseFailure failure, {
    DateTime? recoveryUntil,
    int sequence = 1,
  }) => PotionRefused(
    _herb,
    failure,
    recoveryUntil: recoveryUntil,
    sequence: sequence,
  );

  void verifyNoNotice() => verifyNever(
    () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
  );

  List<Object?> publishedKeys() => verify(
    () => notices.publishNotice(any(), dedupKey: captureAny(named: 'dedupKey')),
  ).captured;

  testWidgets('a refusal publishes one banner titled Pozione non bevuta '
      '(D-18)', (tester) async {
    await pumpListener(tester);

    await emit(tester, refused(ItemUseFailure.noEffect));

    verify(
      () => notices.publishNotice(
        const KGNotification(
          title: 'Pozione non bevuta',
          description: 'Questa pozione non ti farebbe nulla adesso',
        ),
        dedupKey: any(named: 'dedupKey'),
      ),
    ).called(1);
  });

  testWidgets('the remaining time of a recovery refusal comes from the server '
      'date on the server clock (D-11, D-19)', (tester) async {
    await pumpListener(tester);

    await emit(
      tester,
      refused(
        ItemUseFailure.potionRecovering,
        recoveryUntil: spellFixtureNow.add(const Duration(minutes: 72)),
      ),
    );

    final notice =
        verify(
              () => notices.publishNotice(
                captureAny(),
                dedupKey: any(named: 'dedupKey'),
              ),
            ).captured.single
            as KGNotification;
    expect(notice.title, 'Pozione non bevuta');
    expect(notice.description, endsWith('pronta fra 1 h 12 min'));
  });

  testWidgets('two identical refusals publish two banners with different keys '
      '(D-19)', (tester) async {
    await pumpListener(tester);

    await emit(tester, refused(ItemUseFailure.noEffect));
    await emit(tester, refused(ItemUseFailure.noEffect, sequence: 2));

    final keys = publishedKeys();
    expect(keys, hasLength(2));
    expect(keys.first, isNot(keys.last));
  });

  testWidgets('a drunk potion publishes nothing and rereads nothing (D-11)', (
    tester,
  ) async {
    await pumpListener(tester);

    await emit(tester, const PotionDrinking(_herb));
    await emit(
      tester,
      PotionDrunk(_herb, UseItemResult.fromJson(useItemResultJson())),
    );

    verifyNoNotice();
    verifyNever(() => characterCubit.refreshCharacter());
  });

  testWidgets('a not-owned or timed-out refusal rereads the character silently '
      '(D-11)', (tester) async {
    await pumpListener(tester);

    await emit(tester, refused(ItemUseFailure.notOwned));
    verify(() => characterCubit.refreshCharacter()).called(1);

    await emit(tester, refused(ItemUseFailure.timedOut, sequence: 2));
    verify(() => characterCubit.refreshCharacter()).called(1);
  });

  testWidgets('an unknown failure rereads the character silently under the '
      'generic banner (D-11, D-19)', (tester) async {
    await pumpListener(tester);

    await emit(tester, refused(ItemUseFailure.unknown));

    verify(() => characterCubit.refreshCharacter()).called(1);
    final notice =
        verify(
              () => notices.publishNotice(
                captureAny(),
                dedupKey: any(named: 'dedupKey'),
              ),
            ).captured.single
            as KGNotification;
    expect(notice.title, 'Pozione non bevuta');
    expect(notice.description, 'Qualcosa è andato storto, riprova');
  });

  testWidgets('a recovery or no-effect refusal does not reread the character '
      '(D-11)', (tester) async {
    await pumpListener(tester);

    await emit(
      tester,
      refused(
        ItemUseFailure.potionRecovering,
        recoveryUntil: spellFixtureNow.add(const Duration(minutes: 30)),
      ),
    );
    await emit(tester, refused(ItemUseFailure.noEffect, sequence: 2));

    verifyNever(() => characterCubit.refreshCharacter());
  });

  testWidgets('mounting with a refusal already in the state publishes nothing '
      '(D-18)', (tester) async {
    await pumpListener(tester, initialState: refused(ItemUseFailure.noEffect));
    await tester.pump();

    verifyNoNotice();
    verifyNever(() => characterCubit.refreshCharacter());
  });
}
