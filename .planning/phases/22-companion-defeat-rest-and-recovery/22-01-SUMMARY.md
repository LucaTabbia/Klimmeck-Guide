---
phase: 22-companion-defeat-rest-and-recovery
plan: 01
subsystem: models
tags: [pet, owned-pet, companion, requirements, lenient-parsing]
requires: []
provides:
  - "OwnedPet.name / isDefeated / lifeAsOf / fullLifeAt / potionRecoveryUntil (lenient, unselected)"
  - "Pet.recoveryTime (int? ms) and Pet.recoveryDuration (Duration?)"
  - "CharacterAssets.equippedOwnedPet"
  - "petJson(maxLifePoints, recoveryTime, imagePath) and ownedPetJson(name, defeated, lifeAsOf, fullLifeAt, potionRecoveryUntil) fixtures"
  - "PET-01..PET-09 in REQUIREMENTS and ROADMAP"
affects: [22-02, 22-03, 22-05, 22-06, 22-09, 22-16]
tech-stack:
  added: []
  patterns: ["lenient wire reads: `== true`, `DateTime.tryParse(String)?.toUtc()`, `num > 0`"]
key-files:
  created: []
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - lib/models/owned_pet.dart
    - lib/models/pet.dart
    - lib/models/character/character_assets.dart
    - test/models/owned_pet_test.dart
    - test/models/pet_test.dart
    - test/models/character/character_assets_test.dart
    - test/helpers/fixtures/shop_fixtures.dart
key-decisions:
  - "Boolean field named isDefeated, read from the wire key `defeated` (naming.md modal prefix)"
  - "Dates parsed only from a String, in UTC; blank name reads null and is trimmed"
  - "recoveryTime keeps the wire unit (ms); zero/negative/non-num reads null; no OwnedPet.id (D-23)"
requirements-completed: []
duration: ~15min
completed: 2026-11-14
---

# Phase 22 Plan 01: Requirements and companion models Summary

PET-01..PET-09 written into REQUIREMENTS and the ROADMAP (17-plan list, Success Criteria, Progress row), and the BE Phase 23 companion state is now modelled on `OwnedPet` (name, defeated, three UTC dates) and `Pet` (`recoveryTime` in ms) with lenient reads. `CharacterAssets.equippedOwnedPet` resolves the owned entry of the equipped species. None of these fields is selected by any GraphQL document yet.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | PET requirements and the ROADMAP §Phase 22 | c1e56bec |
| 2 RED | Fixtures and titled tests | dcdb4151 |
| 2 GREEN | Lenient companion state, recovery time, equipped owned entry | c96e42af |
| 3 | Bookkeeping | (this commit) |

## TDD

- **RED (dcdb4151):** compile errors: `The getter 'recoveryDuration' isn't defined for the type 'Pet'`, `The getter 'equippedOwnedPet' isn't defined for the type 'CharacterAssets'`, and the missing `OwnedPet` getters (`name`, `isDefeated`, `lifeAsOf`, …). All three test files failed to load.
- **GREEN (c96e42af):** `flutter test test/models/owned_pet_test.dart test/models/pet_test.dart test/models/character/character_assets_test.dart` showed +59, all passed. The wider set `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop` showed +1351, all passed.
- No case was green at the first run: the RED was a compile failure, so every case failed.
- 11 new tests (owned_pet 6, pet 3, character_assets 2). The suite should now count 4722 + 11 = 4733 (the full suite was not run, as the repo rules require).

## Verification

- Analyzer: `47 issues found.`, then `ANALYZE_GATE_OK` (baseline unchanged: 47 info / 0 warning / 0 error).
- Formatter: all 7 touched code and test files were formatter-clean before the edit. Each one was formatted on its own afterwards, with 0 changes.
- `grep -rn "lifeAsOf\|fullLifeAt" lib/graphql` printed nothing. `recoveryTime` appears in `pet_fragment.dart` 0 times (Pitfall 1, T-22-01). The registry was not touched (54).
- `La vita non si mostra` was replaced by the C-10 sentence.

## Deviations from Plan

1. **Bookkeeping numbering (orchestrator over plan):** STATE reads `Plan: 1 of 17` and the Progress row reads `1/17`, as the orchestrator asked. The plan's own Task 3 verify (`grep -q "Plan: 01 of 17"`) and the VALIDATION row 22-01-03 command therefore do not match literally. The orchestrator's k/N wins (REPO-RULES).
2. **Extra malformed case:** the test «absent or malformed new fields keep the entry» also checks `potionRecoveryUntil: true` → null, so every new field has a malformed case. This only adds coverage.
3. **Wave-0 checklist:** the `shop_fixtures.dart` line in 22-VALIDATION.md is ticked `[x]`.

Otherwise the plan was executed as written.

## Known Stubs

None. The new fields are intentionally unselected until gate plan 22-16 (Pitfall 1).

## Self-Check: PASSED

- Files exist: lib/models/owned_pet.dart, lib/models/pet.dart, lib/models/character/character_assets.dart, test files, fixtures.
- Commits exist: c1e56bec, dcdb4151, c96e42af.
