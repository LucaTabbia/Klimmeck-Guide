---
phase: 17-unlockable-lore
plan: 06
subsystem: library
tags: [library, cubit, live-refresh, bookmarks, bloc_listener, tdd]
requires:
  - phase: 17-05
    provides: "LibraryBook enum, LibraryBookmarksStore, InMemoryLibraryBookmarksStore"
  - phase: 17-01
    provides: "CharacterStatus.unlockedLore, LoreType.label, loreJson fixture"
provides:
  - "LibraryCubit(graphQl, bookmarks:, characterId:) with openBook / syncUnlockedLore / goToInitial"
  - "LibraryLoadData(book:, lore:, newLoreIds:)"
  - "LibraryBookArt extension (coverUrl, bookmarkUrl, newMarkInk)"
  - "Library forwards CharacterStatus.unlockedLore through BlocListener<CharacterCubit>, seeded at mount"
  - "AuthenticatedShell.libraryBookmarksStore, created once in main.dart"
affects: [17-07, 17-10]
tech-stack:
  added: []
  patterns: ["generation counter drops stale completions; single-flight refresh with one trailing re-run; BlocListener forwarding instead of cubit-to-cubit subscription"]
key-files:
  created:
    - lib/screens/mainScreen/tabs/library/components/library_book_art.dart
    - test/screens/mainScreen/tabs/library/cubit/library_cubit_test.dart
    - test/screens/mainScreen/tabs/library/library_test.dart
  modified:
    - lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart
    - lib/screens/mainScreen/tabs/library/cubit/library_state.dart
    - lib/screens/mainScreen/tabs/library/library.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_initial_page.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart
    - lib/screens/auth/authenticated_shell.dart
    - lib/main.dart
    - test/screens/auth/authenticated_shell_test.dart
key-decisions:
  - "D-07 revised applied: baseline written after every successful load (opening and live refresh); marks computed against the session reference (baseline read at opening, or the first shown set when none); no write at close"
  - "Baseline read/write failures are caught in the cubit (debugPrint): an unreadable baseline marks nothing, a failed write still shows the book"
  - "The live refresh never emits LibraryLoading/LibraryError; a failed refresh keeps the page and the next set change retries"
requirements-completed: []
duration: 12min
completed: 2026-11-07
---

# Phase 17 Plan 06: Library live refresh and «Nuovo» marks Summary

**`LibraryCubit` opens one book at a time, refetches it silently (single-flight, one trailing re-run, stale completions dropped by a generation counter) when the set of `unlockedLore` ids changes, and computes the «Nuovo» marks against a per-character device baseline; `Library` forwards the ids through a `BlocListener<CharacterCubit>`.**

## Performance
- Duration: ~12 min; tasks 2; files 11 (3 created, 8 modified)

## Accomplishments
- `LibraryCubit(KlimmeckGraphQl graphQl, {required LibraryBookmarksStore bookmarks, required String characterId})`:
  - `Future<void> openBook(LibraryBook book)` — emits `LibraryLoading` (explicit tap), then `LibraryLoadData` with only that book's lore (`book.holds(lore.type)`), or `LibraryError` on a failed read; reads the baseline, `_reference = baseline ?? shown`, writes the baseline after the emit.
  - `Future<void> syncUnlockedLore(List<String> ids)` — set comparison (`setEquals`), first set only recorded, nothing without an open book; single-flight with `_hasPendingRefresh` trailing loop; refresh path emits only `LibraryLoadData`.
  - `void goToInitial()` — bumps `_generation`, emits `LibraryInitial`.
  - `loadLoreData` removed (no other caller).
