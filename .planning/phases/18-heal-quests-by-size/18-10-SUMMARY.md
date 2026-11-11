---
phase: 18-heal-quests-by-size
plan: 10
subsystem: quests
tags: [quests, board, no-effect, torn-sheet, scope-listener, tdd]
requires: ["18-04", "18-01"]
provides:
  - "Quest.noEffect (bool, default false): per-viewer flag read as json['noEffect'] == true, carried by toJson/copyWith/props (D-20)"
  - "QuestAvailability.noEffect (last enum value): returned instead of available when the flag is set; standingOf marks the sheet torn whenever quest.noEffect"
  - "const String questNoEffectLine = 'Il tempio non può fare nulla per te adesso' in quest_blocked_reason.dart, mapped from QuestAvailability.noEffect (reused by the refusal notice of 18-11)"
  - "questPaperAssetIds(QuestType.heal, isTorn: true) -> [questSheetTorn1, questSheetTorn2]; study keeps the announcement sheets"
  - "Board: TearablePaper(isEnabled: isIdle && !selected.noEffect)"
  - "QuestScopeListener: scope record gains currentLifePoints, maxLifePoints, injuries (names joined by ','), filled only when the character is in a city"
affects: [18-11, 18-12, 18-13]
tech-stack:
  added: []
  patterns: ["value-only record fields (List joined into a String) so a record scope compares by value"]
key-files:
  created: []
  modified:
    - lib/models/quest/quest.dart
    - lib/models/quest/quest_availability.dart
    - lib/models/quest/quest_blocked_reason.dart
    - lib/models/quest/quest_paper_asset.dart
    - lib/screens/mainScreen/tabs/board/board.dart
    - lib/screens/mainScreen/components/quest_scope_listener.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/models/quest/quest_test.dart
    - test/models/quest/quest_availability_test.dart
    - test/models/quest/quest_blocked_reason_test.dart
    - test/models/quest/quest_paper_asset_test.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
    - test/screens/mainScreen/components/quest_scope_listener_test.dart
    - test/screens/mainScreen/main_screen_test.dart
decisions:
  - "Planner's choice kept: the torn heal borrows questSheetTorn1/2 (no new asset id), so a heal held in the viewer's own lane (tornForOwner) is now drawn torn on the Board like every other accepted quest"
  - "Planner's choice kept: the open sheet line reuses the refusal copy (questNoEffectLine)"
  - "Planner's choice kept: a no-effect sheet ignores the drag entirely (isEnabled: false), not just a resisting tear"
  - "Planner's choice kept: the vitals reread only while the character is in a city; outside a city the vitals are null in the scope"
  - "A more specific block (tornForOwner, laneBusy, full, ...) keeps its reason; noEffect only replaces available; the sheet is torn in every case where the flag is set"
metrics:
  duration: "~30 min"
  completed: 2026-11-10
---

# Phase 18 Plan 10: Heal with no effect Summary

A quest flagged `noEffect` by the backend stays in its place on the Board, drawn as a torn sheet that cannot be dragged or accepted, says «Il tempio non può fare nulla per te adesso», and comes back whole when a silent reread (triggered by a change of HP, max HP or injuries in a city) clears the flag. The FE computes nothing: it reads the flag.

## Commits

| Task | Commit | Message |
| ---- | ------ | ------- |
| 1 RED | 9600714 | test(models): expect the no-effect flag and its torn standing |
| 1 GREEN | 9a7df1f | feat(models): read the no-effect flag and tear its sheet |
| 2 RED | 42fb4ed | test(quests): expect the inert no-effect sheet and the vitals reread |
| 2 GREEN | a55cdce | feat(quests): keep a no-effect sheet inert and reread on vitals |

## Names and signatures

