import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/library.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_data_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fakes/in_memory_library_bookmarks_store.dart';
import '../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

final Lore andogan = Lore.fromJson(
  loreJson(id: 'lore-andogan', name: 'Andogan'),
);
final Lore bosa = Lore.fromJson(loreJson(id: 'lore-bosa', name: 'Bosa'));

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
  late MockKlimmeckGraphQl graphQl;
  late MockCharacterCubit characterCubit;
  late StreamController<CharacterState> characterStates;
  late InMemoryLibraryBookmarksStore bookmarks;
  late LibraryCubit libraryCubit;
  late List<Future<List<Lore>> Function()> answers;

  void answerWith(List<Lore> lore) => answers.add(() async => lore);

  Completer<List<Lore>> holdNextAnswer() {
    final held = Completer<List<Lore>>();
    answers.add(() => held.future);
    return held;
  }

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    characterCubit = MockCharacterCubit();
    characterStates = StreamController<CharacterState>.broadcast();
    answers = [];
    when(() => graphQl.getAllLores()).thenAnswer((_) => answers.removeAt(0)());
    bookmarks = InMemoryLibraryBookmarksStore();
    libraryCubit = LibraryCubit(
      graphQl,
      bookmarks: bookmarks,
      characterId: 'c-1',
    );
  });

  tearDown(() async {
    await characterStates.close();
    await libraryCubit.close();
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    required CharacterState character,
  }) async {
    useLandscapePhone(tester);
    seedSvgCache([
      CloudinaryAssets.bestiary,
      CloudinaryAssets.locations,
      CloudinaryAssets.religions,
      CloudinaryAssets.knowledge,
      CloudinaryAssets.bookmarkRed,
      CloudinaryAssets.bookmarkGreen,
      CloudinaryAssets.bookmarkYellow,
      CloudinaryAssets.bookmarkBlue,
      CloudinaryAssets.arrowDown,
    ]);
    whenListen(characterCubit, characterStates.stream, initialState: character);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<LibraryCubit>.value(value: libraryCubit),
            ],
            child: const Library(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPlaces(WidgetTester tester) async {
    await tester.tap(find.text('Luoghi'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'forwards the unlocked ids of the character to the open book (D-05, D-12)',
    (tester) async {
      answerWith([andogan]);
      answerWith([andogan, bosa]);
      await pumpLibrary(tester, character: characterWith(['lore-andogan']));
      await openPlaces(tester);
      expect(find.text('Andogan'), findsOneWidget);
      expect(find.text('Bosa'), findsNothing);

      characterStates.add(characterWith(['lore-andogan', 'lore-bosa']));
      await tester.pumpAndSettle();

      expect(find.text('Bosa'), findsOneWidget);
      verify(() => graphQl.getAllLores()).called(2);
    },
  );

  testWidgets(
    'a live refresh shows the page throughout, without spinner or placeholder (D-05)',
    (tester) async {
      answerWith([andogan]);
      final held = holdNextAnswer();
      await pumpLibrary(tester, character: characterWith(['lore-andogan']));
      await openPlaces(tester);

      characterStates.add(characterWith(['lore-andogan', 'lore-bosa']));
      await tester.pump();

      expect(find.byType(LibraryDataPage), findsOneWidget);
      expect(find.byType(Placeholder), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      held.complete([andogan, bosa]);
      await tester.pumpAndSettle();
      expect(find.text('Bosa'), findsOneWidget);
    },
  );

  testWidgets(
    'a status change with the same unlocked set refetches nothing (D-05)',
    (tester) async {
      answerWith([andogan]);
      await pumpLibrary(tester, character: characterWith(['lore-andogan']));
      await openPlaces(tester);

      characterStates.add(
        characterWith(['lore-andogan'], currentLifePoints: 700),
      );
      await tester.pumpAndSettle();

      verify(() => graphQl.getAllLores()).called(1);
    },
  );

  testWidgets('an unlock right after mounting the tab is not missed (D-05)', (
    tester,
  ) async {
    answerWith([andogan]);
    answerWith([andogan, bosa]);
    await pumpLibrary(tester, character: characterWith(['lore-andogan']));
    await openPlaces(tester);

    characterStates.add(characterWith(['lore-andogan', 'lore-bosa']));
    await tester.pumpAndSettle();

    verify(() => graphQl.getAllLores()).called(2);
    expect((libraryCubit.state as LibraryLoadData).lore, [andogan, bosa]);
  });

  testWidgets('opening a book never shows a debug placeholder (rule 2)', (
    tester,
  ) async {
    final held = holdNextAnswer();
    await pumpLibrary(tester, character: characterWith(const []));

    await tester.tap(find.text('Luoghi'));
    await tester.pump();

    expect(libraryCubit.state, const LibraryLoading());
    expect(find.byType(Placeholder), findsNothing);

    held.complete([andogan]);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a live arrival appears in the open book marked «Nuovo» (D-05, D-07)',
    (tester) async {
      bookmarks.seen[InMemoryLibraryBookmarksStore.keyOf(
        'c-1',
        LibraryBook.places,
      )] = {
        'lore-andogan',
      };
      answerWith([andogan]);
      answerWith([andogan, bosa]);
      await pumpLibrary(tester, character: characterWith(['lore-andogan']));
      await openPlaces(tester);
      expect(find.byKey(LoreCard.newMarkKey), findsNothing);

      characterStates.add(characterWith(['lore-andogan', 'lore-bosa']));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();

      expect(find.byKey(LoreCard.newMarkKey), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
