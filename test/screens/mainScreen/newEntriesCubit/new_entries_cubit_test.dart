import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';

import '../../../helpers/fakes/in_memory_new_entries_store.dart';

const String _characterId = 'c-1';
const NewEntryCategory spells = NewEntryCategory.spells;
const NewEntryCategory items = NewEntryCategory.items;
const NewEntryCategory background = NewEntryCategory.background;

void main() {
  late InMemoryNewEntriesStore store;
  late NewEntriesCubit cubit;

  void seedSeen(NewEntryCategory category, Set<String> ids) =>
      store.seen[InMemoryNewEntriesStore.keyOf(_characterId, category)] = ids;

  Set<String>? seenOf(NewEntryCategory category) =>
      store.seenOf(_characterId, category);

  setUp(() {
    store = InMemoryNewEntriesStore();
    cubit = NewEntriesCubit(store: store, characterId: _characterId);
  });

  tearDown(() => cubit.close());

  test('what the character owns at the first launch is not new', () async {
    await cubit.sync({
      spells: {'fireball'},
      items: {'potion'},
    });

    expect(cubit.state.unseen, isEmpty);
    expect(seenOf(spells), {'fireball'});
    expect(seenOf(items), {'potion'});
  });

  test('an entry never seen is unseen until its page is visited', () async {
    seedSeen(spells, {'fireball'});

    await cubit.sync({
      spells: {'fireball', 'frost'},
    });

    expect(cubit.state.unseen, {
      spells: {'frost'},
    });
    expect(cubit.state.hasUnseenIn(NewEntryCategory.journal), isTrue);
    expect(cubit.state.hasUnseenIn(NewEntryCategory.profile), isFalse);
    expect(cubit.state.highlightedOf(spells), isEmpty);
  });

  test('a visit highlights the unseen entries and marks them seen', () async {
    seedSeen(spells, {'fireball'});
    await cubit.sync({
      spells: {'fireball', 'frost'},
    });

    await cubit.visit(NewEntryCategory.journal);

    expect(cubit.state.unseen, isEmpty);
    expect(cubit.state.highlightedOf(spells), {'frost'});
    expect(seenOf(spells), {'fireball', 'frost'});
  });

  test('the next visit drops the highlights of the previous one', () async {
    seedSeen(spells, {'fireball'});
    await cubit.sync({
      spells: {'fireball', 'frost'},
    });
    await cubit.visit(NewEntryCategory.journal);

    await cubit.visit(NewEntryCategory.journal);

    expect(cubit.state.highlightedOf(spells), isEmpty);
  });

  test('a visit touches only the categories of its page', () async {
    seedSeen(spells, const {});
    seedSeen(background, const {});
    await cubit.sync({
      spells: {'frost'},
      background: {'Ha salvato Bosa.'},
    });

    await cubit.visit(NewEntryCategory.profile);

    expect(cubit.state.unseen, {
      spells: {'frost'},
    });
    expect(cubit.state.highlightedOf(background), {'Ha salvato Bosa.'});
  });

  group('an entry appended to a background already seen (Phase 24)', () {
    const birth = 'Nata a Drustea.';
    const addition = 'Ha salvato Bosa dai predoni.';

    Future<void> appendAddition() async {
      seedSeen(background, {birth});
      await cubit.sync({
        background: {birth, addition},
      });
    }

    test('is unseen, and Profile reports a novelty (D-09)', () async {
      await appendAddition();

      expect(cubit.state.unseen, {
        background: {addition},
      });
      expect(cubit.state.hasUnseenIn(NewEntryCategory.profile), isTrue);
      expect(cubit.state.hasUnseenIn(NewEntryCategory.journal), isFalse);
    });

    test('is highlighted and remembered at the Profile visit (D-09)', () async {
      await appendAddition();

      await cubit.visit(NewEntryCategory.profile);

      expect(cubit.state.highlightedOf(background), {addition});
      expect(cubit.state.hasUnseenIn(NewEntryCategory.profile), isFalse);
      expect(seenOf(background), {birth, addition});
    });

    test('loses its highlight at the second Profile visit (D-09)', () async {
      await appendAddition();
      await cubit.visit(NewEntryCategory.profile);

      await cubit.visit(NewEntryCategory.profile);

      expect(cubit.state.highlightedOf(background), isEmpty);
      expect(seenOf(background), {birth, addition});
    });
  });

  test('an arrival during a visit waits for the next visit', () async {
    seedSeen(items, {'potion'});
    await cubit.sync({
      items: {'potion'},
    });
    await cubit.visit(NewEntryCategory.journal);

    await cubit.sync({
      items: {'potion', 'herb'},
    });

    expect(cubit.state.highlightedOf(items), isEmpty);
    expect(cubit.state.unseen, {
      items: {'herb'},
    });
  });

  test('an entry lost and found again is new again', () async {
    seedSeen(items, {'potion', 'herb'});

    await cubit.sync({
      items: {'potion'},
    });
    expect(seenOf(items), {'potion'});

    await cubit.sync({
      items: {'potion', 'herb'},
    });
    expect(cubit.state.unseen, {
      items: {'herb'},
    });
  });

  test('an unreadable store marks nothing', () async {
    store.readFailure = Exception('storage');

    await cubit.sync({
      spells: {'frost'},
    });

    expect(cubit.state.unseen, isEmpty);
  });

  test('a failed write keeps the visit seen for the session', () async {
    seedSeen(spells, const {});
    await cubit.sync({
      spells: {'frost'},
    });
    store.writeFailure = Exception('storage');

    await cubit.visit(NewEntryCategory.journal);
    await cubit.sync({
      spells: {'frost'},
    });

    expect(cubit.state.unseen, isEmpty);
    expect(cubit.state.highlightedOf(spells), {'frost'});
  });
}
