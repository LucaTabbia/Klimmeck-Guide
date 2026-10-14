---
phase: 03-real-time-sync-foundation
plan: 09
status: complete
subsystem: cross-repo-verification
tags: [schema-check, validation, uat, checkpoint]
requires: [03-01, 03-02, 03-03, 03-04, 03-05, 03-06, 03-07, 03-08]
key-files:
  modified:
    - .planning/phases/03-real-time-sync-foundation/BACKEND-NOTES.md
    - .planning/phases/03-real-time-sync-foundation/03-VALIDATION.md
  created:
    - .planning/phases/03-real-time-sync-foundation/03-HUMAN-UAT.md
completed: 2026-10-14
---

# Phase 3 Plan 09: Cross-repo gate and E2E Summary

Task 1 done: all 24 app GraphQL documents validate against the regenerated BE schema, phase gates green, validation signed off, UAT checklist ready. Task 2 (human E2E) approved by the user on a physical Android device.

## Task 1: Schema check, gates, sign-off (done)

**Backend gate (D-04):** `userUpdated: User!` found at `src/schema.gql:491`. BE branch `feat/03-autorizzazione-ownership-ruoli-audit`, HEAD `62890b6 docs(phase-3): update validation strategy after Nyquist audit` (read-only).

**Schema check output (validate_documents.js, 24 documents, all OK; baseline plan 01 was 23 OK + OnUserChanged):**

```
OK CreateCharacter.graphql
OK ExchangeLoginTicket.graphql
OK GetMe.graphql
OK GetRaceTraits.graphql
OK Logout.graphql
OK OnUserChanged.graphql
OK RefreshSession.graphql
OK character.graphql
OK characterUpdated.graphql
OK cities.graphql
OK doTransaction.graphql
OK equipItem.graphql
OK equipSpell.graphql
OK equipment.graphql
OK equipmentAssetsQuantity.graphql
OK equipmentItems.graphql
OK equipmentItemsByIds.graphql
OK lootAssetsQuantity.graphql
OK lootItems.graphql
OK lootItemsByIds.graphql
OK lore.graphql
OK lores.graphql
OK quests.graphql
OK unequipSpell.graphql
```

`OnUserChanged`, `characterUpdated`, `character`, `GetMe`: OK. No fix needed, no pre-existing drift, no new failure.

**Phase gates:**

| Gate | Result |
|------|--------|
| `flutter test` | 639 tests passed (baseline after plan 08: 639), exit 0 |
| `flutter analyze` | 57 issues (limit 57), none located in the 57 Phase 3 Dart files |
| `dart format --output=none --set-exit-if-changed` on `git diff --name-only develop...HEAD -- '*.dart'` (base: local `develop`, 57 files, includes `lib/main.dart` because plan 08 states it was formatter-clean) | `Formatted 57 files (0 changed)` |
| `grep -rn "activeTravel\|activeStoryQuest\|activeWorldMissionQuest" lib` | empty |
| `grep -rn "showSessionExpiredNotice" lib test` | empty |
| `git log develop..HEAD --format=%B \| grep -c "Co-Authored-By"` | 0 |

**Docs updated:** 03-VALIDATION.md signed (`status: approved`, `nyquist_compliant: true`, `wave_0_complete: true`; row 3-09-02 stays pending until the E2E); BACKEND-NOTES.md header Stato, §2 point 5 (clarified D-15 wording) and §5 (schema result); 03-HUMAN-UAT.md created (12 entries, `status: partial`).

**Commit:** see git log (`docs(phase-3): verify the schema and sign off the validation`).

## Task 2: Manual E2E (done)

Resume signal (verbatim):

```
approved
```

Steps 1-11 pass; step 12 (optional physical iOS) skipped, no iOS device reported. Full results in `03-HUMAN-UAT.md` (`status: complete`, 12 results recorded).

**Session context:** Samsung SM S938B, Android 16 (API 36), physical, USB with `adb reverse tcp:3000 tcp:3000`; real Twitch login (`DEV_AUTH_ENABLED=false`); BE branch `feat/03-autorizzazione-ownership-ruoli-audit` at `62890b6`, local on :3000; date 2026-10-14. Orchestrator note (flutter logs, step 8): with the BE down the app logged `Disconnected from websocket` and retried with backoff 1, 2, 4, 8, 16, 32 then 60 s, no crash, no UI shown.

**Tests after the E2E:** `flutter test` 639 passed, all green.

**FORBIDDEN form (step 9)** recorded in `BACKEND-NOTES.md` section 5.

## Gaps

None, no `/gsd-plan-phase 3 --gaps` needed.

## For the PR description

- The session-wide watchdog also covers the character creation page (accepted, D-15 Open Question 3).
- FORBIDDEN/NOT_FOUND on `characterUpdated` is terminal, with a single `me` refetch and no resubscribe.
- The FE PR to `develop` must be opened only after the BE PR is merged (D-04), by the user.

## Self-Check: PASSED

Files: `03-HUMAN-UAT.md`, `03-VALIDATION.md`, `BACKEND-NOTES.md`, `03-09-SUMMARY.md` all present. Commits: `d237cf0` (Task 1); the E2E record commit follows this file.
