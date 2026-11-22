import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/new_entries_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';

import '../../../helpers/fakes/in_memory_new_entries_store.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

CharacterLoaded characterWith(List<String> background, {int xp = 0}) =>
    CharacterLoaded(
      Character.fromJson({
        'id': 'c-1',
        'infos': {'name': 'Aria', 'background': background},
        'status': {'xp': xp},
      }),
    );

void main() {
  late MockCharacterCubit characterCubit;
  late InMemoryNewEntriesStore store;
  late NewEntriesCubit entries;
  late StreamController<CharacterState> characterStates;

  setUp(() {
    characterCubit = MockCharacterCubit();
    store = InMemoryNewEntriesStore();
    characterStates = StreamController<CharacterState>.broadcast();
  });

  tearDown(() => characterStates.close());

  /// Il cubit nasce nel test: la sua coda deve girare nella zona del test.
  Future<void> pumpListener(
    WidgetTester tester, {
    required CharacterState character,
  }) async {
    entries = NewEntriesCubit(store: store, characterId: 'c-1');
    addTearDown(entries.close);
    whenListen(characterCubit, characterStates.stream, initialState: character);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<NewEntriesCubit>.value(value: entries),
          ],
          child: const NewEntriesListener(child: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('records the character already loaded as the first sight', (
    tester,
  ) async {
    await pumpListener(tester, character: characterWith(['Nata a Drustea.']));

    expect(store.seenOf('c-1', NewEntryCategory.background), {
      'Nata a Drustea.',
    });
    expect(entries.state.unseen, isEmpty);
  });

  testWidgets('an entry arriving with a new character becomes unseen', (
    tester,
  ) async {
    await pumpListener(tester, character: characterWith(['Nata a Drustea.']));

    characterStates.add(
      characterWith(['Nata a Drustea.', 'Ha salvato Bosa.'], xp: 10),
    );
    await tester.pump();
    await tester.pump();

    expect(entries.state.unseen, {
      NewEntryCategory.background: {'Ha salvato Bosa.'},
    });
  });

  testWidgets('a character update that appends a background entry marks it '
      'and lights the Profile (D-09)', (tester) async {
    const birth = 'Nata a Drustea.';
    const deed = 'Ha salvato Bosa.';
    const addition = "L'oste racconta ancora del suo coraggio.";
    await pumpListener(tester, character: characterWith([birth, deed]));

    characterStates.add(characterWith([birth, deed, addition]));
    await tester.pump();
    await tester.pump();

    expect(entries.state.unseen, {
      NewEntryCategory.background: {addition},
    });
    expect(entries.state.hasUnseenIn(NewEntryCategory.profile), isTrue);
    expect(store.seenOf('c-1', NewEntryCategory.background), {birth, deed});
  });
}
