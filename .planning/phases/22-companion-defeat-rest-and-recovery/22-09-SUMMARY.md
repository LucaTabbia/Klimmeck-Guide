---
phase: 22-companion-defeat-rest-and-recovery
plan: 09
subsystem: journal
tags: [companion, potion, refusals, pet-defeated, pet-potion-recovering, single-flight, d-02, d-05, d-06, d-07, d-23, d-32]
requires: ["22-01 OwnedPet served state", "22-02 companionDisplayNameOf (callers pass it as targetName)"]
provides: ["shared petDefeatedCode", "ItemUseFailure.petDefeated / petPotionRecovering", "PetEquipFailure.defeated", "companion potion notice «Pozione non data»", "useItem(itemId, {petId}) on service and repository", "PotionCubit.give", "potion states carrying the target"]
affects: ["22-10 potion sheet (calls PotionCubit.give)", "22-16 gate (UseItem document gains $petId)"]
tech-stack:
  added: []
  patterns: ["one private _use body behind drink and give (one single-flight guard)"]
key-files:
  created:
    - lib/repository/pet_defeated.dart
  modified:
    - lib/repository/item_use_failure.dart
    - test/repository/item_use_failure_test.dart
    - lib/repository/pet_equip_failure.dart
    - test/repository/pet_equip_failure_test.dart
    - lib/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart
    - test/screens/mainScreen/tabs/journal/companionCubit/companion_notice_test.dart
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart
    - test/screens/mainScreen/tabs/journal/potionCubit/potion_notice_test.dart
    - lib/repository/services/graphql/graphql.dart
    - test/repository/services/graphql/graphql_use_item_test.dart
    - lib/repository/item_use_repository.dart
    - test/repository/item_use_repository_test.dart
    - test/graphql/use_item_document_test.dart
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_state.dart
    - test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart
    - lib/screens/mainScreen/components/potion_outcome_listener.dart
    - test/screens/mainScreen/components/potion_outcome_listener_test.dart
decisions:
  - "Without a targetName, petDefeated and petPotionRecovering fall to the generic line under «Pozione non bevuta»; with one, every non-companion arm keeps its line under «Pozione non data»"
  - "potionNoticeFor stays ONE exhaustive switch (compiler catches a future enum value)"
  - "itemUseExceptionFrom reads recoveryUntil for the set {potionRecovering, petPotionRecovering}"
  - "petDefeated joins the listener's silent-reread set and still shows its banner"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 22 Plan 09: Companion potion plumbing Summary

The companion potion now exists end to end on mocks: `PET_DEFEATED` (one shared constant) and `PET_POTION_RECOVERING` (with the served `recoveryUntil`) are classified on `useItem` and `equipPet`, the banners name the companion under «Pozione non data», `useItem` carries an optional `petId` that travels only when given, and `PotionCubit.give` shares the single-flight of `drink`. The `UseItem` document is unchanged (Pitfall 2), so nothing changes against today's BE.

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 Classifiers and copy | e3dc1a79 (RED), d44d101b (GREEN) | `petDefeatedCode`, `petPotionRecoveringCode`, `ItemUseFailure.petDefeated/petPotionRecovering`, `PetEquipFailure.defeated`, equip line «È ancora sconfitto: aspetta che torni in forze», `companionPotionNoticeTitle`, `potionNoticeFor(..., targetName:)` |
| 2 Target and give | 2c03a46d (RED), 7237a4f2 (GREEN) | `KlimmeckGraphQl.useItem(itemId, {petId})`, `ItemUseRepository.useItem(itemId, {petId})`, `PotionCubit.give(itemId, petId:, targetName:)`, states with `targetPetId`/`targetName`, listener passes `targetName`, `petDefeated` rereads |
| 3 Bookkeeping | this commit | ROADMAP 9/17, STATE `Plan: 9 of 17`, VALIDATION 22-09-01..03 green |

## RED failures

- Task 1: compile errors — `Member not found: 'petDefeated'` / `'petPotionRecovering'` (item_use_failure_test), `'defeated'` (pet_equip_failure_test, companion_notice_test), `No named parameter with the name 'targetName'` (potion_notice_test).
- Task 2: compile errors — `No named parameter with the name 'petId'` (graphql_use_item_test, item_use_repository_test), `The method 'give' isn't defined`, `No named parameter with the name 'targetPetId'` (potion_cubit_test, potion_outcome_listener_test).

### Green at first run (by design)

- «UseItem does not declare petId before the gate (Pitfall 2)» — the document is intentionally unchanged; the pin guards it until 22-16.
- «ITEM_NO_EFFECT stays noEffect for a companion (D-32)» — existing mapping, pinned for the companion path (its file failed to compile in RED for the other cases).
- «without a target the character copy is unchanged» noEffect half — existing copy; the petDefeated/petPotionRecovering half was RED.

## Extra switch sites

`grep -rn "ItemUseFailure\.\|PetEquipFailure\." lib`: no other exhaustive switch on either enum (only throws in repositories/cubits and the two listeners' stale sets). Nothing else to extend.

## Tests

+20 tests: item_use_failure +4, pet_equip_failure +1, companion_notice +1, potion_notice +5, graphql_use_item +1, use_item_document +1, item_use_repository +1, potion_cubit +4, potion_outcome_listener +2. Expected suite 4870 (full suite not run).
- `flutter test test/repository test/screens/mainScreen/tabs/journal test/screens/mainScreen/components` +1422 green.
- `flutter test test/repository test/graphql test/screens/mainScreen` +2506 green.
- Analyzer 47 info, ANALYZE_GATE_OK after each code task. All touched files formatter-clean before and after. Registry 54.

## Deviations from Plan

- The plan mentions a `_coded(code, {extensions})` helper in each test file; it does not exist — the existing helpers (`_withExtensions` / `_shapes`, `_withCode`) were reused.
- STATE reads `Plan: 9 of 17` (orchestrator format), so the plan's `grep -q "Plan: 09 of 17"` (Task 3 verify, VALIDATION 22-09-03 command) does not match — expected, as in plans 01..08. Progress row `9/17 | In Progress`.

Otherwise the plan executed as written.

## Threat model

T-22-26 (document untouched, pinned), T-22-28 (one guard for drink and give, tested), T-22-29 (every new code has a banner line; petDefeated also rereads) mitigated. T-22-27 transferred to the BE. No new surface.

## Self-Check: PASSED

- lib/repository/pet_defeated.dart exists; commits e3dc1a79, d44d101b, 2c03a46d, 7237a4f2 in `git log`.
