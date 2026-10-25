import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  const openSheetKey = ValueKey('test.openSheet');
  final quest = buildQuest(id: 'q-1', type: 'boss', title: 'Il drago rosso');

  late MockQuestAbandonCubit cubit;
  late StreamController<QuestAbandonState> states;

  setUp(() {
    cubit = MockQuestAbandonCubit();
    states = StreamController<QuestAbandonState>.broadcast();
    when(
      () => cubit.abandon(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).thenAnswer((_) async {});
    seedSvgCache([CloudinaryAssets.bottomEmptySheet]);
  });

  tearDown(() => states.close());

  Future<void> openSheet(
    WidgetTester tester, {
    QuestAbandonState initial = const QuestAbandonIdle(),
  }) async {
    useLandscapePhone(tester);
    whenListen(cubit, states.stream, initialState: initial);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: openSheetKey,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider<QuestAbandonCubit>.value(
                  value: cubit,
                  child: PaperSheetModal(
                    child: AbandonPartySheet(quest: quest, characterId: 'c-1'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(openSheetKey));
    await tester.pumpAndSettle();
  }

  TextButton button(WidgetTester tester, Key key) =>
      tester.widget<TextButton>(find.byKey(key));

  testWidgets('shows the quest title, the question and both actions', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Il drago rosso'), findsOneWidget);
    expect(
      find.text('Vuoi abbandonare il gruppo? Il tuo posto sarà liberato.'),
      findsOneWidget,
    );
    expect(find.text('Abbandona'), findsOneWidget);
    expect(find.text('Resta'), findsOneWidget);
  });

  testWidgets('Resta closes the sheet without abandoning', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byKey(AbandonPartySheet.stayKey));
    await tester.pumpAndSettle();

    expect(find.byType(AbandonPartySheet), findsNothing);
    verifyNever(
      () => cubit.abandon(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    );
  });

  testWidgets('Abbandona abandons the quest exactly once', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byKey(AbandonPartySheet.abandonKey));
    await tester.pump();

    verify(() => cubit.abandon(characterId: 'c-1', questId: 'q-1')).called(1);
  });

  testWidgets('while abandoning both actions are disabled', (tester) async {
    await openSheet(tester, initial: const QuestAbandoning('q-1'));

    expect(button(tester, AbandonPartySheet.abandonKey).onPressed, isNull);
    expect(button(tester, AbandonPartySheet.stayKey).onPressed, isNull);
  });

  testWidgets('back cannot dismiss an abandon in flight', (tester) async {
    await openSheet(tester, initial: const QuestAbandoning('q-1'));

    await Navigator.of(
      tester.element(find.byType(AbandonPartySheet)),
    ).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(AbandonPartySheet), findsOneWidget);
  });

  testWidgets('closes itself when the quest is abandoned', (tester) async {
    await openSheet(tester, initial: const QuestAbandoning('q-1'));

    states.add(const QuestAbandoned('q-1'));
    await tester.pumpAndSettle();

    expect(find.byType(AbandonPartySheet), findsNothing);
  });

  testWidgets('closes itself on a rejection', (tester) async {
    await openSheet(tester, initial: const QuestAbandoning('q-1'));

    states.add(const QuestAbandonFailed('q-1', QuestAbandonFailure.notWaiting));
    await tester.pumpAndSettle();

    expect(find.byType(AbandonPartySheet), findsNothing);
  });

  testWidgets('uses no app chrome and accessible actions', (tester) async {
    await openSheet(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    for (final key in [
      AbandonPartySheet.abandonKey,
      AbandonPartySheet.stayKey,
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });
}
