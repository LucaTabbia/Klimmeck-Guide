---
phase: 06-quest-accept-info-sheets
plan: 12
subsystem: quests / board / cross-repo contract
tags: [graphql, schema-check, device-e2e, uat, quests]
requires: [06-01, 06-02, 06-03, 06-04, 06-05, 06-06, 06-07, 06-08, 06-09, 06-10, 06-11]
provides:
  - quests document on the BE Phase 8 shapes (rank slots, registeredAdventurers, enemy, relatedLore, recommendedLoot)
  - 29/29 documents validated against the merged BE schema
  - Android device E2E 12/12 passed
affects: [07-travel]
key-files:
  modified:
    - lib/graphql/queries/quest_queries.dart
    - test/graphql/board_documents_test.dart
    - .planning/phases/06-quest-accept-info-sheets/06-HUMAN-UAT.md
    - .planning/phases/06-quest-accept-info-sheets/06-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - BE ref evolved from the fallback origin/feat/08-travel-lifecycle-travel-01 @ e9b0768 to origin/develop @ 2a3449a (BE PR #11 merged, schema identical)
  - Acceptance call gets a 15 s client timeout mapped to a connection failure
metrics:
  tests: 1336 green
  analyze: 54 issues, 0 errors
  completed: 2026-10-22
---

# Phase 6 Plan 12: Phase 8 document flip, schema check and device E2E Summary

The `quests` document now selects the BE Phase 8 catalogue shapes, every FE document validates against the merged BE schema (29/29), and the user ran the 12-step Android E2E against the real BE: all 12 steps passed, so QUEST-01..07 are ticked and Phase 6 is closed.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 (RED) | ff4c17a | test(board): expect the BE Phase 8 quest selections |
| 1 (GREEN) | a77fee4 | feat(board): select rank slots, registrations, enemy and lore from the BE Phase 8 catalogue |
| 1 | 44d68a0 | docs(phase-6): validate the documents against the BE Phase 8 schema |
| 2 | 683069f | docs(phase-6): open the device E2E record |
| 2 | d2796ef | docs(phase-6): record the device E2E results |
| 3 | final docs commit | docs(phase-6): record the quest acceptance device E2E |

## BE ref evolution

- Task 1 ran against the approved fallback `origin/feat/08-travel-lifecycle-travel-01` @ e9b0768 (29/29 OK).
- BE PR #11 was merged during the session: `origin/develop` @ 2a3449a carries the Phase 8 SDL (identical to the branch schema). `tool/schema_check` re-run against `origin/develop`: **29/29 OK** (`NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <docs>`).
- Live probe on the running BE: the FE `quests` document answered 13 quests with enemy / lore / items populated.

## Device E2E (2026-10-22)

Samsung SM-S938B, Android 16, real Twitch login, BE develop @ 2a3449a + Redis (docker compose), character "Reavor" (legend, Talmvere, 10000 points). **12/12 steps passed** (user: "Tutto corretto"); per-step evidence in `06-HUMAN-UAT.md`. Requirement ticks follow the passed steps: QUEST-01 (3), QUEST-02 (4, 6), QUEST-03 (4, 5, 7), QUEST-04 (2, 7, 8, 9), QUEST-05 (3, 7), QUEST-06 (10), QUEST-07 (5) - all seven ticked.

## Fixes landed during the UAT (each TDD)

| Id | Fix |
|----|-----|
| DB data | `itemType` set on 83 loot + 145 equipment items (its absence nulled the `quests` list); legend story inserted; test user points 250 to 10000 (no restore) |
| e4211cc (bca71c4 RED) | Loot items without description and prizeItem as AssetQuantity (board was empty: 12/13 quests skipped by the tolerant parser) |
| c663be2 (1eae3bb RED) | effect/power selected for the prize loot; LootItemCard null-safe (crash on the `aid` sheet) |
| quick 261022-f0n | worldMission listed and acceptable only in its own city (user correction of D-11/D-16) |
| quick 261022-qkx | Tear geometry: horizontal tear at 10%, lower piece slides off-screen unclipped, seeded jaggedness (D-06 amended), verified on device |
| 652ed2f (0231cbc RED) | 15 s client timeout on acceptQuest mapped to `connection` failure (the client hung ~100 s when the BE was stuck) |

## Deviations from Plan

- **[Rule 3 - Blocking] BE gate:** Phase 8 was not on `develop` at Task 1; the user approved the fallback ref, later superseded by develop (above).
- **[Rule 1 - Bug] Four defects found only on the device** (data `itemType`, item parsing, prize loot crash, acceptance hang) fixed inline with tests, listed above; two user design corrections (worldMission city rule, tear geometry) landed as quick tasks with the decisions amended in CONTEXT.
- Single non-pass observed mid-session (no auto-navigation after a travel quest): root cause was Redis not running (BE hung on Bull `queue.add` after the commit); with Redis up the step passed. Not an FE defect; FE hardened with the timeout.

## Follow-ups

- **BE:** `TravelScheduler.schedule/cancel` must bound `queue.add`/`remove` with a timeout (Redis down: WARN, travel stays valid, sweep covers; never hang the mutation); surface Redis connection errors in the boot log.
- Notes, not failures: Impeller `SetInheritedOpacity` warnings while the satchel icon is disabled (opacity 0.4); FlutterSecureStorage "bad base-64" fallback on startup (session still restored).
- **FE PR:** open `feat/06-quest-accept-info-sheets` to `develop` (`gh auth switch -u LucaTabbia` first); mention D-20 (C1 banner path, G2 GetCity, A1/D-32), the worldMission city rule and the tear amendment in the description.

## Gates

- `flutter test` (full): 1336 passed, all green
- `flutter analyze`: 54 issues, 0 errors (limit 56 / 0)
- `git log develop..HEAD`: no `Co-Authored-By` trailers
- No known stubs; no new threat surface beyond the plan's threat model (T-06-12-01..05 mitigations held: schema check 29/29, no token printed, ticks only for passed steps).

## Self-Check: PASSED
