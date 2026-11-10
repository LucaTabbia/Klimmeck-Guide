import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/potion_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/potion_fixtures.dart';
import '../../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/journal_harness.dart';
import '../../../../../helpers/mocks.dart';

const String _herb = 'l-herb';
const String _balm = 'l-balm';
const String _plain = 'l-plain';
const String _food = 'l-food';
const String _readyIn72 = 'pronta fra 1 h 12 min';

const Map<String, dynamic> _bread = {
  'item': {
    'id': _food,
    'name': 'Pane',
    'description': 'Sfama il viaggiatore',
    'effect': 'hunger',
    'power': 5,
  },
  'quantity': 1,
};

String _recoveryEndIn(Duration delta) =>
    spellFixtureNow.add(delta).toIso8601String();

List<Map<String, dynamic>> _ownedItems({int herbQuantity = 2}) => [
  ownedHealPotionJson(quantity: herbQuantity),
  ownedHealPotionJson(
    item: healPotionJson(id: _balm, name: 'Balsamo'),
  ),
  ownedHealPotionJson(
    item: healPotionJson(id: _plain, name: 'Unguento', recovery: null),
  ),
  _bread,
];

Character _character({
  int herbQuantity = 2,
  String? potionRecoveryUntil,
  Map<String, dynamic>? awaitingAid,
  Map<String, dynamic>? activeTravel,
}) => journalCharacter(
  spellbook: spellbookCharacterJson(),
  ownedItems: _ownedItems(herbQuantity: herbQuantity),
  potionRecoveryUntil: potionRecoveryUntil,
  awaitingAid: awaitingAid,
  activeTravel: activeTravel,
);

Finder _card(String id) => find.byKey(ValueKey(id));

Finder _statusOf(String id) => find.byKey(ValueKey('item-status-$id'));

String? _statusTextOf(WidgetTester tester, String id) =>
    tester.widget<Text>(_statusOf(id)).data;

