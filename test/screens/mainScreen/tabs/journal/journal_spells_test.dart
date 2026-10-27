import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/popup/spell_info_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/spells_harness.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

/// Icona dei punti vita: URL letterale in `journal.dart`, fuori da `CloudinaryAssets`.
const _healEffectUrl =
    'https://res.cloudinary.com/dzuhywp53/image/upload/v1757660480/healEffect_jc9bsg.svg';

Map<String, dynamic> _spellJson(String letter) =>
    spellJson(id: 'spell-$letter', name: 'Magia $letter');

/// Personaggio completo per tutte le sezioni del Diario; A attiva, B no.
Character _journalCharacter() {
  final json = spellbookCharacterJson(
    spells: [_spellJson('a'), _spellJson('b')],
    activeSpells: [
      activeSpellJson(spellId: 'spell-a', usages: 1, spell: _spellJson('a')),
    ],
    spellStates: [
      spellStateJson(spellId: 'spell-a'),
      spellStateJson(spellId: 'spell-b', usages: 3, recoveries: const []),
    ],
  );
  return Character.fromJson({
    ...json,
    'infos': {'name': 'Aria', 'sex': 'male'},
    'status': {
      ...json['status'] as Map<String, dynamic>,
      'xp': 120,
      'currentLifePoints': 10,
      'maxLifePoints': 12,
      'coins': {'gold': 1, 'silver': 2, 'copper': 3},
      'injuries': <String>[],
    },
    'assets': {
      ...json['assets'] as Map<String, dynamic>,
      'wearedEquipment': <String, dynamic>{},
      'ownedEquipments': <Map<String, dynamic>>[],
      'ownedItems': <Map<String, dynamic>>[],
    },
  });
}

void _seedJournalSvgs() {
  seedSpellSvgs();
  seedSvgCache([
    CloudinaryAssets.goldCoin,
    CloudinaryAssets.silverCoin,
    CloudinaryAssets.copperCoin,
  ]);
  final svg =
      File('${Directory.systemTemp.createTempSync('kg_svg').path}/j.svg')
        ..writeAsStringSync(
          '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
        );
  SvgCache().add(_healEffectUrl, svg);
  SvgCache().add(SexType.male.mannequinPath, svg);
}

Finder _row(String letter) => find.byKey(ValueKey('spell-row-spell-$letter'));

Finder _slot(String letter) => find.byKey(ValueKey('spell-slot-spell-$letter'));

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  final character = _journalCharacter();

  setUpAll(() => registerFallbackValue(spellbookCharacter()));

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(character),
    );
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    when(
      () => spellsCubit.toggle(any(), any()),
    ).thenReturn(SpellToggleIntent.equip);
  });

  Future<void> pumpJournal(WidgetTester tester) async {
    useLandscapePhone(tester);
    _seedJournalSvgs();
    await tester.pumpWidget(
      buildTestApp(
        home: RepositoryProvider<ServerClockService>.value(
          value: FakeServerClockService(spellFixtureNow),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<SpellsCubit>.value(value: spellsCubit),
            ],
            child: const Scaffold(body: Journal()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSpells(WidgetTester tester) async {
    final header = find.text('Magie imparate');
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
  }

  Future<void> longPressAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.longPress(target);
    await tester.pumpAndSettle();
  }

  SpellInfoSheet sheet(WidgetTester tester) =>
      tester.widget<SpellInfoSheet>(find.byType(SpellInfoSheet));

  testWidgets('the journal shows the extracted spells section', (tester) async {
    await pumpJournal(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Magie imparate'), findsOneWidget);
  });

  testWidgets('long-pressing a row raises the spell sheet on the right', (
    tester,
  ) async {
    await pumpJournal(tester);
    await openSpells(tester);

    await longPressAndSettle(tester, _row('b'));

    expect(find.byType(SpellInfoSheet), findsOneWidget);
    expect(sheet(tester).spell.id, 'spell-b');
    expect(sheet(tester).isActive, isFalse);
    final position = tester.widget<Positioned>(
      find.ancestor(
        of: find.byType(SpellInfoSheet),
        matching: find.byType(Positioned),
      ),
    );
    expect(position.top, 0);
    expect(position.right, 0);
  });

  testWidgets('the sheet ribbon toggles the spell', (tester) async {
    await pumpJournal(tester);
    await openSpells(tester);
    await longPressAndSettle(tester, _row('b'));

    await tester.tap(
      find.descendant(
        of: find.descendant(
          of: find.byType(SpellInfoSheet),
          matching: find.byType(BookmarkRibbon),
        ),
        matching: find.byType(RotatedBox),
      ),
    );
    await tester.pump();

    verify(() => spellsCubit.toggle(character, 'spell-b')).called(1);
  });

  testWidgets('a tap outside the sheet closes it', (tester) async {
    await pumpJournal(tester);
    await openSpells(tester);
    await longPressAndSettle(tester, _row('b'));

    await tester.tapAt(const Offset(20, 200));
    await tester.pumpAndSettle();

    expect(find.byType(SpellInfoSheet), findsNothing);
  });

  testWidgets('long-pressing a slot card opens the sheet of that spell', (
    tester,
  ) async {
    await pumpJournal(tester);
    await openSpells(tester);

    await longPressAndSettle(tester, _slot('a'));

    expect(sheet(tester).spell.id, 'spell-a');
    expect(sheet(tester).isActive, isTrue);
    expect(sheet(tester).usages, 1);
  });
}
