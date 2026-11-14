import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

const String _sword = 'e-sword';
const String _missionLine = 'Missione in corso';

Finder _armourRow() => find.ancestor(
  of: find.byKey(const ValueKey(_sword)),
  matching: find.byType(ItemRow),
);

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  late MockEquipmentRepository repository;
  late JournalCubit journalCubit;

  setUpAll(() {
    registerFallbackValue(
      EquipItemRequest(
        id: 'c-1',
        itemId: 'e-1',
        slotType: SlotType.values.first,
      ),
    );
  });

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    repository = MockEquipmentRepository();
    journalCubit = JournalCubit(repository);
    addTearDown(journalCubit.close);
    when(() => repository.equip(any())).thenAnswer((_) async {});
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
  });

  Future<void> pumpArmour(
    WidgetTester tester, {
    required bool missionInProgress,
  }) async {
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        journalCharacter(
          spellbook: spellbookCharacterJson(),
          wornEquipment: {'rightHand': equipmentAssetJson(id: _sword)['item']},
          ownedEquipments: [equipmentAssetJson(id: _sword)],
          missionInProgress: missionInProgress,
        ),
      ),
    );
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
      journalCubit: journalCubit,
    );
    await tester.ensureVisible(find.text('Armatura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armatura'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSword(WidgetTester tester) async {
    final card = find.byKey(const ValueKey(_sword));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('an armour row is disabled with «Missione in corso» during a '
      'mission (D-12, D-30)', (tester) async {
    await pumpArmour(tester, missionInProgress: true);

    final row = tester.widget<ItemRow>(_armourRow());
    expect(row.isDisabled, isTrue);
    expect(row.statusLine, _missionLine);
    expect(row.onSelect, isNull);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('item-status-$_sword')))
          .data,
      _missionLine,
    );

    await tapSword(tester);

    verifyNever(() => repository.equip(any()));
  });

  testWidgets('without a mission the same tap sends equipItem (D-12)', (
    tester,
  ) async {
    await pumpArmour(tester, missionInProgress: false);

    final row = tester.widget<ItemRow>(_armourRow());
    expect(row.isDisabled, isFalse);
    expect(row.statusLine, isNull);

    await tapSword(tester);

    verify(() => repository.equip(any())).called(1);
  });
}
