---
phase: 21-innkeeper-mission-completion-flow
plan: 17
subsystem: innkeeper
tags: [graphql, schema-check, innkeeper, retirement, gate]
requires:
  - phase: 21-16
    provides: "«Completa» and the resume open the wizard; schema gate green on BE f82ab278"
provides:
  - "Phase 10 override form, its models, service/repository path and document removed"
  - "schema-check registry at 54 documents, 54/54 OK on the merged SDL"
  - "automated phase gate green; 21-VALIDATION.md nyquist_compliant: true"
affects: [21-18]
tech-stack:
  added: []
  patterns: ["RED-first deletion in groups of at most 8 files, targeted tests + analyzer after each"]
key-files:
  created: []
  modified:
    - tool/schema_check/schema_check_documents.dart
    - lib/screens/innkeeper/components/completion_recap.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/innkeeper_repository.dart
    - lib/graphql/mutations/mission_mutations.dart
    - test/helpers/mocks.dart
  deleted:
    - lib/screens/innkeeper/request_completion_route.dart
    - lib/screens/innkeeper/request_completion_screen.dart
    - lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart
    - lib/screens/innkeeper/requestCompletionCubit/request_completion_state.dart
    - lib/screens/innkeeper/components/participant_override_section.dart
    - lib/models/request/participant_draft.dart
    - lib/models/request/participant_override.dart
    - lib/models/request/complete_pending_request_input.dart
    - lib/graphql/mutations/pending_request_mutations.dart
key-decisions:
  - "The wizard is the only completion path; the Phase 10 override form and its document are gone (D-25, D-28)"
  - "OUTCOME_OVERRIDE_INVALID stays pinned through saveMissionDraft in innkeeper_repository_test (the deleted complete group was not its only pin)"
metrics:
  duration: ~25 min
  completed: 2026-11-14
  tasks: 3
  files: 30
---

# Phase 21 Plan 17: Phase 10 completion form retired Summary

The Phase 10 override form (route, screen, Cubit, override section, `ParticipantDraft`, `ParticipantOverride`, `CompletePendingRequestInput`, the service call, `InnkeeperRepository.complete` and its mutation document) is deleted RED-first in four groups; the schema-check registry drops to 54 and every document validates on the merged BE SDL (`f82ab278`); full suite 4678 green. The branch needs a BE with Phase 22.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 (RED) | a0a9b7d6 | test(graphql): expect the completion form document retired |
| 2 G1 | 7b229d24 | refactor(innkeeper): retire the Phase 10 completion screen |
| 2 G2 | 2dac3a9f | refactor(innkeeper): retire the override section and its draft model |
| 2 G3 | 5b65a9db | refactor(repository): retire the completePendingRequest path |
| 2 G4 | f98f5682 | refactor(graphql): retire the completion form document |
| 3 | (this docs commit) | docs(phase-21): record plan 17 progress |

## Task 1 — RED pins

- Count pins → `schemaCheckDocuments.length, 54)` in `test/tool/schema_check_documents_test.dart` («the registry lists 54 documents and no completion form document (D-25)»), `travel_documents_test.dart`, `shop_documents_test.dart`, `loot_fragment_test.dart` (one each).
- `pending_request_documents_test.dart`: the old document group is replaced by «the completion form document is gone (D-25)»; its import of the mutations file is removed. The removed name is built from two adjacent literals (the formatter puts them on two lines).
- RED run `flutter test test/tool test/graphql`: `+202 -5`, failing exactly the 5 new pins (4 count pins see 55, the key is still present). Nothing else failed.

## Task 2 — four deletion groups

| Group | Commit | `git show --stat` | Targeted run |
|-------|--------|-------------------|--------------|
| G1 screen + Cubit | 7b229d24 | 7 files changed, 1284 deletions(-) | `flutter test test/screens/innkeeper` +325 green |
| G2 section, recap, draft | 2dac3a9f | 6 files changed, 2 insertions(+), 917 deletions(-) | `flutter test test/screens/innkeeper test/models/request` +346 green |
| G3 input + service/repo | 5b65a9db | 7 files changed, 2 insertions(+), 269 deletions(-) | `flutter test test/repository test/models` +1973 green |
| G4 document + registry | f98f5682 | 3 files changed, 3 insertions(+), 18 deletions(-) | `flutter test test/tool test/graphql` +207 green (Task 1 pins green) |

Analyzer after every group: `47 issues found.` + `ANALYZE_GATE_OK`. Edited files formatter-clean before and after.

- `completion_recap.dart` keeps `unnamedItemLabel`, `unnamedSpellLabel` (used by `recap_step.dart` / `prizes_step.dart`), `resultRecapLinesOf`, `recapNameOf`; the doc of the fallback names now says «riepiloghi e passi della missione guidata».
- `completion_recap_test.dart` keeps the `resultRecapLinesOf` and `recapNameOf` groups only (the draft helper and three now-unused imports removed).
- `InjuryChips`, `QuantityStepper`, `completion_exit.dart` untouched (used by the wizard).
- Plan Task 2 `<verify>`: combined run `test/screens/innkeeper test/graphql test/tool test/repository test/models` +2486 green; the name grep prints nothing; the three `test ! -e` checks pass; `grep -c resultRecapLinesOf completion_recap.dart` = 1 → `VERIFY_OK`. The wider grep of action step 5 (incl. `ParticipantOverride\b`, `participant_override`, `request_completion`) also prints nothing.

