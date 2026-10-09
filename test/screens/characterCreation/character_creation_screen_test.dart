import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/character_creation_screen.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fixtures/race_traits_fixture.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockCharacterCreationCubit cubit;
  late MockAuthCubit authCubit;

  const validDraft = CharacterDraft(
    sex: SexType.female,
    name: 'Aria',
    pronoun: PronounType.she,
    race: RaceType.elf,
    classType: ClassType.wizard,
    ageText: '150',
  );
  final loadedState = CharacterCreationState(
    raceTraits: testRaceTraits,
    raceTraitsStatus: RaceTraitsStatus.loaded,
  );

  setUpAll(() => registerFallbackValue(buildTestUser()));

  setUp(() {
    cubit = MockCharacterCreationCubit();
    authCubit = MockAuthCubit();
    when(() => authCubit.logout()).thenAnswer((_) async {});
    when(() => authCubit.adoptUser(any())).thenReturn(null);
    when(() => cubit.loadRaceTraits()).thenAnswer((_) async {});
    when(() => cubit.submit()).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    CharacterCreationState state, {
    Stream<CharacterCreationState>? updates,
  }) async {
    useLandscapePhone(tester);
    whenListen(
      cubit,
      updates ?? const Stream<CharacterCreationState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<CharacterCreationCubit>.value(value: cubit),
        ],
        child: buildTestApp(home: const CharacterCreationScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the sheet in landscape without overflow', (
    tester,
  ) async {
    await pumpScreen(tester, loadedState);

    expect(find.text('Il tuo personaggio'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
    for (final row in [
      'Sesso',
      'Pronome',
      'Razza',
      'Classe',
      'Storia',
      'Ritratto',
    ]) {
      expect(find.text(row), findsWidgets, reason: row);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow with the keyboard open', (tester) async {
    await pumpScreen(tester, loadedState);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);

    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing is preselected', (tester) async {
    await pumpScreen(tester, loadedState);

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.where((chip) => chip.selected), isEmpty);
  });

  testWidgets('tapping a race chip and typing the name drive the cubit', (
    tester,
  ) async {
    await pumpScreen(tester, loadedState);
    await tester.ensureVisible(find.text('Elfo'));
    await tester.tap(find.text('Elfo'));
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Aria');

    verify(() => cubit.selectRace(RaceType.elf)).called(1);
    verify(() => cubit.updateName('Aria')).called(1);
  });

  testWidgets('age is disabled until a race is chosen', (tester) async {
    await pumpScreen(tester, loadedState);

    final age = tester.widget<TextField>(find.widgetWithText(TextField, 'Età'));
    expect(age.enabled, isFalse);
    expect(find.text('Scegli prima la razza'), findsOneWidget);
  });

  testWidgets('failed race traits offer a retry', (tester) async {
    await pumpScreen(
      tester,
      const CharacterCreationState(raceTraitsStatus: RaceTraitsStatus.failed),
    );

    expect(
      find.text('Non riesco a leggere le età delle razze'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Riprova'));
    await tester.tap(find.text('Riprova'));
    verify(() => cubit.loadRaceTraits()).called(1);
  });

  testWidgets('an out-of-range age shows the inline race range', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      loadedState.copyWith(
        draft: const CharacterDraft(race: RaceType.elf, ageText: '30'),
      ),
    );

    expect(
      find.text("Per la razza Elfo l'età va da 100 a 9999 anni"),
      findsOneWidget,
    );
  });

  testWidgets('Crea is disabled until the sheet is valid', (tester) async {
    await pumpScreen(tester, loadedState);

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Crea submits when the sheet is valid', (tester) async {
    await pumpScreen(tester, loadedState.copyWith(draft: validDraft));

    await tester.ensureVisible(find.text('Crea'));
    await tester.tap(find.text('Crea'));

    verify(() => cubit.submit()).called(1);
  });

  testWidgets('while submitting everything is locked with one inline spinner', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      loadedState.copyWith(draft: validDraft, isSubmitting: true),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final esci = find.widgetWithText(TextButton, 'Esci');
    expect(tester.widget<TextButton>(esci).onPressed, isNull);
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.every((chip) => chip.onSelected == null), isTrue);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.enabled == false), isTrue);
  });

  testWidgets('a submit failure keeps the typed text', (tester) async {
    final updates = StreamController<CharacterCreationState>();
    addTearDown(updates.close);
    await pumpScreen(tester, loadedState, updates: updates.stream);
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Aria');

    updates.add(
      loadedState.copyWith(
        draft: const CharacterDraft(name: 'Aria'),
        submitFailure: CharacterCreationFailure.nameTaken,
      ),
    );
    await tester.pump();

    expect(find.text('Nome già in uso'), findsOneWidget);
    expect(find.text('Aria'), findsOneWidget);
  });

  testWidgets('a created user is handed to AuthCubit.adoptUser once', (
    tester,
  ) async {
    final user = buildTestUserWithCharacter();
    await pumpScreen(
      tester,
      loadedState,
      updates: Stream.value(loadedState.copyWith(createdUser: user)),
    );
    await tester.pump();

    verify(() => authCubit.adoptUser(user)).called(1);
  });

  testWidgets('Esci asks for confirmation and then logs out', (tester) async {
    await pumpScreen(tester, loadedState);

    await tester.tap(find.widgetWithText(TextButton, 'Esci'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sei sicuro di voler uscire?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Esci'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => authCubit.logout()).called(1);
  });
}
