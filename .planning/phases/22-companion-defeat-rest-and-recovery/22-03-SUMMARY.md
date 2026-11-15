---
phase: 22-companion-defeat-rest-and-recovery
plan: 03
subsystem: journal
tags: [companion, level, vitality, ticker, graphql, pet-fragment]
requires: [22-02]
provides:
  - "PET-10 in REQUIREMENTS (section, traceability, coverage 32/32) and in the ROADMAP Requirements line"
  - "OwnedPet.level, OwnedPet.ownMaxLifePoints, OwnedPet.effectiveMaxLifePoints (D-37, D-38)"
  - "companionVitalityOf interpolates to effectiveMaxLifePoints"
  - "companionLevelLine / companionSpeciesLevelLine"
  - "PetFragment selects imagePath and maxLifePoints (today's SDL)"
  - "CompanionVitalityCubit + CompanionVitalityState + CompanionVitalityScope; Journal wrapped; MockCompanionVitalityCubit"
affects: [22-04, 22-05, 22-06, 22-09, 22-10, 22-16]
tech-stack:
  added: []
  patterns: ["Journal-scoped ticker on the shape of SpellRecoveryCubit", "scope widget = BlocProvider + BlocListener following the character"]
key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart
    - lib/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_state.dart
    - lib/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_scope.dart
    - test/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_scope_test.dart
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - lib/models/owned_pet.dart
    - lib/models/companion/companion_vitality.dart
    - lib/utils/companion_lines.dart
    - lib/graphql/fragments/pet_fragment.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - test/helpers/mocks.dart
    - test/helpers/fixtures/shop_fixtures.dart
    - test/models/owned_pet_test.dart
    - test/models/companion/companion_vitality_test.dart
    - test/utils/companion_lines_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/character_fragment_test.dart
key-decisions:
  - "The owned max is `ownMaxLifePoints` (wire key `maxLifePoints` on OwnedPet); `level` reads `num >= 1`, the own max `num > 0`; both unselected until the gate plan (Pitfall 1)"
  - "imagePath now selected: Phase 13 D-13 amended by D-34 (already served as `Pet.imagePath: String!`)"
  - "One cubit for every owned companion, tick 1 s; the timer lives while any vitality is not CompanionSteady or a potion wait is pending"
  - "Journal.build returns `CompanionVitalityScope(child: _buildPage(context))` (old body moved to `_buildPage`, no re-indent)"
requirements-completed: []
duration: ~25min
completed: 2026-11-14
---

# Phase 22 Plan 03: Companion levels, live-safe pet fields and the vitality ticker Summary

PET-10 is written; `OwnedPet` reads the companion's level and its own max life leniently and exposes ONE getter, `effectiveMaxLifePoints` (own max, else species max), which now feeds `companionVitalityOf`. `PetFragment` selects `imagePath` and `maxLifePoints`, both in today's SDL (`recoveryTime`, `level` and the owned `maxLifePoints` stay unselected). The Journal provides a `CompanionVitalityCubit` through `CompanionVitalityScope`, which follows the character's owned companions and the equipped pet id silently and ticks on `ServerClockService.now()` only while a companion rests, is defeated or waits for a potion.

## Live-safe proof (run before Task 1)

```
$ awk '/^type Pet /,/^}/' "$S" | grep -E '^ +(maxLifePoints: Int!|imagePath: String!)$' | wc -l
       2
```

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | PET-10 in REQUIREMENTS and ROADMAP | 7c16db05 |
| 2 | Level, own max, one getter, vitality, level lines, PetFragment fields | e474238a (RED), e07210f7 (GREEN) |
| 3 | CompanionVitalityCubit, state, scope, Journal provider, mock | 65868ce2 (RED), 5c8e771f (GREEN) |
| 4 | Bookkeeping | this commit |

## RED failures

- Task 2: compilation failures — `The getter 'level' / 'ownMaxLifePoints' / 'effectiveMaxLifePoints' isn't defined for the type 'OwnedPet'`, `No named parameter with the name 'ownMaxLifePoints'`, `Method not found: 'companionLevelLine' / 'companionSpeciesLevelLine'`; document pins: `PetFragment selects id, name, imagePath, …` (differ at offset 8), `GetCityShop selects pets … with maxLifePoints and imagePath`, `ownedPets and the equipped pet carry maxLifePoints and imagePath` (`does not contain 'maxLifePoints'`).
- Task 3: compilation failure — `Error when reading 'lib/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart': No such file or directory`.

## Tests

- +10 in Task 2 (owned_pet 5, companion_vitality 2, companion_lines 2, character_fragment 1; shop_documents 2 retargeted, not added), +11 in Task 3 (cubit 10, scope 1) → expected suite total **4782** (full suite not run).
- `flutter test test/graphql test/models test/utils` green (+1459); `flutter test test/screens/mainScreen test/graphql test/models test/utils` green (+2760); `flutter test test/screens/mainScreen/tabs/journal` green (+263).
- Green at the first run in GREEN: none were green in RED. Extra cases beyond the plan: «a defeated companion keeps the timer alive (D-02, D-09)», «starts empty and reads an unknown id as null», own max `0` read as null, props case for level/own max.
- Analyzer 47 info / 0 warning / 0 error, `ANALYZE_GATE_OK`. Registry untouched (54). All touched files were formatter-clean and remain so.

## Deviations from Plan

1. **[Rule 1 - Test] Scope test settles after each character.** The RED scope test pumped once after each character emission; the third step (equipped) needs the CharacterCubit stream event and the cubit's own stream event to both be delivered, so the GREEN commit changed both `tester.pump()` to `tester.pumpAndSettle()` (no assertion changed). Commit 5c8e771f.
2. **Journal wiring by method extraction.** Instead of re-indenting the 75-line body, `build` now returns `CompanionVitalityScope(child: _buildPage(context))` and the old body is `_buildPage`; `grep -c CompanionVitalityScope journal.dart` = 1.
3. **Character-fragment pin** splits `assetsFields` on `' pet { '` (equipped pet) and `'ownedPets {'` so each half is checked separately.
4. STATE `Plan: 3 of 17` / Progress `3/17 | In Progress` in the orchestrator's format (the VALIDATION 22-03-04 command already uses `Plan: 3 of 17`). Wave-0 checkboxes of 22-03-02/03 ticked; 22-03-03 «File Exists» `❌ W0` → `✅`.

## Known Stubs

None: nothing reads `CompanionVitalityCubit` yet by design (plans 22-06, 22-10); `level` and the owned `maxLifePoints` are modelled but unselected until 22-16 (Pitfall 1).

## Threat surface

T-22-09 mitigated (block-anchored proof printed 2; `recoveryTime` absent from `pet_fragment.dart`). T-22-10 mitigated (tests «the ticker stops when nothing rests and nothing waits», «close cancels the timer and the offset listener»). No new surface.
