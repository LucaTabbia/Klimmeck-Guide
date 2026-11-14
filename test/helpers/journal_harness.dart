import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/potion_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';

import 'fakes/fake_server_clock_service.dart';
import 'fixtures/spell_fixtures.dart';
import 'landscape.dart';
import 'mocks.dart';
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
/// [potionRecoveryUntil], [awaitingAid] e [activeTravel] entrano nello status
/// solo se passati.
Character journalCharacter({
  required Map<String, dynamic> spellbook,
  List<Map<String, dynamic>> ownedItems = const [],
  List<String> injuries = const [],
  String? potionRecoveryUntil,
  Map<String, dynamic>? awaitingAid,
  Map<String, dynamic>? activeTravel,
}) => Character.fromJson({
  ...spellbook,
  'infos': {'name': 'Aria', 'sex': 'male'},
  'status': {
    ...spellbook['status'] as Map<String, dynamic>,
    'xp': 120,
    'currentLifePoints': 10,
    'maxLifePoints': 12,
    'coins': {'gold': 1, 'silver': 2, 'copper': 3},
    'injuries': injuries,
    'potionRecoveryUntil': ?potionRecoveryUntil,
    'awaitingAid': ?awaitingAid,
    'activeTravel': ?activeTravel,
  },
  'assets': {
    ...spellbook['assets'] as Map<String, dynamic>,
    'wornEquipment': <String, dynamic>{},
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
    CloudinaryAssets.bottomEmptySheet,
  ]);
  final svg =
      File('${Directory.systemTemp.createTempSync('kg_svg').path}/j.svg')
        ..writeAsStringSync(
          '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
        );
  SvgCache().add(_healEffectUrl, svg);
  SvgCache().add(SexType.male.mannequinPath, svg);
}

/// Slot «Compagno» a riposo: nessuna operazione in attesa.
CompanionCubit idleCompanionCubit() {
  final cubit = MockCompanionCubit();
  whenListen(
    cubit,
    const Stream<CompanionState>.empty(),
    initialState: const CompanionState(),
  );
  return cubit;
}

/// Nessuna bevuta in corso.
PotionCubit idlePotionCubit() {
  final cubit = MockPotionCubit();
  whenListen(
    cubit,
    const Stream<PotionState>.empty(),
    initialState: const PotionIdle(),
  );
  return cubit;
}

/// Nessun cambio di equipaggiamento rifiutato.
JournalCubit idleJournalCubit() {
  final cubit = MockJournalCubit();
  whenListen(
    cubit,
    const Stream<JournalState>.empty(),
    initialState: const JournalIdle(),
  );
  return cubit;
}

/// Il Diario intero con i provider che legge, in landscape, ad animazioni finite.
/// Come in produzione, il Diario sta sotto PotionOutcomeListener: i banner dei
/// rifiuti vanno a [notices].
Future<void> pumpJournalPage(
  WidgetTester tester, {
  required CharacterCubit characterCubit,
  required SpellsCubit spellsCubit,
  CompanionCubit? companionCubit,
  PotionCubit? potionCubit,
  JournalCubit? journalCubit,
  InAppNotificationsCubit? notices,
  FakeServerClockService? clock,
}) async {
  useLandscapePhone(tester);
  seedJournalSvgs();
  await tester.pumpWidget(
    buildTestApp(
      home: RepositoryProvider<ServerClockService>.value(
        value: clock ?? FakeServerClockService(spellFixtureNow),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<SpellsCubit>.value(value: spellsCubit),
            BlocProvider<CompanionCubit>.value(
              value: companionCubit ?? idleCompanionCubit(),
            ),
            BlocProvider<PotionCubit>.value(
              value: potionCubit ?? idlePotionCubit(),
            ),
            BlocProvider<JournalCubit>.value(
              value: journalCubit ?? idleJournalCubit(),
            ),
            BlocProvider<InAppNotificationsCubit>.value(
              value: notices ?? MockInAppNotificationsCubit(),
            ),
          ],
          child: const PotionOutcomeListener(child: Scaffold(body: Journal())),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
