---
phase: 22-companion-defeat-rest-and-recovery
plan: 10
subsystem: journal
tags: [companion, potion, potion-sheet, targets, single-flight, pitfall-3, d-05, d-06, d-07, d-08, d-20, d-32, d-38]
requires: ["22-03 CompanionVitalityCubit (Journal-scoped)", "22-02 companionDisplayNameOf, companionLifeLine, giveToCompanionLabel", "22-04 CompanionCard", "22-05 companionCareEnabled", "22-09 PotionCubit.give and targeted states"]
provides: ["CompanionPotionTarget + companionPotionTargetsOf (pure)", "ItemsSection.isCompanionCareEnabled and row gating on targets", "PotionSheet.targets, targetKeyOf, characterWaitKey, companion outcome face"]
affects: ["22-16 gate (flipping companionCareEnabled exposes the targets; UseItem gains $petId)"]
tech-stack:
  added: []
  patterns: ["model takes two lookups instead of a screen state (lib/models never imports a screen)", "sheet receives the shell cubits by value through MultiBlocProvider"]
key-files:
  created:
    - lib/models/companion/companion_potion_target.dart
    - test/models/companion/companion_potion_target_test.dart
  modified:
    - lib/screens/mainScreen/tabs/journal/sections/items_section.dart
    - test/screens/mainScreen/tabs/journal/sections/items_section_test.dart
    - lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart
    - test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart
decisions:
  - "Targets are read once when the sheet opens; the character's countdown inside the sheet is live from PotionRecoveryCubit passed by value"
  - "The outcome face takes title, max and an optional healed line (no boolean flag): the companion face passes no healed line"
  - "The awaiting-aid row stays read-only for companions too (BE AWAITING_AID applies to a companion target)"
metrics:
  duration: ~30 min
  completed: 2026-11-14
---

# Phase 22 Plan 10: Potion sheet with companion targets Summary

The potion sheet can now give a potion to a companion: eligible targets (not defeated, below their own max, equipped or resting, no wait of their own) are derived purely from the served vitality, the Journal potion row stays tappable during the character's wait when one of them can drink, and the sheet lists one «Dai a <nome>» parchment per target with «Vita: x / max», «Bevi» disabled with the character's countdown, and a companion outcome face titled with its name. Everything stays hidden behind `companionCareEnabled` (off), so the app is unchanged against today's BE.

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 Eligible targets and row gating | d79229ea (RED), 1d1b0480 (GREEN) | `companionPotionTargetsOf`; `ItemsSection(isCompanionCareEnabled)` gates on targets; sheet gets targets + recovery cubit by value |
| 2 Targets and outcome face in the sheet | 61a59df4 (RED), d4b3e90a (GREEN) | target parchments (CompanionCard 56 + label + life, ≥ 44 px, `targetKeyOf`), «Bevi» off in the wait with `characterWaitKey`, companion outcome face |
| 3 Bookkeeping | this commit | ROADMAP 10/17, STATE `Plan: 10 of 17`, VALIDATION 22-10-01..03 green |

## RED evidence

- Task 1: compilation failure (no `companion_potion_target.dart`, no `ItemsSection.isCompanionCareEnabled`, no `PotionSheet.targets`).
- Task 2: compilation failure (no `PotionSheet.targetKeyOf` / `characterWaitKey` / `give` wiring); the new harness already provided `PotionRecoveryCubit`.

## Phase 18 row amended (companion case only)

The Phase 18 D-12 pins (row dimmed with «pronta fra …», tap opens nothing) stay green unchanged: they run through the Journal with the switch off. The amendment applies only with the switch on and an eligible companion: the row keeps the «pronta fra …» status line but is not dimmed and opens the sheet. Mission (Phase 21 D-12) and awaiting aid keep their rows.

## Tests

- companion_potion_target_test: 6 new. items_section_test: +5 (new group with a direct `ItemsSection` pump under `CompanionVitalityScope` and a fake clock). potion_sheet_test: +6 (harness now provides a local `_MockPotionRecoveryCubit`, wraps the sheet in `SingleChildScrollView`).
- +17 → expected suite 4887 (full suite not run). `flutter test test/models/companion test/screens/mainScreen` +1380 green.
- Analyzer 47 info, ANALYZE_GATE_OK. All touched files formatter-clean. No GraphQL change, registry 54.

## Deviations from Plan

1. [Rule 3 - Blocking] `PotionSheet.targets` (field only) added in Task 1's GREEN commit: Task 1 passes the targets to the sheet, so the field had to exist before Task 2.
2. Extra test «with the switch off a ready potion opens a sheet with no target (Pitfall 3)».
3. Clean Code: `_outcome` takes `title`, `max` and an optional `healed` line instead of a boolean, per CLAUDE.md (no behaviour flags).
4. Doc comment of PotionSheet writes «Dai a …» (angle brackets triggered `unintended_html_in_doc_comment`).
5. STATE `Plan: 10 of 17` (the VALIDATION 22-10-03 literal `Plan: 10 of 17` matches; the brief's non-padded format).

## Known Stubs

None: the targets are wired from the served state; the switch is the intended pre-gate guard flipped in 22-16.

## Self-Check: PASSED
