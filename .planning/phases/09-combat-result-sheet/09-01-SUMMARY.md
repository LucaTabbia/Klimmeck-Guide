---
phase: 09-combat-result-sheet
plan: 01
subsystem: models
tags: [flutter, dart, equatable, combat, quest-result, fixtures, labels]

# Dependency graph
requires:
  - phase: BE Phase 9 (Combat Result and Admin Outcomes, merged on BE develop @ 10e5f43)
    provides: "`QuestResult` SDL (`QuestOutcome`, `QuestResultQuest`, `SpellUsage`, `QuestRewards`), push `questEnd` copy (BE §4)"
  - phase: 07-travel
    provides: "tolerant parse boundary pattern (`ActiveTravel.tryFromJson`)"
  - phase: 05-notifications-infrastructure
    provides: "`PushEvent` + `dedupKey`, `NotificationCategory.questEnd`"
provides:
  - "Flutter-free `QuestResult` family (`QuestOutcome`, `QuestResultQuest`, `SpellUsage`, `QuestRewards`, `QuestResult`) with fromJson / tryFromJson / toJson, UTC instants, unmodifiable lists"
  - "`QuestOutcome.label` sheet headers (D-04) and `QuestOutcome.fromWire`"
  - "`QuestType.label` provisional Italian copy (C2)"
  - "pinning test of the 28 `InjuryType` labels and of the FE/BE name parity (C1, COMBAT-04)"
  - "`questEndTitle`, `questEndBody`, `questEndEventOf(result)` (D-12, dedupKey `questEnd|<id>`)"
  - "`test/helpers/fixtures/quest_result_fixtures.dart` (Wave 0) with one payload per outcome"
affects: [09-03, 09-06, 09-07, 09-10, 09-11, 09-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-entry tolerance inside a strict boundary: required scalars throw inside `fromJson`, `tryFromJson` turns any failure into `null`; optional parts (unknown injury, orphan item, unknown title/type, null spell) degrade per entry"
    - "Nested foreign models fed only the selected keys (`Enemy.fromJson({id, name, imagePath})`) so a stray field can never crash the parser"

key-files:
  created:
    - lib/models/quest_result/quest_outcome.dart
    - lib/models/quest_result/quest_result_quest.dart
    - lib/models/quest_result/spell_usage.dart
    - lib/models/quest_result/quest_rewards.dart
    - lib/models/quest_result/quest_result.dart
    - lib/models/quest_result/quest_end_event.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/models/quest_result/quest_outcome_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/models/quest_result/quest_end_event_test.dart
    - test/models/enums/quest_type_test.dart
    - test/models/enums/injury_type_test.dart
  modified:
    - lib/models/enums/quest_type.dart

key-decisions:
  - "QuestResult.assetQuantitiesFrom is a public static shared with QuestRewards; orphan items (item == null) are dropped"
  - "Unknown titleBefore/titleAfter parse to null (no throw); unknown outcome throws inside fromJson so tryFromJson yields null"
  - "toJson writes acknowledgedAt only when non-null, mirroring the pre-9.2 wire shape"

patterns-established:
  - "Quest result fixtures: questResultJson(...) + successResultJson / failureResultJson / rescuedResultJson / deathResultJson / gmCompletedResultJson / rescuerSuccessResultJson + questResult(json)"

requirements-completed: []

# Metrics
duration: 6min
completed: 2026-10-27
---

# Phase 9 Plan 01: Quest Result Model Family Summary

**Tolerant, Flutter-free `QuestResult` model of the BE Phase 9 contract for all five outcomes, with recorded fixtures, Italian outcome/quest-type labels, pinned injury labels and the single-source `questEnd` banner event.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-10-27T22:28:24Z
- **Completed:** 2026-10-27T22:34:36Z
- **Tasks:** 2 (4 commits, TDD)
- **Files modified:** 13 (12 created, 1 hand-edited)

## Accomplishments

- `QuestResult.fromJson` parses success, failure, rescued, death, gmCompleted and the rescuer success; `tryFromJson` returns `null` for non-maps, missing `id`, unknown outcome, malformed `hpBefore` or `resolvedAt` (T-9-01).
- Per-entry tolerance: unknown injury names, orphan consumables/reward items, unknown titles and quest types, `spell: null` usages; `acknowledgedAt` optional (D-21).
- Enemy parsed only from `id/name/imagePath` (T-9-02, tested with a payload carrying `locations`); equipment rewards keep `equipType` and parse as `EquipmentItem` (T-9-03).
- `QuestType.label` appended by hand to the DIRTY enum (16 added lines, 0 deleted); `injury_type.dart` untouched; `lib/graphql` untouched.
- `questEndEventOf(result)` builds `PushEvent(questEnd, id: result.id, sentAt: result.resolvedAt)` with the generic BE copy (T-9-04).

## Task Commits

1. **Task 1 RED: failing tests for the quest result model** - `f44f76d` (test)
2. **Task 1 GREEN: parse the quest result of the five outcomes** - `d69ff98` (feat)
3. **Task 2 RED: pin injury labels and expect quest type labels** - `e527b0b` (test)
4. **Task 2 GREEN: add quest type labels and the quest end event** - `526efbb` (feat)

## TDD evidence

- Task 1 RED: compile failure — `test/models/quest_result/quest_result_test.dart: Error: Undefined name 'QuestResult'`, `test/helpers/fixtures/quest_result_fixtures.dart:214:5: Error: Undefined name 'QuestResult'` (missing model files).
- Task 2 RED: `quest_type_test.dart:7:29: Error: The getter 'label' isn't defined for the type 'QuestType'`; `quest_end_event_test.dart: Error when reading 'lib/models/quest_result/quest_end_event.dart': No such file or directory`.
- `injury_type_test.dart` passed immediately (3/3): it is a **pinning test** (C1: the 28 labels already exist in `InjuryTypeExtension.label`), not a RED.

## Verification

- `flutter test test/models/quest_result` + `test/models/enums`: 46 green.
- Plan-end quick run (`test/models test/utils test/graphql test/repository test/tool test/shared test/screens`): 2121 green.
- Full suite: 2139 → 2180 green (+41).
- `flutter analyze`: 53 issues (baseline 53), 0 errors.
- `dart format --set-exit-if-changed` clean on every new file.

## Decisions Made

- `QuestRewards.isEmpty` uses `Coins.toCopper() == 0` plus empty items; `QuestResult.hasRewards => !rewards.isEmpty`.
- `QuestResult.assetQuantitiesFrom(Object?)` is public static (reused by `QuestRewards`), returns an unmodifiable list without orphans; a non-list yields `const []`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test setup of the enemy-with-locations case**
- **Found during:** Task 1 GREEN
- **Issue:** the extra test that injects `locations` into the enemy mutated the fixture's inferred `Map<String, String>` literal and threw `type 'List<String>' is not a subtype of type 'String'` in the test itself.
- **Fix:** the test now rebuilds the enemy as a `<String, dynamic>{...}` map before adding `locations`.
- **Files modified:** test/models/quest_result/quest_result_test.dart
- **Commit:** d69ff98 (committed with the GREEN, noted in the commit body)

Additional tests beyond the plan's list (no behaviour change): learned spell parsing, orphan reward item, enemy with `locations`, the `acknowledged` round trip. Otherwise the plan was executed as written.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

- 09-03 (documents/repository), 09-06 (queue), 09-07 (sheet), 09-10 (presenter) can consume `QuestResult`, `QuestResult.tryFromJson`, the fixtures and `questEndEventOf`.

## Self-Check: PASSED

- All 13 files exist; commits f44f76d, d69ff98, e527b0b, 526efbb found in `git log`.
