---
phase: 18-heal-quests-by-size
plan: 04
subsystem: quests
tags: [quests, quest-sheet, cure, injuries, board, map, tdd]
requires: ["18-01", "18-03"]
provides:
  - "QuestInfoSheet(characterInjuries:) + cureLineKey / lifeLineKey: cure line and life row in the combat, narrative and service bodies, keyed by quest.prizes?.cure"
  - "characterInjuriesOf(CharacterState) -> List<InjuryType>? in lib/screens/mainScreen/characterCubit/character_selectors.dart"
  - "QuestInfoOverlay(characterInjuries:) forwarded to the sheet"
  - "Board and WorldMap feed the live injuries through BlocSelector<CharacterCubit, CharacterState, List<InjuryType>?>"
affects: [18-05, 18-10, 18-12, 18-13]
tech-stack:
  added: []
  patterns: ["strings computed in the widget from the pure line helpers (D-21); shared top-level selector for BlocSelector"]
key-files:
  created:
    - lib/screens/mainScreen/characterCubit/character_selectors.dart
    - test/screens/mainScreen/characterCubit/character_selectors_test.dart
  modified:
    - lib/shared/components/popup/quest_info_sheet.dart
    - lib/screens/mainScreen/tabs/board/board.dart
    - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
    - test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
decisions:
  - "Cure line above the life row, both right after the time line (combat, service) / after the lore (narrative) (planner's choice, D-03, D-04)"
  - "characterInjuriesOf lives in character_selectors.dart, shared by Board and Map (planner's choice, D-19)"
  - "Narrative body: lore and cure rows share one scroll region; cost, title and slot lines stay pinned at the bottom (Rule 1 fix of an overflow)"
metrics:
  duration: "~25 min"
  completed: 2026-11-10
  tasks: 2
  files: 10
---

# Phase 18 Plan 04: Quest sheet cure rows Summary

