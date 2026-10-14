---
phase: 02-character-creation
plan: 03
subsystem: character-creation
tags: [models, validation, draft, tdd]
requires: []
provides:
  - RaceTraits model (race, minAge, maxAge) with allows(age) and tolerant tryFromJson
  - CreateCharacterRequest.toJson for the CreateCharacterInput variable
  - SexType.label (Maschio/Femmina)
  - CharacterDraft pure validation (NameError, AgeError, isCompleteFor, toRequest)
  - test fixture testRaceTraits / raceTraitsJson mirroring the D-10 lore table
affects: [02-04, 02-09]
key-files:
  created:
    - lib/models/character/race_traits.dart
    - lib/models/request/create_character_request.dart
    - lib/screens/characterCreation/cubit/character_draft.dart
    - test/models/character/race_traits_test.dart
    - test/models/request/create_character_request_test.dart
    - test/models/enums/sex_type_test.dart
    - test/screens/characterCreation/cubit/character_draft_test.dart
    - test/helpers/fixtures/race_traits_fixture.dart
  modified:
    - lib/models/enums/sex_type.dart
key-decisions:
  - "Client validation is UX only (D-23); name length counts UTF-16 units of the normalized name, background of trim() (D-32)"
  - "ageErrorFor(null) returns null: age field stays disabled until a race with known traits exists (D-10)"
  - "No race/age table in lib/ (D-11); only the test fixture mirrors it"
  - "RaceTraits.tryFromJson uses a deliberate broad catch at the parse boundary so unknown races from a newer backend are skipped"
requirements-completed: []  # CHAR-02/03/04 close with the screen plans, not this domain-only plan
duration: 20min
completed: 2026-10-09
---

# Phase 2 Plan 03: Creation models and draft validation Summary

Flutter-free domain core of character creation: `RaceTraits`, `CreateCharacterRequest`, `SexType.label` and a pure `CharacterDraft` deciding deterministically whether "Crea" is enabled.

## Commits
- 7a9ef87 test(character-creation): add failing tests for the creation models
- 44c7f0e feat(character-creation): add race traits, the create-character request and the sex label
- b8a417f test(character-creation): add failing tests for the character draft rules
- 339cd07 feat(character-creation): add the character draft validation rules

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Typo `SextTypeExtension` renamed to `SexTypeExtension`**
- Planned Boy Scout rename; grep confirmed no other references.
- Commit: 44c7f0e

Otherwise the plan was executed as written.

## Verification
- `flutter test`: 328 passed (298 baseline + 30 new)
- `flutter analyze lib test`: 12 issues (unchanged baseline)
- Format check clean on touched files only; no `package:flutter` import in the new lib files; no `9999` in `lib/`

## Known Stubs
None.

## Self-Check: PASSED
