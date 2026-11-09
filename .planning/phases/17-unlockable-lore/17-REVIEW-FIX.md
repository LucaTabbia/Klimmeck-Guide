---
phase: 17-unlockable-lore
fixed: 2026-11-07T12:52:02Z
source: 17-REVIEW.md
review_path: .planning/phases/17-unlockable-lore/17-REVIEW.md
rulings_path: .planning/phases/17-unlockable-lore/17-REVIEW-RULINGS.md
iteration: 1
fix_scope: all
findings_total: 6
findings_in_scope: 6
fixed_count: 5
skipped_count: 0
not_needed_count: 1
deferred_count: 0
status: all_fixed
---

# Phase 17: Code Review Fix Report

**Fixed at:** 2026-11-07T12:52:02Z
**Source review:** `.planning/phases/17-unlockable-lore/17-REVIEW.md`
**Rulings:** `.planning/phases/17-unlockable-lore/17-REVIEW-RULINGS.md`
**Iteration:** 1
**Branch:** `feat/17-unlockable-lore` (no push). Start `9f77a0a`, final code HEAD `d30ba40`.

**Summary:**
- Findings in the review: 6 (0 critical, 2 warning, 4 info)
- Fixed: 5 (WR-01, WR-02, IN-01, IN-03, IN-04)
- Not needed: 1 (IN-02), recorded with the orchestrator's reason, no code change
- Skipped: 0. Deferred: 0.

WR-01, WR-02 and IN-01 went Red → Green (`test(...)` then `fix(...)`). IN-03 and IN-04 are structural refactors with no behaviour change, covered by the existing tests. Commits use plain `git` with explicit paths, carry no trailers and rewrite no history.

These decisions still hold:
- Rule 2: the live refreshes stay silent. `refreshCities` never emits `MainScreenLoading` outside `loadData()`. The Library refresh path never emits `LibraryLoading` nor `LibraryError`.
- The backend stays the source of truth (D-01, D-05, D-11). `unlockedLore` ids are used only to detect a change and to compute the «Nuovo» marks.
- No GraphQL document changed, and the registry stays at 45. No new dependency, Cloudinary asset id or environment variable.
- The only new copy is the error line the rulings approved.

## Final gate

| Check | Result |
|-------|--------|
| `flutter analyze` (repo-wide) | **50 issues found, all info, 0 errors / 0 warnings**: unchanged baseline |
| `flutter test` (full suite, foreground) | **`01:16 +3420: All tests passed!`** |
| `dart format` on every touched file | each file formatted on its own by name, 0 reflow of untouched members |
| Trailers on `9f77a0a..HEAD` (`co-authored-by` / `generated with` / `claude-session`) | 0 |
| `git status --short` | empty before the report commit |

## Per-finding table

| ID | Severity | Outcome | Commits | Tests added / changed |
|----|----------|---------|---------|-----------------------|
| WR-01 | Warning | fixed | `b9a28c7` → `285af2c` | `main_screen_cubit_test.dart`: «overlapping refreshes read once more after the first and never emit out of order (D-11)», «a refresh requested during the cold start runs once the cities are loaded (D-11)», «a refresh requested before a failed cold start never runs (D-11)» |
| WR-02 | Warning | fixed | `ec026bc` → `6af9684` | new `library_error_page_test.dart` «shows the faded-pages line and goes back to the shelves from the bookmark (D-06)»; `library_test.dart` «a failed opening shows the faded-pages line and goes back to the shelves (D-06)»; `library_cubit_test.dart` «a failed opening remembers the book that failed (D-06)» |
| IN-01 | Info | fixed | `953359e` → `9964450` | `library_cubit_test.dart` «a set change during the opening fetch is applied once the book is shown (D-05)» |
| IN-02 | Info | not_needed | — | Orchestrator ruling: the two baseline writes are dispatched in call order through the same `SharedPreferencesAsync` channel. The only effect of a reorder would be one cosmetic extra «Nuovo» at the next opening (D-07). |
| IN-03 | Info | fixed (refactor) | — → `a1269df` | `quest_enemy_test.dart`: the equivalence test of the wrapper is removed. Its selection test (highest xp, null xp counts as 0, first wins ties) is moved to `strongestEntryOf`, so the null-xp rule keeps its coverage. |
| IN-04 | Info | fixed (refactor) | — → `d30ba40` | none: `main_screen_test.dart` and `test/screens/mainScreen/tabs/library` stay green |

## Details

### WR-01: `MainScreenCubit.refreshCities` single-flight with one trailing re-run

