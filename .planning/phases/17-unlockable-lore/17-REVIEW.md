---
phase: 17-unlockable-lore
reviewed: 2026-11-07T12:45:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/fragments/quest_fragment.dart
  - lib/graphql/fragments/quest_result_fragment.dart
  - lib/main.dart
  - lib/models/character/character_status.dart
  - lib/models/enums/library_book.dart
  - lib/models/enums/lore_type.dart
  - lib/models/lore.dart
  - lib/models/quest/quest_enemy.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/models/quest_result/quest_result.dart
  - lib/repository/storage/library_bookmarks_store.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/cubit/main_screen_cubit.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/library/components/library_book_art.dart
  - lib/screens/mainScreen/tabs/library/components/lore_card.dart
  - lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart
  - lib/screens/mainScreen/tabs/library/cubit/library_state.dart
  - lib/screens/mainScreen/tabs/library/library.dart
  - lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart
  - lib/screens/mainScreen/tabs/library/statesPages/library_initial_page.dart
  - lib/screens/mainScreen/tabs/map/components/unknown_city_modal.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/shared/components/enemy_portrait.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - lib/shared/components/popup/quest_result_sheet.dart
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-11-07
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

The plans 17-01..17-08 hold up well against the brief. Verified clean:

- Parsing: `unlockedLore` is non-list tolerant, drops non-strings, is unmodifiable, and is carried by `copyWith`, `props` and `toJson`. `QuestEnemy.known` is strict on the board and lenient on results, and `toJson` writes it. `QuestResult.loreUnlocked` is lenient entry by entry. `Lore.fromJson` tolerates an unknown or missing `type` and round-trips the wire name via `Enum.name`. No reader of the Italian label through `.name` is left in `lib/`.
- Contract: the fragments match REPO-RULES, and no other `lib/graphql` file changed. The `known` data comes from the BE as received, with no inference from `outcome`.
- Library cubit: the generation counter, single-flight with one trailing re-run, and sets (not lengths) are all in place. The live refresh never emits loading or error. The baseline is written after every successful load and not at close. Store failures are swallowed. The listener lives in the widget, not in a cubit. `ValueKey(type)` is on every `Dropdown`, empty sections are hidden, and the empty-book line is present.
- Character id: `SessionHome` keys the shell on `character:<id>`, so `LibraryCubit` always gets the right id and a recreated character gets a fresh baseline.
- Portrait and sheets: the silhouette is a `ColorFiltered(srcIn, deepNight)` over the same picture, with the correct semantics labels. The portrait follows the strongest enemy's own `known`. Result lines follow the BE order after «Magia appresa», with the prefix chosen by `isBestiary`.
- Map: no `relatedLore!` is left in `lib/`, and an unknown city never calls `lore(id)`.
- Copy matches the fixed strings, and nothing logs a payload.

Two warnings (an out-of-order `refreshCities` and the debug `Placeholder` error page) and four info items follow.

Deferred, not findings: plans 17-09 and 17-10, and the strict board parsing of `known`. A BE without Phase 16 would drop every quest, which is the documented gate (Pitfall 9).

## Critical

None.

## Warning

### WR-01: `MainScreenCubit.refreshCities` has no single-flight or ordering guard

**File:** `lib/screens/mainScreen/cubit/main_screen_cubit.dart:29-40`
**Issue:** Every change of the `unlockedLore` set fires `refreshCities()` from the `BlocListener` in `main_screen.dart:126-130`, and nothing serialises the calls.

- Scenario 1: a result that unlocks two things produces two close `characterUpdated` events, so two `getCities()` calls run in parallel. If the older response (fewer known cities) lands after the newer one, `listEquals(current.cities, cities)` is false and the stale list overwrites the fresh one. The map then shows a city as unknown until the next unlock.
- Scenario 2: the user is still in the cold-start `loadData()`, so state is `MainScreenLoading`. The unlock event is dropped by `if (state is! MainScreenLoadData) return`. A `loadData` response that was served before the unlock then wins, and no later refresh corrects it.

`LibraryCubit.syncUnlockedLore` already solves the same problem with single-flight and one trailing re-run.

**Why it matters:** the D-11 revised promise («a city just learned gets its lore without a restart») silently fails in a plausible multi-event sequence. The backend is the truth, but the FE shows an older snapshot.

