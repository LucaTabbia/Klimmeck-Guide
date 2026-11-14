import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/repository/pet_rename_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_name_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const Key _openKey = ValueKey('test.openNameSheet');
const String _characterId = 'c1';
const String _worg = 'pet-worg';
const double _landscapeHeight = 360;
const double _keyboardHeight = 300;

void main() {
  late MockCompanionNameCubit cubit;
  late StreamController<CompanionNameState> states;

  setUp(() {
    cubit = MockCompanionNameCubit();
    states = StreamController<CompanionNameState>.broadcast();
    addTearDown(states.close);
    when(() => cubit.reset()).thenReturn(null);
    when(
      () => cubit.rename(
        characterId: any(named: 'characterId'),
        petId: any(named: 'petId'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async {});
    seedSvgCache([CloudinaryAssets.bottomEmptySheet]);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    CompanionNameState state = const CompanionNameIdle(),
    String? initialName,
  }) async {
    useLandscapePhone(tester);
    whenListen(cubit, states.stream, initialState: state);
    await tester.pumpWidget(
      BlocProvider<CompanionNameCubit>.value(
        value: cubit,
        child: buildTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: _openKey,
                onPressed: () => showCompanionNameSheet(
                  context,
                  characterId: _characterId,
                  petId: _worg,
                  species: 'Worg',
                  initialName: initialName,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, CompanionNameState state) async {
    when(() => cubit.state).thenReturn(state);
    states.add(state);
    await tester.pumpAndSettle();
  }

  TextButton buttonOf(WidgetTester tester, Key key) =>
      tester.widget<TextButton>(find.byKey(key));

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(CompanionNameSheet.fieldKey), text);
    await tester.pump();
  }

  testWidgets('the prompt names the species (D-18)', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Come chiamerai il tuo Worg?'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Chiamalo così'), findsOneWidget);
    expect(find.text('Più tardi'), findsOneWidget);
    verify(() => cubit.reset()).called(1);
  });

  testWidgets(
    'a short or invalid name shows the character message and blocks the confirm (D-31)',
    (tester) async {
      await pumpSheet(tester);

      expect(find.byKey(CompanionNameSheet.errorKey), findsNothing);
      expect(buttonOf(tester, CompanionNameSheet.confirmKey).onPressed, isNull);

      await type(tester, 'A');
      expect(find.text('Il nome deve avere almeno 2 lettere'), findsOneWidget);
      expect(buttonOf(tester, CompanionNameSheet.confirmKey).onPressed, isNull);

      await type(tester, 'R2D2');
      expect(
        find.text('Solo lettere, spazi, apostrofi e trattini'),
        findsOneWidget,
      );
      expect(buttonOf(tester, CompanionNameSheet.confirmKey).onPressed, isNull);
    },
  );

  testWidgets('confirm sends the normalised name (D-18, D-31)', (tester) async {
    await pumpSheet(tester);

    await type(tester, '  Fe   nrir ');
    expect(find.byKey(CompanionNameSheet.errorKey), findsNothing);
    await tester.tap(find.byKey(CompanionNameSheet.confirmKey));
    await tester.pump();

    verify(
      () => cubit.rename(
        characterId: _characterId,
        petId: _worg,
        name: 'Fe nrir',
      ),
    ).called(1);
  });

  testWidgets('the field starts from the current name and confirms only a '
      'changed one (D-19)', (tester) async {
    await pumpSheet(tester, initialName: 'Fenrir');

    expect(
      tester
          .widget<TextField>(find.byKey(CompanionNameSheet.fieldKey))
          .controller
          ?.text,
      'Fenrir',
    );
    expect(buttonOf(tester, CompanionNameSheet.confirmKey).onPressed, isNull);

    await type(tester, '  Fenrir ');
    expect(buttonOf(tester, CompanionNameSheet.confirmKey).onPressed, isNull);

    await type(tester, 'Zanna');
    expect(
      buttonOf(tester, CompanionNameSheet.confirmKey).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'a refused name shows the notice, keeps the field and can be retried or skipped (D-21, D-31)',
    (tester) async {
      await pumpSheet(tester);
      await type(tester, 'Fenrir');
      await tester.tap(find.byKey(CompanionNameSheet.confirmKey));
      await emit(tester, const CompanionNameSubmitting(_worg));
      await emit(
        tester,
        const CompanionNameRefused(
          _worg,
          PetRenameFailure.nameInvalid,
          sequence: 1,
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(CompanionNameSheet.refusalKey)).data,
        'Il nome non è accettato dalle cronache, scegline un altro',
      );
      expect(find.byType(CompanionNameSheet), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(CompanionNameSheet.fieldKey))
            .controller
            ?.text,
        'Fenrir',
      );

      await tester.tap(find.byKey(CompanionNameSheet.confirmKey));
      await tester.pump();
      verify(
        () => cubit.rename(
          characterId: _characterId,
          petId: _worg,
          name: 'Fenrir',
        ),
      ).called(2);

      await tester.tap(find.byKey(CompanionNameSheet.skipKey));
      await tester.pumpAndSettle();
      expect(find.byType(CompanionNameSheet), findsNothing);
    },
  );

  testWidgets('a refusal for another companion is not shown here (D-31)', (
    tester,
  ) async {
    await pumpSheet(tester);
    await emit(
      tester,
      const CompanionNameRefused(
        'pet-owl',
        PetRenameFailure.nameInvalid,
        sequence: 1,
      ),
    );

    expect(find.byKey(CompanionNameSheet.refusalKey), findsNothing);
  });

  testWidgets('editing again clears the notice (review lesson)', (
    tester,
  ) async {
    await pumpSheet(tester);
    await emit(
      tester,
      const CompanionNameRefused(
        _worg,
        PetRenameFailure.nameInvalid,
        sequence: 1,
      ),
    );
    clearInteractions(cubit);

    await type(tester, 'Fenrir');

    verify(() => cubit.reset()).called(1);
  });

  testWidgets('«Più tardi» closes without a request (D-18)', (tester) async {
    await pumpSheet(tester);
    await type(tester, 'Fenrir');

    await tester.tap(find.byKey(CompanionNameSheet.skipKey));
    await tester.pumpAndSettle();

    expect(find.byType(CompanionNameSheet), findsNothing);
    verifyNever(
      () => cubit.rename(
        characterId: any(named: 'characterId'),
        petId: any(named: 'petId'),
        name: any(named: 'name'),
      ),
    );
  });

  testWidgets('a saved name closes the sheet (D-18)', (tester) async {
    await pumpSheet(tester);
    await emit(tester, const CompanionNameSubmitting(_worg));

    await emit(tester, const CompanionNameSaved(_worg, sequence: 1));

    expect(find.byType(CompanionNameSheet), findsNothing);
  });

  testWidgets(
    'actions are disabled and the sheet cannot be popped while submitting (single-flight)',
    (tester) async {
      await pumpSheet(tester);
      await type(tester, 'Fenrir');
      await emit(tester, const CompanionNameSubmitting(_worg));

      expect(buttonOf(tester, CompanionNameSheet.confirmKey).onPressed, isNull);
      expect(buttonOf(tester, CompanionNameSheet.skipKey).onPressed, isNull);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(CompanionNameSheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CompanionNameSheet), findsOneWidget);
    },
  );

  testWidgets(
    'with the keyboard open in landscape the field stays visible and nothing overflows (Pitfall 6)',
    (tester) async {
      await pumpSheet(tester);
      tester.view.viewInsets = const FakeViewPadding(
        bottom: _keyboardHeight * 3,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byKey(CompanionNameSheet.fieldKey));
      expect(field.top, greaterThanOrEqualTo(0));
      expect(
        field.bottom,
        lessThanOrEqualTo(_landscapeHeight - _keyboardHeight),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no Material dialog or AppBar on the sheet (rule 1)', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byType(CompanionNameSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(SimpleDialog), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CompanionNameSheet),
        matching: find.byType(Scaffold),
      ),
      findsNothing,
    );
  });
}
