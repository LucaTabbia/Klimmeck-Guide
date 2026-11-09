---
phase: 17-unlockable-lore
plan: 05
subsystem: library
tags: [library, bookmarks, shared_preferences, enum, tdd]
requires:
  - phase: 17-01
    provides: "LoreType.label / isBestiary"
provides:
  - "LibraryBook enum (four books, types, title, storageKey, holds)"
  - "LibraryBookmarksStore + SharedPreferencesLibraryBookmarksStore (per-character per-book baseline)"
  - "FakeSharedPreferencesAsync getStringList/setStringList; InMemoryLibraryBookmarksStore"
affects: [17-06, 17-07]
tech-stack:
  added: []
  patterns: ["store with injected SharedPreferencesAsync Function(), lazily created (same as notification_preferences_store)"]
key-files:
  created:
    - lib/models/enums/library_book.dart
    - lib/repository/storage/library_bookmarks_store.dart
    - test/models/enums/library_book_test.dart
    - test/repository/storage/library_bookmarks_store_test.dart
    - test/helpers/fakes/in_memory_library_bookmarks_store.dart
  modified:
    - test/helpers/fakes/fake_shared_preferences_async.dart
key-decisions:
  - "Baseline key klimmeck.library.<characterId>.<storageKey>, sorted string list, outside klimmeck.session (D-07, D-12)"
  - "readSeen: null = never opened, empty set = opened empty; platform failures propagate to the caller (cubit decides, plan 06)"
requirements-completed: []
duration: 6min
completed: 2026-11-07
---

# Phase 17 Plan 05: LibraryBook enum and per-character bookmarks store Summary

**`LibraryBook` enum mirroring today's shelf plus a `SharedPreferencesAsync` baseline store of seen lore ids per character and per book, with string-list fake and in-memory store for plans 06–07.**

## Performance
- Duration: ~6 min; tasks 2; files 6 (5 created, 1 modified)

## Accomplishments
- `enum LibraryBook { bestiary, places, religions, knowledge }` in `lib/models/enums/library_book.dart` (Flutter-free): `final String title`, `final String storageKey`, `final List<LoreType> types`, `bool holds(LoreType? type)`.
- `abstract interface class LibraryBookmarksStore { Future<Set<String>?> readSeen(String characterId, LibraryBook book); Future<void> writeSeen(String characterId, LibraryBook book, Set<String> loreIds); }` and `SharedPreferencesLibraryBookmarksStore({SharedPreferencesAsync Function()? preferences})` with `static const keyPrefix = 'klimmeck.library'`, `static String keyFor(characterId, book)`; read returns `Set.unmodifiable`, write stores `loreIds.toList()..sort()`.
- `FakeSharedPreferencesAsync.getStringList/setStringList` (same `readFailures`/`writeFailures` queues; stores a copy).
- `InMemoryLibraryBookmarksStore` (`seen`, `writtenKeys`, `readFailure`, `writeFailure`, `readGate`, `static keyOf(characterId, book)` = `'<characterId>.<storageKey>'`, `seenOf(characterId, book)`).

## Task Commits
1. Task 1 RED `84ffb85` test(models): expect the four library books; GREEN `12ef910` feat(models): describe the four library books
2. Task 2 RED `9bd3a4b` test(repository): expect the per-character library bookmarks; GREEN `4368bba` feat(repository): keep the library bookmarks per character on device

## RED failures observed
- Task 1: compile failure, `package:klimmeck_guide/models/enums/library_book.dart` missing (`+0 -1: Some tests failed`).
- Task 2: compile failure, `Error when reading 'lib/repository/storage/library_bookmarks_store.dart'`, `SharedPreferencesLibraryBookmarksStore isn't a type`.
- No case green at first run.

## Gates
- `flutter test test/models/enums/library_book_test.dart` +5; `flutter test test/repository/storage test/models/enums` +67 All tests passed.
- `flutter analyze`: 0 error / 0 warning, last line `50 issues found.` (baseline unchanged).
- `dart format` run one by one on the six touched files; only `library_bookmarks_store_test.dart` reflowed (my own new file).

## Deviations from Plan
- Added one extra test «builds without a registered platform plugin» in `library_bookmarks_store_test.dart` (mirrors the notification store test; untitled by decision, D-07 count still 9 ≥ 8). The failure test covers read and write in one case as the behavior specified.
- Otherwise none - plan executed exactly as written.

## Known Stubs
None. No lib file outside the two new ones changed; the cubit/shell wiring is plan 06.

## Self-Check: PASSED
- All five created files exist; commits 84ffb85, 12ef910, 9bd3a4b, 4368bba in `git log`.
