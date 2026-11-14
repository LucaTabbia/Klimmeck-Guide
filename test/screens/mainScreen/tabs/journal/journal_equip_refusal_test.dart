import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  late MockJournalCubit journalCubit;
  late MockInAppNotificationsCubit notices;
  late StreamController<JournalState> journalStates;

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    journalCubit = MockJournalCubit();
    notices = MockInAppNotificationsCubit();
    journalStates = StreamController<JournalState>();
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        journalCharacter(spellbook: spellbookCharacterJson()),
      ),
    );
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    whenListen(
      journalCubit,
      journalStates.stream,
      initialState: const JournalIdle(),
    );
  });

  tearDown(() => journalStates.close());

  Future<void> pumpJournal(WidgetTester tester) => pumpJournalPage(
    tester,
    characterCubit: characterCubit,
    spellsCubit: spellsCubit,
    journalCubit: journalCubit,
    notices: notices,
  );

  testWidgets(
    'a refused equip publishes «Equipaggiamento non cambiato» with the '
    'wait line (D-30)',
    (tester) async {
      await pumpJournal(tester);

      journalStates.add(
        const JournalEquipRefused(
          failure: EquipmentFailure.missionInProgress,
          sequence: 1,
        ),
      );
      await tester.pump();

      verify(
        () => notices.publishNotice(
          const KGNotification(
            title: 'Equipaggiamento non cambiato',
            description: missionInProgressRefusalLine,
          ),
          dedupKey: 'equip|missionInProgress|1',
        ),
      ).called(1);
    },
  );

  testWidgets('an unauthenticated refusal publishes nothing', (tester) async {
    await pumpJournal(tester);

    journalStates.add(
      const JournalEquipRefused(
        failure: EquipmentFailure.unauthenticated,
        sequence: 1,
      ),
    );
    await tester.pump();

    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
  });
}
