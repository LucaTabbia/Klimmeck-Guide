---
phase: 21-innkeeper-mission-completion-flow
plan: 11
subsystem: graphql
tags: [mission-draft, graphql-documents, schema-check, innkeeper-repository, guided-mission]
requires: ["21-10"]
provides:
  - "lib/graphql/fragments/mission_draft_fragment.dart — MissionEnemyFragment.fields (const), MissionDraftFragment.fields (getter)"
  - "lib/graphql/queries/mission_queries.dart — MissionQueries.getMissionDraft / listMissionEnemies / getMissionPrizeOptions"
  - "lib/graphql/mutations/mission_mutations.dart — MissionMutations.startMissionDraft / saveMissionDraft / simulateMissionFight / completeGuidedMission (getters), discardMissionDraft (const)"
  - "KlimmeckGraphQl — getMissionDraft, startMissionDraft, saveMissionDraft, simulateMissionFight, discardMissionDraft, completeGuidedMission, getMissionEnemies, getMissionPrizeOptions"
  - "InnkeeperRepository — readMissionDraft, startMissionDraft, saveMissionDraft, simulateMissionFight, discardMissionDraft, completeGuidedMission, listMissionEnemies, readMissionPrizeOptions (all through _guard)"
affects: [21-12, 21-13, 21-14, 21-15, 21-16, 21-17]
tech-stack:
  added: []
  patterns: ["one draft fragment, one parser (MissionDraft.tryFromJson via _missionDraftFrom)", "count pins moved RED-first (Pitfall 7)"]
key-files:
  created:
    - lib/graphql/fragments/mission_draft_fragment.dart
    - lib/graphql/queries/mission_queries.dart
    - lib/graphql/mutations/mission_mutations.dart
    - test/graphql/mission_documents_test.dart
    - test/repository/services/graphql/graphql_mission_test.dart
  modified:
    - tool/schema_check/schema_check_documents.dart
    - test/tool/schema_check_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/loot_fragment_test.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/innkeeper_repository.dart
    - test/repository/innkeeper_repository_test.dart
decisions:
  - "The mission fragment file is NOT exported from fragments.dart: the queries/mutations import it directly (keeps the barrel unchanged; no other consumer)"
  - "getMissionPrizeOptions throws FormatException on unparsable options (null payload included), like the draft operations"
  - "getMissionEnemies always sends showAll (false by default) instead of omitting it: the SDL default is false anyway"
metrics:
  duration: "~30 min"
  completed: "2026-11-14"
  tasks: 3
  files: 13
---

# Phase 21 Plan 11: Mission documents, registry, service and repository operations Summary

One draft fragment and one enemy fragment, eight GraphQL documents named after the final BE Phase 22 wire (registry 47 → 55), eight `KlimmeckGraphQl` methods parsing every draft through `MissionDraft.tryFromJson`, and eight `InnkeeperRepository` operations through `_guard` — none called by any screen yet (D-28).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Draft and enemy fragments, eight documents, registry 55 and pins | `e906610c` test(graphql): expect the mission draft documents; `18c63440` feat(graphql): add the guided mission documents |
| 2 | Mission service methods and repository operations through _guard | `cb4e3419` test(shared): expect the guided mission operations; `7f4ebd4f` feat(shared): add the guided mission operations |
| 3 | Bookkeeping | `docs(phase-21): record plan 11 progress` |

## RED evidence

- Task 1: `flutter test test/graphql test/tool` → `+182 -5`: the four count pins (expected 55, actual 47) and `mission_documents_test.dart` failing to load (missing `mission_draft_fragment.dart`, `mission_queries.dart`, `mission_mutations.dart`).
- Task 2: `flutter test test/repository/services/graphql/graphql_mission_test.dart test/repository/innkeeper_repository_test.dart` → `-2` (both files fail to compile: `getMissionDraft`, `startMissionDraft`, … not defined on `KlimmeckGraphQl` / `InnkeeperRepository`).
- No case was green at the first run (all were behind compile failures or the count change).

## GREEN

- `flutter test test/graphql test/tool` → `+206: All tests passed!`
- `flutter test test/repository` → `+952: All tests passed!`
- Analyzer: `47 issues found.` (47 info / 0 warning / 0 error) → `ANALYZE_GATE_OK` after each code task.
- Registry: 55 documents; the 8 mission keys grep = 8; `grep -rn "length, 47)" test/tool test/graphql` empty; `grep -rn missionInProgress lib/graphql` empty.
- Formatted one by one (all were formatter-clean before): the three new lib files, `schema_check_documents.dart`, the four pin files, `mission_documents_test.dart`, `graphql.dart`, `innkeeper_repository.dart`, `innkeeper_repository_test.dart`, `graphql_mission_test.dart`.
- No `appLog` added (`git diff HEAD~3 -- lib | grep -E "^\+.*appLog"` empty); nothing under `lib/screens` calls the new methods.

## Contract check (BE SDL pinned at `ce7253b3`)

Documents dumped with `dump_documents.dart` and validated with `validate_documents.js` against the BE SDL at commit `ce7253b3` (read-only, temp dir outside the repo):
- `GetMissionDraft`, `StartMissionDraft`, `DiscardMissionDraft`: **OK** — the whole `MissionDraftFragment` (incl. `injuriesBefore`, `consumablesAvailable`, `spellsAvailable`, `verdict`, `simulated`, `corrected`, `prizes`) and `MissionEnemyFragment` match field names and types of that SDL.
- `ListMissionEnemies`, `GetMissionPrizeOptions`, `SaveMissionDraft`, `SimulateMissionFight`, `CompleteGuidedMission`: FAIL (operations / input types not in that SDL yet) — expected.
- No mismatch found between that SDL and the research for the parts already there.

**Note:** the 8 mission documents are valid only on a BE with Phase 22: never sent before 21-16; a manual `validate_documents.js` run between this plan and the gate FAILS on today's SDL (expected — the CI has no schema step; the schema check runs in 21-16/21-17 on the merged SDL).

## Deviations from Plan

None in behaviour. Minor notes:
- The draft fragment doc comment does not name the bound fields literally, so `grep -c injuriesBefore` on the fragment stays at 1 as the acceptance wants.
- Commit scope `shared` used for the repository commits (`repository` is not in the REPO-RULES list); test subject `test(shared): expect the guided mission operations`.
- Extra cases beyond the plan list (start/save/prize-options malformed, discard false at the service, default `showAll`, FORBIDDEN on complete for T-21-35, the per-family query/mutation type check, the draft operations sharing the draft selection).

## Threat Flags

None: the new surface is the one in the plan's threat model (T-21-35..38).

## Known Stubs

None.

## Self-Check: PASSED