**Suggested fix:** apply the same pattern as the Library cubit. Keep `_isRefreshing` and `_hasPendingRefresh`, and loop `do { … } while (_hasPendingRefresh)`. In `loadData`, remember a pending refresh requested during `MainScreenLoading` and run it right after the `MainScreenLoadData` emit. RED test first, in `test/screens/mainScreen/cubit/main_screen_cubit_test.dart`: «two overlapping refreshes, the first answering last, end on the second list (D-11)» using two `Completer`s on `getCities`. A second case: «a refresh requested while loading re-runs after the load».

### WR-02: `LibraryErrorPage` is still a debug `Placeholder`, now reached by `openBook` failures, with no way back

**File:** `lib/screens/mainScreen/tabs/library/statesPages/library_error_page.dart:7` (reached from `library.dart:60`, emitted at `library_cubit.dart:42`)
**Issue:** `openBook` is the only path that emits `LibraryError`, and it runs on every book tap. A transient failure (offline, 5xx, or the BE `NOT_FOUND` filtering added in Phase 16) renders Flutter's crossed-box `Placeholder`. The page has no retry and no bookmark to return to the shelf. `LibraryError.errorMessage` (the raw `e.toString()`) is never shown, which is good, but it is also unused.

**Why it matters:** the user sees a debug artefact, and the only exit is leaving the tab and coming back (`initState` calls `goToInitial`). It is reachable from a normal user path, and Phase 17 adds a second reason for `lores` to fail.

**Suggested fix:** replace the `Placeholder` with a paper page in the style of the data page. It needs one short line and the bookmark tap that calls `goToInitial()`. The copy is not fixed in REPO-RULES, so ask the orchestrator for the string or reuse existing app copy. Drop the unused `errorMessage` payload, or keep it out of `toString()`. RED test first in `library_test.dart`: «a failing `getAllLores` shows a page that lets the user go back to the shelf».

## Info

### IN-01: An unlock that arrives while `openBook` is loading is lost for the page

**File:** `lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart:60-65`
**Issue:** `syncUnlockedLore` updates `_lastUnlocked` first and then returns because `state is! LibraryLoadData` (it is `LibraryLoading`). If the `lores` response was served just before the unlock, the page shows the older set. The next change in `unlockedLore` is compared against the already-updated `_lastUnlocked`, so nothing re-reads. The window is narrow (one request).
**Fix:** after the `LibraryLoadData` emit in `openBook`, compare the set fetched against `_lastUnlocked` (or store `_unlockedAtFetchStart` before the call). If they differ, run one silent `_refreshShownBook`. RED test: «unlock during the opening re-reads once (D-05)».

### IN-02: Baseline write in `openBook` can overwrite a newer live-refresh write

**File:** `lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart:55-56` and `:93-94`
**Issue:** `openBook` emits and then awaits `_writeBaseline(book, shown)`, while a silent refresh can emit and write its larger set in between. Writes are not ordered, so the older set can land last. At the next opening, entries that were already shown are marked «Nuovo» again.
**Fix:** serialise the writes (chain them on a `Future` field), or write only if `generation == _generation`, or skip the older write when a refresh has completed. Low severity, because the bookmark is cosmetic and self-heals at the next load.

### IN-03: `strongestEnemyOf` has no callers in `lib/`

**File:** `lib/models/quest/quest_enemy.dart:130-131`
**Issue:** after the refactor to `strongestEntryOf`, the wrapper is only a leftover. Both sheets and `QuestSheetDetails` call the entry variant (`grep -rn strongestEnemyOf lib` prints only the definition).
**Fix:** remove it (Boy Scout rule), after checking that no test depends on it. Move any such test to `strongestEntryOf(...)?.enemy`.

### IN-04: The «set of unlocked ids changed» comparison is written in two places with different shapes

**File:** `lib/screens/mainScreen/main_screen.dart:98-111` and `lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart:60-65` (with `library.dart:21-31`)
**Issue:**
- The Map compares `previous` against `current` state through `listenWhen`.
- The Library keeps `_lastUnlocked` inside the cubit and compares there.

The two can diverge. For example, the Map misses a change if a `CharacterLoading` state ever sits between two `CharacterLoaded` states. That does not happen today, since `loadCharacter` runs once per shell. The `status?.unlockedLore ?? const []` extraction is also duplicated in `library.dart` and `main_screen.dart`.
**Fix:** add a tiny helper (for example `Character.unlockedLoreSet`, or a function next to `CharacterStatus`) that returns the set, and use it in both places. Optional: make the Map follow the same «last seen set» approach as the Library.
