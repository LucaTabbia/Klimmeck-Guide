---
phase: 09-combat-result-sheet
plan: 02
subsystem: models
tags: [flutter, dart, equatable, combat, awaiting-aid, graphql-fragment, board]

# Dependency graph
requires:
  - phase: BE Phase 9 (Combat Result and Admin Outcomes, on BE develop)
    provides: "`AwaitingAid { quest: ID!, aidQuest: ID!, since: DateTime! }`, nullable `CharacterStatus.awaitingAid`"
  - phase: 07-travel
    provides: "tolerant parse boundary pattern (`ActiveTravel.tryFromJson`), `travellingCharacterJson` fixture"
  - phase: 06-quest-board
    provides: "`questSheetFamilyOf`, `QuestInfoSheet` families"
provides:
  - "Flutter-free `AwaitingAid` (questId, aidQuestId, UTC since) with fromJson / tryFromJson / toJson"
  - "`CharacterStatus.awaitingAid` (null for absent, null or malformed), in toJson, props, kept by copyWith"
  - "`CharacterFragment.statusFields` selects `awaitingAid { quest aidQuest since }`"
  - "`awaitingAidJson(...)` fixture and `travellingCharacterJson(awaitingAid:)`"
  - "`questSheetFamilyOf(QuestType.aid) == QuestSheetFamily.combat` (D-17, COMBAT-10)"
affects: [09-03, 09-04, 09-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Optional status sub-object behind a `tryFromJson` boundary: legacy, null and malformed payloads all become `null`, the rest of the status parses"

key-files:
  created:
    - lib/models/character/awaiting_aid.dart
    - test/models/character/awaiting_aid_test.dart
  modified:
    - lib/models/character/character_status.dart
    - lib/graphql/fragments/character_fragment.dart
    - lib/models/quest/quest_sheet_details.dart
    - lib/models/notification_category.dart
    - test/models/character/character_status_test.dart
    - test/graphql/character_fragment_test.dart
    - test/helpers/fixtures/travel_fixtures.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - .planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md

key-decisions:
  - "`since` is normalised with `.toUtc()` on parse and serialised as UTC ISO (ends with `Z`)"
  - "`copyWith` passes `awaitingAid` through unchanged (not a parameter), like `activeTravel` and `spellStates`"
  - "`awaitingAid` is selected right after `activeTravel` in `statusFields`; no new named operation, registry stays at 34"

patterns-established:
  - "Wounded fixture: `travellingCharacterJson(awaitingAid: awaitingAidJson())`; without the argument the key is absent"

requirements-completed: []

# Metrics
duration: 9min
completed: 2026-10-27
---

# Phase 9 Plan 02: Awaiting Aid Status and Aid Combat Family Summary

**`CharacterStatus.awaitingAid` parsed tolerantly from a new `awaitingAid { quest aidQuest since }` selection of the character fragment, a wounded-character fixture for the map plans, the `aid` quest moved to the combat sheet family, and the Phase 5 handoff corrected about the `questEnd` id.**

## Performance

- **Duration:** ~9 min
- **Completed:** 2026-10-27
- **Tasks:** 2 (5 commits: 2 RED, 2 GREEN, 1 docs)
- **Files modified:** 12 (2 created, 10 modified)

## Accomplishments

- `AwaitingAid` model (Flutter-free, Equatable) with UTC `since`; `tryFromJson` returns `null` for `null`, a string, a map without `aidQuest`, an unparsable `since` (T-9-05).
- `CharacterStatus.awaitingAid`: absent / null / malformed → `null`, other fields still parse; mirrored in `toJson`, part of `props`, kept by `copyWith`.
- `statusFields` selects `awaitingAid { quest aidQuest since }` (verified on BE `origin/develop`: `src/models/character/awaiting-aid.model.ts`); `character`/`characterUpdated` still parse as single operations; `test/tool` registry tests green (T-9-06).
- `questSheetFamilyOf(QuestType.aid)` → combat; `QuestInfoSheet` renders the combat family for `aid` with the enemy name and no `Punti canale` cost line.
- D-22: `fromWireType` doc and the Phase 5 BACKEND-NOTES no longer mention a `combatResult` push; `questEnd.id` documented as the `QuestResult` id read with `questResult(id)`.

## Task Commits

1. **Task 1 RED: expect the awaiting aid status** - `95df05b` (test)
2. **Task 1 GREEN: parse and select the awaiting aid status** - `538d1c3` (feat)
3. **Task 2 RED: expect the aid quest in the combat family** - `70fe948` (test)
4. **Task 2 GREEN: show the aid quest with the combat sheet** - `1edc141` (feat)
5. **Task 2 docs: correct the questEnd id in the phase 5 handoff** - `461a802` (docs)

## TDD evidence

- Task 1 RED: compile failure — `character_status_test.dart:2:8: Error: Error when reading 'lib/models/character/awaiting_aid.dart': No such file or directory`; `Error: The getter 'awaitingAid' isn't defined for the type 'CharacterStatus'`.
- Task 2 RED: 3 failures — `questSheetFamilyOf ... (aid is combat, D-17)`: `Expected: QuestSheetFamily.combat, Actual: QuestSheetFamily.service`; `families aid renders the combat family` and `combat aid shows the enemy name and no cost line`: `Found 0 widgets with key [<'questSheet.family.combat'>]`.

## Verification

- Task 1 verify (`test/models/character test/graphql test/tool`): 114 green; analyzer on the touched paths: no issues.
- Task 2 verify (`test/models/quest`, `quest_info_sheet_test.dart`, `test/screens/mainScreen/tabs/board`): 162 green; `grep -rn combatResult lib` empty.
- Full suite: 2180 → 2199 green (+19).
- `flutter analyze`: 53 issues (baseline 53), 0 errors.
- `dart format --set-exit-if-changed` clean on every touched Dart file (all were formatter-clean before editing).
- Schema-check registry: untouched, 34 documents.

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

None in behaviour. Small test-side choices:
- `statusJson` in `character_status_test.dart` gained an `awaitingAid` parameter with a private `_absent` sentinel so the tests can distinguish "key absent" from "key null".
- Extra tests beyond the plan list: non-UTC `since` normalised to UTC; the "absent unless requested" fixture check lives in `character_status_test.dart`.
- The aid widget test passes a viewer (`twitchPoints: 1200`) so the absence of the `Punti canale` line is meaningful.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

- 09-08 can read `character.status?.awaitingAid` (pawn label, drag gate, disabled pages) and build wounded characters with `travellingCharacterJson(awaitingAid: awaitingAidJson())`.
- 09-03 schema check will validate the `awaitingAid` selection against BE develop.

## Self-Check: PASSED

- Files `lib/models/character/awaiting_aid.dart`, `test/models/character/awaiting_aid_test.dart` exist; commits 95df05b, 538d1c3, 70fe948, 1edc141, 461a802 present in `git log`.