- `lib/models/quest/quest.dart`: `const Quest({required id, required infos, required requirements, required registeredAdventurers, required prizes, this.noEffect = false})`; `final bool noEffect;`; fromJson `noEffect: json['noEffect'] == true`; toJson key `"noEffect"` (last); `copyWith({..., bool? noEffect})`; props end with `noEffect`.
- `lib/models/quest/quest_availability.dart`: `QuestAvailability.noEffect` (last value); `standingOf` isTorn = `tornForOwner || quest.noEffect || _isFullForViewer`; `_availabilityOf` ends with `return quest.noEffect ? QuestAvailability.noEffect : QuestAvailability.available;`. `needsTravelPreview` is false for a noEffect quest through `canAccept` (no change in board_policy.dart).
- `lib/models/quest/quest_blocked_reason.dart`: top-level `const String questNoEffectLine = 'Il tempio non può fare nulla per te adesso';` and `QuestAvailability.noEffect => questNoEffectLine`. No other exhaustive switch over `QuestAvailability` exists in `lib/` (grep: none outside quest_availability.dart / quest_blocked_reason.dart).
- `lib/models/quest/quest_paper_asset.dart`: `QuestType.heal` split from `study`; torn heal = `[questSheetTorn1, questSheetTorn2]`.
- `lib/screens/mainScreen/tabs/board/board.dart` `_tearableSheet`: `isEnabled: isIdle && !selected.noEffect`.
- `lib/screens/mainScreen/components/quest_scope_listener.dart`: `_QuestScope` gains `int? currentLifePoints, int? maxLifePoints, String? injuries`; `_scopeChanged` and `_scopeOf` are now instance methods (need `cities`); `final isInCity = currentCityOf(cities, status?.location) != null;`.
- Fixtures: `questJson(..., bool? noEffect)` / `buildQuest(..., bool? noEffect)` write `'noEffect'` at the top level only when not null; `characterWithLanesJson(..., int? currentLifePoints, int? maxLifePoints, List<String>? injuries)` write into `status` only when not null.
- Test helpers: board_test `_boardQuest(..., bool? noEffect)`, group `'heal with no effect (D-20)'` with `openInert` / `openSheet`; quest_scope_listener_test `_character(..., currentLifePoints, maxLifePoints, injuries)`, group `'vitals (D-20)'`.

## RED failures observed

- Task 1: compile failures `Member not found: 'noEffect'` (quest_availability_test, quest_blocked_reason_test), `The getter 'noEffect' isn't defined for the type 'Quest'` / `No named parameter with the name 'noEffect'` (quest_test); quest_paper_asset_test «a torn heal borrows the torn quest sheets, a whole one keeps the announcement (D-20)» failed on the expectation. board_policy_test showed a transient «The Dart compiler exited unexpectedly» in the same run (collateral of the parallel compile failures); rerun alone it was green.
- Task 2: 5 failures — the three vitals reread cases (life points, max life points, injuries), «its open sheet ignores the swipe and never calls accept (D-20)» (`isEnabled` was true) and «when the reread list clears the flag ... (D-20)» (its first assertion `isEnabled == false` before the reread).

Green at the first run of Task 2, with the reason:
- «a heal with no effect stays in its place, drawn torn (D-20)» and «its open sheet says why in the world (D-20)»: Task 1 already provides the torn standing and the reason line.
- «the same vitals in a new character do not reread (D-20)» and «outside a city a change of life points does not reread (D-20)»: negative cases, true before the feature (the old scope ignored vitals); they pin the GREEN against reread storms.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] main_screen_test cities-refresh group stubs refreshQuests**
- **Found during:** Task 2 GREEN
- **Issue:** «the same set in another order or other status changes refresh nothing (D-11)» changes `currentLifePoints` on `city-marker-1`; the real `QuestScopeListener` mounted by `MainScreen` now (correctly) calls `questCubit.refreshQuests`, unstubbed on the mock → `type 'Null' is not a subtype of type 'Future<void>'`.
- **Fix:** the group `setUp` stubs `questCubit.refreshQuests(cityId: any(named: 'cityId'))` (comment D-20). The test's own assertion (`verifyNever(refreshCities)`) is unchanged.
- **Files modified:** test/screens/mainScreen/main_screen_test.dart (outside `files_modified`)
- **Commit:** a55cdce

**2. [Rule 1 - Test] the «whole again» board test pumps twice after the reread**
- **Found during:** Task 2 GREEN
- **Issue:** after `questStates.add(...)` one `pump()` left the Board unrebuilt (debug print: the mock state was already the new list, the `Sheet` and `QuestInfoSheet` still held the flagged quest); a second `pump()` delivers it. The test also asserts `isEnabled == false` before the reread so the case is RED before GREEN (as written in the plan it would have been green at the first run).
- **Commit:** 42fb4ed (pre-check), a55cdce (second pump)

## Gates

- `flutter test test/models/quest test/screens/mainScreen/tabs/board test/shared/components/popup/quest_info_sheet_test.dart`: 295 passed (Task 1).
- `flutter test test/screens/mainScreen/tabs/board test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart`: 242 passed (Task 2).
- Consumers: `flutter test test/screens/mainScreen test/models test/graphql test/shared`: 2336 passed.
- Analyzer: `47 issues found` (all info), 0 error, 0 warning — unchanged.
- `dart format` on every touched file one by one: lib files already clean; test files reflowed only in the new code.
- No fragment selection: `git diff develop...HEAD --stat -- lib/graphql/fragments` prints nothing. No new Cloudinary asset id.

## Known Stubs

None. Until the gated plan 18-12 selects `noEffect` in the quest fragment, the flag is always `false` on a real build (designed).

## Self-Check: PASSED