double _opacityOf(WidgetTester tester, String id) => tester
    .widget<AnimatedOpacity>(find.byKey(ValueKey('item-card-opacity-$id')))
    .opacity;

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  late MockPotionCubit potionCubit;
  late FakeServerClockService clock;
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
    potionCubit = MockPotionCubit();
    clock = FakeServerClockService(spellFixtureNow);
    addTearDown(clock.dispose);
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    whenListen(
      potionCubit,
      const Stream<PotionState>.empty(),
      initialState: const PotionIdle(),
    );
    when(() => potionCubit.drink(any())).thenAnswer((_) async {});
    when(() => characterCubit.refreshCharacter()).thenAnswer((_) async {});
    useCharacter(_character());
  });

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> pumpItems(WidgetTester tester) async {
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
      potionCubit: potionCubit,
      clock: clock,
    );
    await tapAndSettle(tester, find.text('Oggetti'));
  }

  /// Chiude la sezione e con lei il countdown: nessun timer resta appeso.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('a heal parchment with a recovery opens the potion sheet '
      '(D-11, D-18)', (tester) async {
    await pumpItems(tester);

    await tapAndSettle(tester, _card(_herb));

    expect(
      find.descendant(
        of: find.byType(PaperSheetModal),
        matching: find.text('Bevi Erbe da campo?'),
      ),
      findsOneWidget,
    );
    verifyNever(() => potionCubit.drink(any()));
  });

  testWidgets('opening the sheet resets a previous outcome first (D-18)', (
    tester,
  ) async {
    await pumpItems(tester);

    await tapAndSettle(tester, _card(_herb));

    verify(() => potionCubit.reset()).called(1);
  });

  testWidgets('a heal item without recovery and a non-heal item open nothing '
      '(D-11)', (tester) async {
    await pumpItems(tester);

    await tapAndSettle(tester, _card(_plain));
    expect(find.byType(PotionSheet), findsNothing);

    await tapAndSettle(tester, _card(_food));
    expect(find.byType(PotionSheet), findsNothing);
    verifyNever(() => potionCubit.reset());
  });

  testWidgets('with a recovery end in the future every heal parchment is '
      'dimmed with pronta fra … (D-12)', (tester) async {
    useCharacter(
      _character(
        potionRecoveryUntil: _recoveryEndIn(const Duration(minutes: 72)),
      ),
    );

    await pumpItems(tester);

    expect(find.text(_readyIn72), findsNWidgets(2));
    for (final id in [_herb, _balm]) {
      expect(_statusTextOf(tester, id), _readyIn72, reason: id);
      expect(
        _opacityOf(tester, id),
        KlimmeckGuideTheme.pendingInkOpacity,
        reason: id,
      );
    }
    expect(_statusOf(_plain), findsNothing);
    expect(_statusOf(_food), findsNothing);
    expect(_opacityOf(tester, _plain), 1);
    await unmount(tester);
  });

  testWidgets('a tap during the countdown makes no call and opens nothing '
      '(D-12)', (tester) async {
    useCharacter(
      _character(
        potionRecoveryUntil: _recoveryEndIn(const Duration(minutes: 72)),
      ),
    );
    await pumpItems(tester);

    await tapAndSettle(tester, _card(_herb));

    expect(find.byType(PotionSheet), findsNothing);
    verifyNever(() => potionCubit.drink(any()));
    verifyNever(() => potionCubit.reset());
    await unmount(tester);
  });

  testWidgets('the countdown follows the server clock and the parchments come '
      'back when it ends (D-12)', (tester) async {
    useCharacter(
      _character(
        potionRecoveryUntil: _recoveryEndIn(const Duration(minutes: 72)),
      ),
    );
    await pumpItems(tester);
    expect(find.text(_readyIn72), findsNWidgets(2));

    clock.advance(const Duration(minutes: 72));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(_statusOf(_herb), findsNothing);
    expect(_statusOf(_balm), findsNothing);
    expect(_opacityOf(tester, _herb), 1);

    await tapAndSettle(tester, _card(_herb));

    expect(find.byType(PotionSheet), findsOneWidget);
  });

  testWidgets('a past recovery end leaves the parchments enabled (D-12)', (
    tester,
  ) async {
    useCharacter(
      _character(
        potionRecoveryUntil: _recoveryEndIn(const Duration(minutes: -5)),
      ),
    );
    await pumpItems(tester);

    expect(find.textContaining('pronta fra'), findsNothing);
    expect(_opacityOf(tester, _herb), 1);

    await tapAndSettle(tester, _card(_balm));

    expect(find.text('Bevi Balsamo?'), findsOneWidget);
  });

  testWidgets('a new character from the stream updates stack and countdown '
      'with no reread (D-11)', (tester) async {
    await pumpItems(tester);
    expect(
      find.descendant(
        of: _card(_herb),
        matching: find.byKey(const ValueKey<int>(2)),
      ),
      findsOneWidget,
    );

    characterStates.add(
      CharacterLoaded(
        _character(
          herbQuantity: 1,
          potionRecoveryUntil: _recoveryEndIn(const Duration(minutes: 72)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: _card(_herb),
        matching: find.byKey(const ValueKey<int>(1)),
      ),
      findsOneWidget,
    );
    expect(_statusTextOf(tester, _herb), _readyIn72);
    verifyNever(() => characterCubit.refreshCharacter());
    await unmount(tester);
  });

  testWidgets('while awaiting aid the heal parchments are not tappable and '
      'show no countdown (D-11)', (tester) async {
    for (final recoveryEnd in [
      null,
      _recoveryEndIn(const Duration(minutes: 72)),
    ]) {
      useCharacter(
        _character(
          awaitingAid: awaitingAidJson(),
          potionRecoveryUntil: recoveryEnd,
        ),
      );
      await pumpItems(tester);

      expect(_statusOf(_herb), findsNothing, reason: '$recoveryEnd');
      expect(_statusOf(_balm), findsNothing, reason: '$recoveryEnd');
      expect(_opacityOf(tester, _herb), 1, reason: '$recoveryEnd');

      await tapAndSettle(tester, _card(_herb));

      expect(find.byType(PotionSheet), findsNothing, reason: '$recoveryEnd');
      await unmount(tester);
    }
    verifyNever(() => potionCubit.reset());
    verifyNever(() => potionCubit.drink(any()));
  });

  testWidgets('in travel the heal parchments stay tappable (D-11)', (
    tester,
  ) async {
    useCharacter(_character(activeTravel: activeTravelJson()));
    await pumpItems(tester);

    await tapAndSettle(tester, _card(_herb));

    expect(find.byType(PotionSheet), findsOneWidget);
  });

  testWidgets("the sheet receives the character's maximum life (D-18)", (
    tester,
  ) async {
    await pumpItems(tester);

    await tapAndSettle(tester, _card(_herb));

    expect(
      tester.widget<PotionSheet>(find.byType(PotionSheet)).maxLifePoints,
      12,
    );
  });
}
