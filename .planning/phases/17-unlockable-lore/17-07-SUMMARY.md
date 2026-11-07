---
phase: 17-unlockable-lore
plan: 07
subsystem: library
tags: [library, lore-card, data-page, new-marks, tdd]
requires:
  - phase: 17-06
    provides: "LibraryLoadData(book:, lore:, newLoreIds:), LibraryBookArt.newMarkInk/bookmarkUrl, Library BlocListener"
  - phase: 17-05
    provides: "LibraryBook enum (title, types), InMemoryLibraryBookmarksStore"
  - phase: 17-01
    provides: "LoreType.label, loreJson fixture"
provides:
  - "LoreCard(lore:, isNew:, newMarkInk:) with the «Nuovo» ribbon (newMarkLabel, newMarkKey); null-safe name/description"
  - "LibraryDataPage(book:, lore:, newLoreIds:, onBack:) StatelessWidget: hidden empty sections, emptyBookLine/emptyBookKey, sectionKeyOf(type) = ValueKey<LoreType>(type)"
  - "Library passes book, lore and newLoreIds to the page"
affects: [17-10]
tech-stack:
  added: []
  patterns: ["sections computed in build from every state; Dropdown keyed by LoreType so open state follows its section"]
key-files:
  created:
    - test/screens/mainScreen/tabs/library/components/lore_card_test.dart
  modified:
    - lib/screens/mainScreen/tabs/library/components/lore_card.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart
    - lib/screens/mainScreen/tabs/library/library.dart
    - test/screens/mainScreen/tabs/library/library_data_page_test.dart
    - test/screens/mainScreen/tabs/library/library_test.dart
key-decisions:
  - "The «Nuovo» ribbon is a Container with BoxDecoration(color: newMarkInk) (a DecoratedBox in the tree) carrying «Nuovo» in parchment bodyMedium, at the end of the name row"
  - "LibraryDataPage is stateless; the old types/title/bookmarkImagePath parameters are gone, derived from LibraryBook"
requirements-completed: []
duration: 6min
completed: 2026-11-07
---

# Phase 17 Plan 07: Library data page redraw Summary

The Library page shows only the sections with unlocked entries, the single line «Le pagine di questo libro sono ancora bianche.» for an empty book, a «Nuovo» ribbon in the book's ink on new entries, and sections keyed by `LoreType` recomputed from every state (D-05, D-06, D-07).

## Performance

- Duration: ~6 min (12:22–12:28 UTC), 2 tasks, 6 files (1 created, 5 modified)

## Accomplishments

- `LoreCard` gains `isNew` (default `false`), `newMarkInk` (default `KlimmeckGuideTheme.royalCrimson`), `static const String newMarkLabel = 'Nuovo'`, `static const Key newMarkKey = ValueKey('loreCard.newMark')`; the name line is a `Row(Expanded(AutoSizeText(lore.name ?? '')), if (isNew) _newMark())`; `lore.description ?? ''`.
- `LibraryDataPage` is a `StatelessWidget` `({key, required book, required lore, required newLoreIds, required onBack})`; `static const String emptyBookLine`, `static const Key emptyBookKey = ValueKey('library.emptyBook')`, `static Key sectionKeyOf(LoreType type) => ValueKey<LoreType>(type)`; sections = `book.types` with at least one entry, in book order; title `book.title`, back bookmark `CachedSvg(url: book.bookmarkUrl)`; `_LoreList(lores, newLoreIds, newMarkInk)` builds `LoreCard(isNew: newLoreIds.contains(id), newMarkInk: book.newMarkInk)`.
- `Library` builds `LibraryDataPage(book: state.book, lore: state.lore, newLoreIds: state.newLoreIds, onBack: goToInitial)`.

## Task Commits

1. Task 1 RED `873a103` test(library): expect the new bookmark on lore cards; GREEN `83667cf` feat(library): mark new lore cards with a bookmark
2. Task 2 RED `69c9c66` test(library): expect hidden sections, the empty line and new marks; GREEN `524428d` feat(library): hide empty sections and mark new pages

## RED failures observed

- Task 1: compile failure — `No named parameter with the name 'isNew'`, `Member not found: 'newMarkKey'`.
- Task 2: `library_data_page_test.dart` compile failure (`No named parameter with the name 'book'`, `Member not found: 'emptyBookKey'` / `'emptyBookLine'`); the compiler crash also failed the loading of `library_cubit_test.dart` (collateral: that file alone was green, 17/17); `library_test.dart` «a live arrival appears in the open book marked «Nuovo» (D-05, D-07)» failed on the missing mark (the page did not yet render `newLoreIds`).

## Tests

- `lore_card_test.dart` 4/4; `test/screens/mainScreen/tabs/library` +34 green; `test/screens/mainScreen/tabs/library test/screens/auth test/screens/mainScreen/main_screen_test.dart test/repository/storage` +272 green.
- Analyzer: `50 issues found.` (0 error, 0 warning).

## Files formatted

- `lore_card.dart` (format-dirty at baseline: the reflow of untouched lines — `CachedSvg` row, bronze rule border — accepted), `library_data_page.dart`, `library.dart`, the three test files; each by name.

## Deviations from Plan

1. **[Rule 1 - Bug] Ribbon uses `decoration: BoxDecoration(color: …)` instead of `color:`** — `Container(color:)` builds a `ColoredBox`, so the planned «DecoratedBox/Container has that colour» assertion would need a different widget; the decoration form keeps a `DecoratedBox` the test reads. Same look. Commit `83667cf`.
2. **[Rule 3 - Blocking] Unused import removed from `library.dart`** — `library_book_art.dart` was only used for `state.book.bookmarkUrl`, now read by the page; leaving it would break the analyzer gate. Commit `524428d`.
3. **library_test seeds the baseline under `'c-1'`** — the plan says «character id of the fixture», but the harness builds `LibraryCubit(characterId: 'c-1')`; the store key must match the cubit's id.
4. `pumpDataPage` gained an optional `VoidCallback? onBack` (needed by the two back-bookmark tests); the page no longer takes a widget key from the helper (stateless page, same-tree re-pumps are the point of the D-05 tests).

None of the shared Phase 16 result files (D-18) were touched. `dropdown.dart` and `book_type.dart` untouched.

## Known Stubs

None. The ribbon look is to be reviewed on device in 17-10.

## Threat Flags

None (T-17-19 / T-17-20 mitigated by the Task 2 / Task 1 tests).

## Self-Check: PASSED

- Files exist: lore_card_test.dart, library_data_page.dart, lore_card.dart, library.dart
- Commits 873a103, 83667cf, 69c9c66, 524428d in `git log`