The quest sheet shows «Cura le tue ferite: …» (only the viewer's own curable injuries) and «Vita: almeno il N%» for any quest whose `prizes.cure` is present, in all three family layouts. The Board and the Map lane sheet feed it the live injuries of the current character through a shared `characterInjuriesOf` selector.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | QuestInfoSheet computes and renders the two rows in the three families | 7a8e495 (test), bc9372e (feat) |
| 2 | The Board and the Map pass the character's injuries to the sheet | a2730a4 (test), 0734bcf (feat) |

## Names and signatures created

- `QuestInfoSheet({..., this.travelPreview, this.characterInjuries})`, `final List<InjuryType>? characterInjuries;`
- `static const Key cureLineKey = ValueKey('questSheet.cureLine');`, `static const Key lifeLineKey = ValueKey('questSheet.lifeLine');`
- private `List<Widget> _cureLines()` using `curableInjuriesLine(quest!.prizes?.cure, characterInjuries)` and `lifeShareLine(cure)`, style `bodyLarge`
- `List<InjuryType>? characterInjuriesOf(CharacterState state)` (`lib/screens/mainScreen/characterCubit/character_selectors.dart`)
- `QuestInfoOverlay({..., this.onAbandon, this.characterInjuries})`, `final List<InjuryType>? characterInjuries;`
- Test helpers: `quest_info_sheet_test` `_pump(..., characterInjuries:)`, `_cureQuest({type = 'heal', share = 0.5, canHeal})`, `_inFamily(familyKey, lineKey)`, `_textOf(tester, key)`; `board_test` `_boardQuest(..., prizes:)`, `_injuredCharacterJson(List<String>)`, `pumpBoard(..., characterStates:)`; `quest_info_overlay_test` `pumpOverlay(..., quest:, characterInjuries:)`.
- The Map test lives in `world_map_travel_test.dart` (group `'cure rows on the lane sheet (BE Phase 18)'`), as in `files_modified`: the harness (`pumpWorldMap`, `travellingCharacterJson`) is defined there; `world_map_availability_test.dart` imports it and needs the same setup.

## RED failures observed

- Task 1: compile failure — `No named parameter with the name 'characterInjuries'`, `Member not found: 'cureLineKey'` / `'lifeLineKey'`.
- Task 2: `character_selectors_test` — `Error when reading 'lib/screens/mainScreen/characterCubit/character_selectors.dart'`, `Method not found: 'characterInjuriesOf'`; `quest_info_overlay_test` — `No named parameter with the name 'characterInjuries'`; the two Board tests and the Map test — `Found 0 widgets with text "Cura le tue ferite: contusione"`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Narrative sheet overflowed with the two new rows**
- **Found during:** Task 1 GREEN
- **Issue:** `_narrativeBody` is a non-scrolling `Column` (only the lore paragraphs scroll in an `Expanded`). Spreading `..._cureLines()` before the cost line as the plan wrote made «a narrative quest with a cure shows the two rows (D-05)» fail with `A RenderFlex overflowed by 66 pixels on the bottom` on the landscape phone.
- **Fix:** the narrative body computes `final cureLines = _cureLines();` and puts the lore text and the cure rows in one `Expanded` → `SingleChildScrollView` → `Column`, shown when there is lore or a cure row; cost, title and slot lines stay pinned at the bottom exactly as before. With no lore and no cure the layout is unchanged.
- **Consequence on the acceptance grep:** `grep -c "_cureLines()," quest_info_sheet.dart` = 2 (combat, service) instead of 3; the narrative body calls it as `_cureLines();` (`grep -c "_cureLines()"` = 4: definition, two spreads, one assignment). Cure line still above the life row and above the cost line in the narrative family.
- **Files modified:** lib/shared/components/popup/quest_info_sheet.dart
- **Commit:** bc9372e

**2. [Test syntax] `const` map with `double` keys**
- The «elides the article» test first used a `const` map `{0.8: …, 0.5: …, 1: …}`, which does not compile (double keys in a const map); replaced before the RED commit by a const list of records `(share, line)`. No effect on the committed history.

## Gates

- Analyzer: `47 issues found` — all info, 0 error, 0 warning (unchanged baseline); `ANALYZE_GATE_OK` after both tasks.
- Tests: `quest_info_sheet_test.dart` + `test/models/quest` 240 green; `character_selectors_test.dart` + `test/screens/mainScreen/tabs/board` + `test/screens/mainScreen/tabs/map` 306 green; consumers `test/screens/mainScreen` + `test/shared` + `test/models/quest` 1539 green.
- Formatted (one by one): `quest_info_sheet.dart`, `quest_info_sheet_test.dart`, `character_selectors.dart`, `character_selectors_test.dart`, `board.dart`, `board_test.dart` (reflowed only the new code), `quest_info_overlay.dart`, `quest_info_overlay_test.dart`, `world_map.dart`, `world_map_travel_test.dart`. None of the formatter-dirty candidates touched.
- Other acceptance greps: `curableInjuriesLine(` 1, `lifeShareLine(` 1, both ValueKeys 1, `final List<InjuryType>? characterInjuries` 1, `QuestType.heal`/chrome 0, `utils/` in `quest_sheet_details.dart` 0, `git diff --stat -- lib/models` empty since ef6e936; `D-05)` 6, `D-19)` 1, `D-21)` 1, `Vita: almeno l'80%` 1 in the sheet test; `characterInjuriesOf` 1 in board.dart and world_map.dart, `characterInjuries: injuries` 1 in each, `characterInjuries: characterInjuries` 1 in the overlay, `D-19)` 2 / 1 / 1 in board / overlay / selectors tests, `with no reload` 0. Trailer check 0 on all four commits.
- Every new test was red before its implementation; none green at the first run.

## Threat surface

T-18-10 / T-18-11 mitigated as planned: the sheet prints only the helpers' strings, the only filter is `curableInjuriesLine` on the current character's `status.injuries`, the full `canHeal` is never rendered, no type check. No new surface.

## Known Stubs

None. The `cure` field is not selected on the wire before the gated plan 18-12, so on device the rows appear only once 18-12 lands (by design).

## Self-Check: PASSED
