import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/library_news_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/newsCubit/library_news_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

CharacterLoaded characterWith(
  List<String> unlockedLore, {
  int currentLifePoints = 900,
}) {
  final json = travellingCharacterJson();
  final status = json['status'] as Map<String, dynamic>;
  status['unlockedLore'] = unlockedLore;
  status['currentLifePoints'] = currentLifePoints;
  return CharacterLoaded(Character.fromJson(json));
}

void main() {
  late MockCharacterCubit characterCubit;
  late MockLibraryNewsCubit newsCubit;
  late StreamController<CharacterState> characterStates;

  setUp(() {
    characterCubit = MockCharacterCubit();
    newsCubit = quietLibraryNewsCubit();
    characterStates = StreamController<CharacterState>.broadcast();
  });

  tearDown(() => characterStates.close());

  Future<void> pumpListener(
    WidgetTester tester, {
    required CharacterState character,
  }) async {
    whenListen(characterCubit, characterStates.stream, initialState: character);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<LibraryNewsCubit>.value(value: newsCubit),
          ],
          child: const LibraryNewsListener(child: SizedBox.shrink()),
        ),
      ),
    );
  }

  testWidgets('counts the news of the character already loaded', (
    tester,
  ) async {
    await pumpListener(tester, character: characterWith(['lore-andogan']));

    verify(() => newsCubit.syncUnlockedLore(['lore-andogan'])).called(1);
  });

  testWidgets('counts again only when the unlocked lore change', (
    tester,
  ) async {
    await pumpListener(tester, character: characterWith(['lore-andogan']));
    clearInteractions(newsCubit);

    characterStates.add(
      characterWith(['lore-andogan'], currentLifePoints: 100),
    );
    await tester.pump();
    verifyNever(() => newsCubit.syncUnlockedLore(any()));

    characterStates.add(characterWith(['lore-andogan', 'lore-bosa']));
    await tester.pump();
    verify(
      () => newsCubit.syncUnlockedLore(['lore-andogan', 'lore-bosa']),
    ).called(1);
  });
}