`refreshCities()` now uses the same discipline as `LibraryCubit.syncUnlockedLore`.
- It uses `_isRefreshing` / `_hasPendingRefresh` and a private `_runRefreshLoop()` with a `do { … } while (_hasPendingRefresh && state is MainScreenLoadData)` loop around `_readCities()`.
- A call made while a read is in flight, or while `loadData()` is in `MainScreenLoading`, only marks the refresh pending.
- `loadData()` runs the loop after a successful `MainScreenLoadData` emit. It clears the pending flag on `MainScreenError`, so nothing runs after a failed cold start.
- `_readCities()` keeps every D-11 rule: the old list is kept on failure, and a new state is emitted only when the list differs (`listEquals`).
- `main_screen.dart` was not changed for this finding.

RED: the overlap case failed with `getCities` called twice before the first answer (expected 1), and the cold-start case failed with one call (expected 2). The «failed cold start» case was green at its first run, because the old code also dropped that refresh. It pins the new «never after `MainScreenError`» branch. In the GREEN commit, the overlap test also drains the event queue (`pumpEventQueue()`) before it reads the collected states, because broadcast deliveries are asynchronous. The test was re-run against the old cubit and still failed for the same reason.

### WR-02: in-world page for a failed opening

- `LibraryError(book, errorMessage)` now carries the `LibraryBook` that failed, and the props are updated. `errorMessage` is kept for the logs only and is never rendered.
- The parchment frame of `LibraryDataPage` (padding, container, scroll, title, bottom-right bookmark `GestureDetector`) is extracted into `statesPages/library_book_frame.dart` (`LibraryBookFrame({book, onBack, child})`). Both pages use it.
- `LibraryDataPage` keeps its public API (`book`, `lore`, `newLoreIds`, `onBack`, `emptyBookLine`, `emptyBookKey`, `sectionKeyOf`), and all its tests stay green.
- `LibraryErrorPage({required book, required onBack})` shows `errorLine` = «Le pagine di questo libro sono sbiadite. Riprova più tardi.» with `errorKey = ValueKey('library.error')`. It has no AppBar, no button and no spinner.
- `library.dart` passes `state.book` and `goToInitial()`.

RED by compilation: the new constructor parameters, the constants and `LibraryError.book` did not exist yet.

### IN-01: an unlock during the opening fetch is applied

- While `state is LibraryLoading` (or while a refresh is running), `syncUnlockedLore()` sets `_hasPendingRefresh` instead of returning.
- A successful `openBook` (same generation, after its `LibraryLoadData` emit and its baseline write) runs the extracted `_runRefreshLoop()` if a refresh is pending and none is running.
- A failed or superseded `openBook` clears nothing. The flag is reset at the start of each loop iteration.

RED: `getAllLores` was called once (expected 2).

### IN-03: `strongestEnemyOf` removed

The wrapper is removed from `lib/models/quest/quest_enemy.dart`. `grep -rn strongestEnemyOf lib test` prints nothing, and `test/models/quest` is green (161 tests).

### IN-04: shared extraction of the unlocked ids

`List<String>? unlockedLoreOf(CharacterState state)` lives in `character_state.dart`, the part of `character_cubit.dart`, so it adds no new import. It returns `status?.unlockedLore ?? const []` for `CharacterLoaded` and `null` otherwise. `MainScreen._hasUnlockedLoreChanged` and the Library tab use it, and the private `_unlockedLoreOf` of `library.dart` is gone.

The check is not unified further, for this reason. The Map listener compares two consecutive character states in `listenWhen`. The Library cubit compares against its own last seen set, because it must record the first set and ignore changes while no book is open. Those are two different shapes on purpose, and only the extraction was duplicated.

## Notes for the device UAT

- **Library, failed opening (WR-02):** if `lores` fails when a book is tapped (offline, 5xx), the book's parchment now opens with its title and the line «Le pagine di questo libro sono sbiadite. Riprova più tardi.». Tapping the bookmark in the bottom-right corner returns to the shelves. The crossed debug box and the raw error never appear.
- **Library, unlock while a book is opening (IN-01):** an unlock that arrives while the book is still loading now appears in the open page right after it is shown, marked «Nuovo», with no second spinner.
- **Map, live refresh (WR-01):** an unlock that arrives during the cold start of the main screen now refreshes the cities once they are loaded, so the city opens its lore without a restart. Several unlocks in a row end on the latest city list, and a stale answer can no longer show a known city as unknown again. All of this stays silent, with no loading.
- IN-03 and IN-04 change nothing visible.

---

_Fixed: 2026-11-07T12:52:02Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
