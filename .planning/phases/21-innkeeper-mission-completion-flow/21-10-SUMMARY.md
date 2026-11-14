---
phase: 21-innkeeper-mission-completion-flow
plan: 10
subsystem: models
tags: [mission-draft, wire-inputs, lenient-parsing, guided-mission]
requires: ["21-09"]
provides:
  - "lib/models/mission/mission_draft.dart — MissionDraftStep, MissionParticipant, MissionDraft.tryFromJson + prizeOf"
  - "lib/models/mission/mission_fight.dart — MissionItemUsage, MissionSpellUsage, MissionFightEffects, MissionFightOutcome (effective = corrected ?? simulated), MissionFightVerdict (Vittoria/Sconfitta), MissionFightEnemy, MissionFight (isSimulated, outcomeOf)"
  - "lib/models/mission/mission_enemy.dart — MissionEnemy (isLegendary)"
  - "lib/models/mission/mission_prize.dart — MissionPrizeItem (toJson), MissionPrize"
  - "lib/models/mission/mission_prize_options.dart — MissionPrizeOptions (catalogueItems, itemById, petById, spellById; block items/pet/spell)"
  - "lib/models/mission/mission_limits.dart — BE caps (10 fights, 10 enemy entries, quantity 1..20, prize item 99)"
  - "lib/models/mission/mission_entries.dart — missionEntriesOf, missionIntOf, missionInstantOf (shared lenient readers)"
  - "lib/models/request/mission_draft_inputs.dart — MissionEnemyInput, MissionCorrection, MissionFightInput, MissionPrizeInput, SaveMissionDraftInput, SimulateMissionFightInput, fightsInputOf / fightsInputWithEnemies / fightsInputWithCorrections"
  - "test/helpers/fixtures/mission_fixtures.dart — Wave 0 fixtures"
affects: [21-11, 21-12, 21-13, 21-14, 21-15, 21-16]
tech-stack:
  added: []
  patterns: ["per-entry tryFromJson + asNameMap enums (Pitfall 8)", "replace-all fights section rebuilt from the served draft, full corrections list with hpAfter"]
key-files:
  created:
    - lib/models/mission/mission_entries.dart
    - lib/models/mission/mission_enemy.dart
    - lib/models/mission/mission_fight.dart
    - lib/models/mission/mission_draft.dart
    - lib/models/mission/mission_prize.dart
    - lib/models/mission/mission_prize_options.dart
    - lib/models/mission/mission_limits.dart
    - lib/models/request/mission_draft_inputs.dart
    - test/helpers/fixtures/mission_fixtures.dart
    - test/models/mission/mission_fight_test.dart
    - test/models/mission/mission_draft_test.dart
    - test/models/mission/mission_prize_test.dart
    - test/models/request/mission_draft_inputs_test.dart
  modified: []
decisions:
  - "Shared lenient readers (entries, int, instant) live in one new file mission_entries.dart instead of a private copy in each model file (Clean Code, zero duplication)"
  - "MissionPrizeOptions parses the block per entry (prizeItem and randomLoot via AssetQuantity.tryFromJson, pet via Pet.tryFromEntryJson, spell leniently) instead of QuestPrizes.fromJson in a try: a bad randomLoot entry drops that entry, not the whole block"
  - "A served outcome with neither simulated nor corrected, in a fight that carries corrections, is completed with hpAfter = hpBefore and an empty effect (the same thing the BE does for an omitted hpAfter)"
  - "fightsInputWithCorrections appends given corrections for characters without a served outcome after the served ones"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 21 Plan 10: Mission draft models and wire inputs Summary

Flutter-free, lenient models of the served `MissionDraft` / `MissionPrizeOptions` (BE 22-RESEARCH §Q9 + the D-17 additions) and the wire inputs, with pure builders that rebuild the replace-all `fights` section of `saveMissionDraft` from the served draft, always sending the full corrections list with `hpAfter` for every participant.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Wave 0 fixtures and the served read models | `378a7350` test, `d9d15e76` feat |
| 2 | Wire inputs and the served-draft input builders | `77d586c2` test, `5d5afe56` feat |
| 3 | Bookkeeping | this commit |

### RED evidence

- Task 1: `flutter test test/models/mission` → `+0 -3: Some tests failed.` (the three test files fail to load: `lib/models/mission/*` missing).
- Task 2: `flutter test test/models/request/mission_draft_inputs_test.dart` → `+0 -1: Some tests failed.` (load failure: `mission_draft_inputs.dart` and `mission_limits.dart` missing).

### GREEN

- `flutter test test/models` → `+1032 All tests passed` after Task 1, `+1048 All tests passed` after Task 2.
- Every case went green on the first GREEN run.
- Analyzer gate after each code task: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK`.

### Formatted files (one by one)

`test/helpers/fixtures/mission_fixtures.dart` (unchanged), `test/models/mission/mission_fight_test.dart`, `mission_draft_test.dart`, `mission_prize_test.dart`, `test/models/request/mission_draft_inputs_test.dart`, and all eight new lib files.

### Acceptance greps

- `grep -rn "package:flutter" lib/models/mission` → nothing; `grep -rn "byName(" lib/models/mission` → nothing.
- `mission_fight.dart`: `injuriesBefore` 5, `consumablesAvailable` 6, `spellsAvailable` 6.
- `mission_fight_test.dart` «Pitfall 8» 4; `mission_draft_test.dart` «D-24» 1.
- `mission_draft_inputs.dart` builders 3 (single-line grep count; each name appears more often over wrapped lines); limits greps 1/1/1; no Flutter import.
- `mission_draft_inputs_test.dart`: «D-14» 2, «D-15» 2, «D-24» 4, «BE handoff» 1.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Clean Code] Shared lenient readers in a new file**
- **Found during:** Task 1
- **Issue:** the five model files would each have needed the same "list per entry / int or null / UTC instant" helpers.
- **Fix:** `lib/models/mission/mission_entries.dart` (outside `files_modified`), Flutter-free, three top-level functions.
- **Commit:** `d9d15e76`

**2. [Rule 2 - Pitfall 8] Block parsed per entry**
- **Found during:** Task 1
- **Issue:** the plan suggested `QuestPrizes.fromJson` inside a `try` → empty block on failure; one bad `randomLoot` entry would lose every block item, the pet and the spell.
- **Fix:** per-entry parsing of `prizeItem`, `randomLoot`, `pet`, `spell`. Pinned by «a malformed catalogue entry is dropped, the options stay (Pitfall 8)».
- **Commit:** `d9d15e76`

Extra test cases beyond the plan (pin the same rules): a malformed enemy entry / prize item dropped, an unknown title read null, options without character null, toggling an absent injury adds it, `MissionEnemyInput.of`.

## Known Stubs

None. Nothing reads these models yet (21-11 documents/repository, 21-12+ Cubits and UI).

## Threat Flags

None: models only, no logging, no network surface.

## Self-Check: PASSED

- All 13 created files exist; commits `378a7350`, `d9d15e76`, `77d586c2`, `5d5afe56` are in `git log`.