- `LibraryLoadData({required LibraryBook book, required List<Lore> lore, required Set<String> newLoreIds})`, props `[book, lore, newLoreIds]`.
- `extension LibraryBookArt on LibraryBook` (`coverUrl`, `bookmarkUrl`, `newMarkInk`: royalCrimson/healGreen/darkBronze/mysticBlue).
- `LibraryInitialPage({super.key, required ValueChanged<LibraryBook> onOpen})`, two shelves built from `LibraryBook` (same layout and order).
- `Library`: no more widget-state fields; `initState` → `goToInitial()` then `syncUnlockedLore(current ids)` when `CharacterLoaded`; `BlocListener<CharacterCubit, CharacterState>` (listenWhen `CharacterLoaded`) → `syncUnlockedLore`; `LibraryLoading` renders `SizedBox.shrink()` (no `Placeholder`).
- Shell: `required this.libraryBookmarksStore` after `notificationPreferencesStore`; `main.dart` creates `SharedPreferencesLibraryBookmarksStore()` once beside the notification store.

## Task Commits
1. Task 1 RED `5493690` test(library): expect the silent refresh and the new marks — compile failure (`openBook`, `syncUnlockedLore`, named ctor params, `LibraryLoadData(book:…)` undefined).
2. Task 1 GREEN `5675f41` feat(library): refresh open books silently and mark new pages — 16 cubit tests + shell/main-screen suites green (213).
3. Task 2 RED `1f65cdb` test(library): expect the library to follow the unlocked lore — 4 of 5 red: «forwards…» and «a live refresh…» (Bosa not shown), «an unlock right after mounting…» (getAllLores called 1, expected 2), «opening a book never shows a debug placeholder» (Placeholder found). Green at first run: «a status change with the same unlocked set refetches nothing (D-05)» — with no listener nothing refetched either; it pins the non-regression once the listener exists.
4. Task 2 GREEN `de21c5a` feat(library): follow the unlocked lore of the character.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `LibraryDataPage` cached its per-type lists in `initState`**
- **Found during:** Task 2 GREEN
- **Issue:** after the listener was wired, the cubit emitted the refreshed `LibraryLoadData` but the data page (same widget position) kept the lists built in `initState`, so «Bosa» never appeared (D-05 requires the page to recompute).
- **Fix:** replaced the `late _loreLists` + `initState` with `_loreOfType(LoreType)` computed in `build` (minimal; signature unchanged; plan 17-07 redraws the page anyway).
- **Files modified:** `lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart` (outside `files_modified`)
- **Commit:** `de21c5a`

**2. [Boy Scout] `LibraryInitialPage` shelves** built by a private `_shelf(List<LibraryBook>)` instead of four hand-written `BookType`s (same layout, order and output).

### Acceptance discrepancy (noted, not fixed)
- Task 2: `grep -c "D-05)" library_test.dart` = 3, plan asks ≥ 4. The plan's own exact titles give 3 (`(D-05, D-12)` matches `D-12)`, not `D-05)`); titles kept as prescribed.

## Verification
- `flutter test test/screens/mainScreen/tabs/library test/screens/auth test/screens/mainScreen/main_screen_test.dart test/repository/storage` → +261, all passed.
- `flutter analyze` → `50 issues found` (all info), 0 error, 0 warning.
- `dart format` per touched file: all lib files already clean after edits (0 changed), the two new tests and `library.dart`/`library_data_page.dart` reflowed only edited lines.
- Acceptance greps Task 1: `openBook` 1, `syncUnlockedLore` 1, `setEquals` 1, `LibraryLoading()` 1, `loadLoreData` 0, `.stream.listen` 0, `final Set<String> newLoreIds` 1, `extension LibraryBookArt` 1, shell `libraryBookmarksStore` 3, main `SharedPreferencesLibraryBookmarksStore()` 1; cubit test `D-07)` 7, `D-19)` 3, `D-05)` 6. Task 2: `BlocListener<CharacterCubit, CharacterState>` 1, `syncUnlockedLore` 2, `Placeholder()` 0, `seedSvgCache` 1.

## Deferred Issues
- `LibraryErrorPage` still renders a debug `Placeholder()` (out of this plan's scope; only reached after an explicit tap fails).

## Known Stubs
- `LibraryBookArt.newMarkInk` and `LibraryLoadData.newLoreIds` are not rendered yet: plan 17-07 draws the «Nuovo» bookmark.

## Threat Flags
None beyond the plan's register (T-17-15..18 mitigated by the tests named in the plan).

## Self-Check: PASSED
