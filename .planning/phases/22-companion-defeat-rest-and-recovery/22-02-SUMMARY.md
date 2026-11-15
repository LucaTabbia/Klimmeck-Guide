---
phase: 22-companion-defeat-rest-and-recovery
plan: 02
subsystem: models
tags: [companion, vitality, display-name, name-rules, copy]
requires: [22-01]
provides:
  - "companionVitalityOf / companionPotionWaitOf and the sealed CompanionVitality (Steady, Resting, Defeated)"
  - "companionDisplayName / companionDisplayNameOf"
  - "lib/utils/name_rules.dart (NameError, nameMinLength, nameMaxLength, normalizedNameOf, nameErrorOf, NameErrorMessage)"
  - "lib/utils/companion_lines.dart (every companion line and label)"
affects: [22-03, 22-04, 22-05, 22-06, 22-07, 22-08, 22-09]
tech-stack:
  added: []
  patterns: ["pure sealed status derived from served dates (shape of spell_recovery_status.dart)", "re-export `show` to move a symbol without touching importers"]
key-files:
  created:
    - lib/models/companion/companion_vitality.dart
    - lib/models/companion/companion_display_name.dart
    - lib/utils/name_rules.dart
    - lib/utils/companion_lines.dart
    - test/models/companion/companion_vitality_test.dart
    - test/models/companion/companion_display_name_test.dart
    - test/utils/name_rules_test.dart
    - test/utils/companion_lines_test.dart
  modified:
    - lib/screens/characterCreation/cubit/character_draft.dart
    - lib/screens/characterCreation/components/character_creation_messages.dart
key-decisions:
  - "Vitality rounds to the nearest point (round(), as the BE anchor D-24) and is capped at max − 1 while now < fullLifeAt (Pitfall 8): the user's example reads 40"
  - "A clock before lifeAsOf reads the served life (share clamped to 0); fullLifeAt not after lifeAsOf reads share 1.0 (one short of full until fullLifeAt)"
  - "NameError and NameErrorMessage moved to lib/utils/name_rules.dart; character_draft.dart and character_creation_messages.dart re-export them with `export … show`"
requirements-completed: []
duration: ~15min
completed: 2026-11-14
---

# Phase 22 Plan 02: Pure companion rules Summary

The live companion life is now a pure rule (`companionVitalityOf`) that reads only the served dates and `isDefeated`, never `recoveryTime` (rule 4). `companionDisplayNameOf` gives one display name for every wording. The character-name form rules moved to `lib/utils/name_rules.dart` with no change in behaviour, and every Italian companion line lives in `lib/utils/companion_lines.dart`.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | fb4ce776 | test(models): expect the companion vitality and display name |
| 1 GREEN | e3e3af93 | feat(models): derive companion vitality from served dates |
| 2 RED | 7f82740e | test(utils): expect shared name rules and companion lines |
| 2 GREEN | 1f50c9cb | refactor(utils): share the name rules and add companion lines |

## RED failures (expected)

- Task 1: `Error when reading 'lib/models/companion/companion_display_name.dart'` / `companion_vitality.dart`: the files did not exist (compilation failure, 0 tests run).
- Task 2: `Error when reading 'lib/utils/name_rules.dart'` / `lib/utils/companion_lines.dart`: the files did not exist.

No case was green at its first run: every test file failed to compile until GREEN.

## Rule details

- Rounding: `currentLifePoints + ((max − currentLifePoints) × share).round()`, then capped at `max − 1` and never below `currentLifePoints`. The user's example (20 → 100, `fullLifeAt = lifeAsOf + 4848485 ms`, 20 min later) gives 80 × 0.2475 = 19.8 → 20 → **40**. One second before `fullLifeAt` it reads 99, not 100. With `floor` (the research proposal) it would read 39.
- At or after `fullLifeAt`: `CompanionSteady(life: max)`, even when served as defeated (D-02, D-24).
- Equipped, no max, or no dates: `CompanionSteady(life: currentLifePoints)` (D-04, D-24).
- `companionPotionWaitOf`: `potionRecoveryUntil − now`, null when it has passed or is absent (D-05).

## Tests

- `flutter test test/models/companion`: +15, all passed (11 vitality/potion wait, 4 display name).
- `flutter test test/utils test/screens/characterCreation`: +296, all passed (13 new: 3 name rules, 10 companion lines). The character-creation tests were not touched (`git diff --stat HEAD~1 -- test/screens/characterCreation` is empty).
- New tests: +28. Expected suite total: 4733 + 28 = **4761** (the full suite was not run).
- Analyzer: 47 issues (info only), `ANALYZE_GATE_OK` after both code tasks.

## Deviations from Plan

- [Rule 2 - T-22-07] Added a test for dates in the wrong order (`fullLifeAt` before `lifeAsOf`): share 1.0, reads 99 and does not crash. It is the mitigation the threat register asks for.
- `companion_lines.dart` and `name_rules.dart` have a library doc comment (`library;`) instead of a dangling comment over the first declaration.
- `CharacterDraft.nameError` is typed `name_rules.NameError?` because the library is imported with a prefix (as the plan says). The re-export keeps `NameError` visible to every importer.
- Bookkeeping uses the orchestrator's format: `Plan: 2 of 17` and the Progress row `2/17 | In Progress`. The plan's literal grep for `Plan: 02 of 17` (Task 3 verify, VALIDATION 22-02-03) does not match. This is expected and was the same in 22-01.
- The Wave-0 checkboxes for the four test files in 22-VALIDATION.md are ticked.

## Known Stubs

None. The rules are not consumed yet; later plans (Journal cubit, sheets) wire them.

## Self-Check: PASSED

- All 8 created files exist; commits fb4ce776, e3e3af93, 7f82740e, 1f50c9cb are in `git log`.
