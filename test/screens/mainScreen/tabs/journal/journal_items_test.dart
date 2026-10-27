import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';

import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

const _potion = {
  'item': {
    'id': 'l-heal',
    'name': 'Pozione',
    'description': 'Cura le ferite',
    'effect': 'heal',
    'power': 12,
  },
  'quantity': 2,
};

const _bread = {
  'item': {
    'id': 'l-food',
    'name': 'Pane',
    'description': 'Sfama il viaggiatore',
    'effect': 'hunger',
    'power': 5,
  },
  'quantity': 1,
};

const _stone = {
  'item': {
    'id': 'l-stone',
    'name': 'Pietra',
    'description': 'Una pietra liscia',
  },
  'quantity': 1,
};

Character _characterOwning(List<Map<String, dynamic>> ownedItems) =>
    journalCharacter(
      spellbook: spellbookCharacterJson(),
      ownedItems: ownedItems,
    );

Finder _effectFilter() => find.byType(ItemsFilter<EffectType>);

ItemsFilter<EffectType> _filter(WidgetTester tester) =>
    tester.widget<ItemsFilter<EffectType>>(_effectFilter());

Finder _chip(EffectType effect) => find.descendant(
  of: _effectFilter(),
  matching: find.byWidgetPredicate(
    (widget) => widget is CachedSvg && widget.url == effect.imagePath,
  ),
);

Finder _allChip() =>
    find.descendant(of: _effectFilter(), matching: find.text('Tutti'));

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  late StreamController<CharacterState> characterStates;

  void useCharacter(Character character) {
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(characterStates.close);
    whenListen(
      characterCubit,
      characterStates.stream,
      initialState: CharacterLoaded(character),
    );
  }

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    useCharacter(_characterOwning([_potion, _bread, _stone]));
  });

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> pumpItems(WidgetTester tester) async {
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
    );
    await tapAndSettle(tester, find.text('Oggetti'));
  }

  Future<void> emitCharacter(
    WidgetTester tester,
    List<Map<String, dynamic>> ownedItems,
  ) async {
    characterStates.add(CharacterLoaded(_characterOwning(ownedItems)));
    await tester.pumpAndSettle();
  }

  void expectDescriptions({
    required bool potion,
    required bool bread,
    required bool stone,
  }) {
    Matcher shown(bool visible) => visible ? findsOneWidget : findsNothing;
    expect(find.text('Cura le ferite'), shown(potion));
    expect(find.text('Sfama il viaggiatore'), shown(bread));
    expect(find.text('Una pietra liscia'), shown(stone));
  }

  testWidgets('the chips list the present effects and every row is shown', (
    tester,
  ) async {
    await pumpItems(tester);

    expect(_effectFilter(), findsOneWidget);
    expect(_filter(tester).values, [EffectType.heal, EffectType.hunger]);
    expect(_filter(tester).current, isNull);
    expectDescriptions(potion: true, bread: true, stone: true);
    expect(find.text('Cura: 12'), findsOneWidget);
    expect(find.text('Sazietà: 5'), findsOneWidget);
  });

  testWidgets('a chip filters the rows, «Tutti» restores them', (tester) async {
    await pumpItems(tester);

    await tapAndSettle(tester, _chip(EffectType.heal));

    expect(_filter(tester).current, EffectType.heal);
    expectDescriptions(potion: true, bread: false, stone: false);

    await tapAndSettle(tester, _allChip());

    expect(_filter(tester).current, isNull);
    expectDescriptions(potion: true, bread: true, stone: true);
  });

  testWidgets('a vanished effect falls back to «Tutti» for good', (
    tester,
  ) async {
    await pumpItems(tester);
    await tapAndSettle(tester, _chip(EffectType.hunger));
    expectDescriptions(potion: false, bread: true, stone: false);

    await emitCharacter(tester, [_potion, _stone]);

    expect(_filter(tester).current, isNull);
    expect(_filter(tester).values, [EffectType.heal]);
    expectDescriptions(potion: true, bread: false, stone: true);

    await emitCharacter(tester, [_potion, _bread, _stone]);

    expect(_filter(tester).current, isNull);
    expectDescriptions(potion: true, bread: true, stone: true);
  });

  testWidgets('an effect gone between two frames still falls back (WR-01)', (
    tester,
  ) async {
    await pumpItems(tester);
    await tapAndSettle(tester, _chip(EffectType.hunger));

    characterStates
      ..add(CharacterLoaded(_characterOwning([_potion, _stone])))
      ..add(CharacterLoaded(_characterOwning([_potion, _bread, _stone])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_filter(tester).current, isNull);
    expectDescriptions(potion: true, bread: true, stone: true);
  });

  testWidgets('without owned items no chip row is shown', (tester) async {
    useCharacter(_characterOwning(const []));

    await pumpItems(tester);

    expect(tester.takeException(), isNull);
    expect(_effectFilter(), findsNothing);
  });
}
