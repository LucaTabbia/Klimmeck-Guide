import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';

import 'fakes/fake_server_clock_service.dart';
import 'fixtures/spell_fixtures.dart';
import 'landscape.dart';
import 'spells_harness.dart';
import 'svg_cache_seed.dart';
import 'test_app.dart';

/// Icona dei punti vita: URL letterale in `journal.dart`, fuori da `CloudinaryAssets`.
const _healEffectUrl =
    'https://res.cloudinary.com/dzuhywp53/image/upload/v1757660480/healEffect_jc9bsg.svg';

/// Personaggio completo per tutte le sezioni del Diario.
///
/// [spellbook] è una mappa di `spellbookCharacterJson(...)`; [ownedItems] sono
/// le voci `{'item': …, 'quantity': …}` della sezione «Oggetti».
Character journalCharacter({
  required Map<String, dynamic> spellbook,
  List<Map<String, dynamic>> ownedItems = const [],
}) => Character.fromJson({
  ...spellbook,
  'infos': {'name': 'Aria', 'sex': 'male'},
  'status': {
    ...spellbook['status'] as Map<String, dynamic>,
    'xp': 120,
    'currentLifePoints': 10,
    'maxLifePoints': 12,
    'coins': {'gold': 1, 'silver': 2, 'copper': 3},
    'injuries': <String>[],
  },
  'assets': {
    ...spellbook['assets'] as Map<String, dynamic>,
    'wearedEquipment': <String, dynamic>{},
    'ownedEquipments': <Map<String, dynamic>>[],
    'ownedItems': ownedItems,
  },
});

/// SVG di tutte le sezioni del Diario: magie, monete, effetti, manichino.
void seedJournalSvgs() {
  seedSpellSvgs();
  seedSvgCache([
    CloudinaryAssets.goldCoin,
    CloudinaryAssets.silverCoin,
    CloudinaryAssets.copperCoin,
    CloudinaryAssets.noneEffect,
    CloudinaryAssets.healEffect,
    CloudinaryAssets.hungerEffect,
    CloudinaryAssets.munitionEffect,
    CloudinaryAssets.explorationEffect,
  ]);
  final svg =
      File('${Directory.systemTemp.createTempSync('kg_svg').path}/j.svg')
        ..writeAsStringSync(
          '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
        );
  SvgCache().add(_healEffectUrl, svg);
  SvgCache().add(SexType.male.mannequinPath, svg);
}

/// Il Diario intero con i provider che legge, in landscape, ad animazioni finite.
Future<void> pumpJournalPage(
  WidgetTester tester, {
  required CharacterCubit characterCubit,
  required SpellsCubit spellsCubit,
}) async {
  useLandscapePhone(tester);
  seedJournalSvgs();
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