### Schema check (merged SDL, BE origin/develop `f82ab278`)

```
dumped 54 documents
OK AbandonQuest.graphql, OK AcceptQuest.graphql, OK AcknowledgeQuestResult.graphql, OK CompleteGuidedMission.graphql,
OK CreateCharacter.graphql, OK DeleteCharacter.graphql, OK DiscardMissionDraft.graphql, OK EquipPet.graphql,
OK EquipSpell.graphql, OK ExchangeLoginTicket.graphql, OK GenerateQuests.graphql, OK GetCity.graphql, OK GetCityShop.graphql,
OK GetMe.graphql, OK GetMissionDraft.graphql, OK GetMissionPrizeOptions.graphql, OK GetPendingRequests.graphql,
OK GetQuestResult.graphql, OK GetQuestTravelPreview.graphql, OK GetRaceTraits.graphql, OK GetServerTime.graphql,
OK GetTravelPreview.graphql, OK ListMissionEnemies.graphql, OK ListPointsOfInterest.graphql,
OK ListUnacknowledgedQuestResults.graphql, OK Logout.graphql, OK OnPendingRequestsUpdated.graphql,
OK OnQuestResultReceived.graphql, OK OnQuestUpdated.graphql, OK OnUserChanged.graphql, OK RefreshSession.graphql,
OK RegisterPushDevice.graphql, OK SaveMissionDraft.graphql, OK SimulateMissionFight.graphql, OK StartMissionDraft.graphql,
OK StartTravel.graphql, OK TeleportCharacter.graphql, OK UnequipPet.graphql, OK UnequipSpell.graphql,
OK UnregisterPushDevice.graphql, OK UseItem.graphql, OK character.graphql, OK characterUpdated.graphql, OK cities.graphql,
OK doTransaction.graphql, OK equipItem.graphql, OK equipment.graphql, OK equipmentItems.graphql,
OK equipmentItemsByIds.graphql, OK lootItems.graphql, OK lootItemsByIds.graphql, OK lore.graphql, OK lores.graphql,
OK quests.graphql
```

54 lines OK, no FAIL, exit 0 (one line per document in the real output; joined here).

## Task 3 — phase gate

1. Full suite (alone, foreground): `01:41 +4678: All tests passed!` (baseline 4339 before the phase; no `[E]`).
2. Analyzer: `47 issues found. (ran in 5.9s)` → `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error).
3. Format loop over the 173 `.dart` files added/modified since `6f685817` in lib/test/tool: nothing printed.
4. Trailers `git log 6f685817..HEAD --format=%B | grep -ciE …` = `0`; subjects > 72: none.
5. Product greps: `appLog(` in missionCompletion / models/mission / equipment_repository: nothing; mainScreen diff with `AppBar|AlertDialog|CircularProgressIndicator|KGLoader`: nothing; lock derived from lanes: nothing; `map_utils.dart` diff stat: empty.
6. `bash tool/hardening_check.sh` → `hardening_check: OK`.
7. `21-VALIDATION.md`: `nyquist_compliant: true`, `wave_0_complete: true`, six sign-off boxes ticked, gate line added, rows 21-17-01..03 `✅ green`; Approval: automated gate passed, device E2E pending (21-18).
8. ROADMAP row `17/18 | In Progress`, `- [x] 21-17-PLAN.md`; STATE `Plan: 17 of 18`, Resume file 21-18-PLAN.md. `requirements mark-complete` not run (21-18 only).

## Deviations from Plan

**1. [Rule 2 - Boy Scout] Doc comment of `completeGuidedMission` in `lib/graphql/mutations/mission_mutations.dart`**
- Found during: Task 2 G4 (step 5 grep).
- Issue: the comment compared the new mutation to the retired one by name; the gate grep must find nothing in `lib`.
- Fix: «restituisce gli esiti creati, uno per partecipante.» (file outside `files_modified`, committed in G4: 3 files).

**2. [Boy Scout] `InnkeeperRepository.readCharacter` doc** said «form e teletrasporto»; now «partecipanti della missione guidata e teletrasporto» (G3).

**3. [Note] `graphql_pending_requests_test.dart`** also lost its now-unused `quest_result_fixtures.dart` import (G3).

No group needed a file from a later group; all groups ≤ 8 files.

## Known Stubs

None.

## Notes for 21-18

- The branch needs a BE with Phase 22 (`f82ab278` or later): the fragments select the Phase 22 fields and the only completion path is `completeGuidedMission`.
- The BE may now remove `completePendingRequest` (D-25): no FE document references it.

## Self-Check: PASSED

- Deleted files absent (`test ! -e` checks passed); kept files present (`completion_recap.dart`, `schema_check_documents.dart`).
- Commits a0a9b7d6, 7b229d24, 2dac3a9f, 5b65a9db, f98f5682 present in `git log`.
