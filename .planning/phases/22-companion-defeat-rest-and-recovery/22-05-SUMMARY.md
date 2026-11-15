---
phase: 22-companion-defeat-rest-and-recovery
plan: 05
subsystem: shared
tags: [companion, details-sheet, route, switch, pitfall-3]
requires: ["22-02 companion lines + vitality", "22-04 DetailsSheetFrame + CompanionCard"]
provides: ["companionCareEnabled switch", "CompanionInfo", "CompanionInfoSheet", "showCompanionDetails"]
affects: ["22-06 Journal long press", "shop / basket / quest sheet / innkeeper long press", "rename and potion entry points"]
tech-stack:
  added: []
  patterns: ["details body rows shown only with served data", "root showGeneralDialog host for surfaces without a Stack"]
key-files:
  created:
    - lib/config/companion_care.dart
    - lib/shared/components/popup/companion_info.dart
    - lib/shared/components/popup/companion_info_sheet.dart
    - lib/shared/components/popup/companion_details_route.dart
    - test/config/companion_care_test.dart
    - test/shared/components/popup/companion_info_sheet_test.dart
    - test/shared/components/popup/companion_details_route_test.dart
  modified: []
decisions:
  - "Hosts without a Stack (shop, basket, quest sheet, innkeeper rows) use showCompanionDetails (root showGeneralDialog) instead of generalising EquipmentInfoSheetDisplay (research default 8): one host for four surfaces, no edit of the non-formatter-clean equipment_info_display.dart"
  - "The route wraps the sheet in a SingleChildScrollView like Journal._buildInfoSheet (the parchment is 1.3 x screen height)"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 22 Plan 05: Companion details sheet, route and care switch Summary

One pre-gate switch `companionCareEnabled = false`, a `CompanionInfo` body that prints name, species, «Livello N», «Vita: x / max» (max carried by the vitality, D-38), rest/defeat line, potion wait, «Recupero completo», speed, attack, defense, experience and an in-world rename action, all on the shared `DetailsSheetFrame` with the `CompanionCard`; plus `showCompanionDetails`, a root-navigator slide-in route closed by a tap outside for the hosts without a Stack.

## Tasks

| Task | Commits |
|------|---------|
| 1 Switch + details body and sheet | 78a42c7b test(shared): expect the companion details sheet; 480f82f1 feat(shared): add the companion details sheet |
| 2 showCompanionDetails | ded6d065 test(shared): expect the companion details route; d0bbd99a feat(shared): open the companion details from any list |
| 3 Bookkeeping | docs(phase-22): record plan 05 progress |

## RED failures

- Task 1: compilation failure, `package:klimmeck_guide/config/companion_care.dart` and `shared/components/popup/companion_info*.dart` do not exist (2 load failures).
- Task 2: compilation failure, `companion_details_route.dart` missing, `showCompanionDetails` not found.

## Tests

- `companion_care_test.dart` 1, `companion_info_sheet_test.dart` 17, `companion_details_route_test.dart` 3 → +21, expected suite 4810 (full suite not run).
- Attack and defense (removed from the card in 22-04) are covered in the details: «speed, attack, defense and experience moved here from the card (D-22)» checks `Attacco: tagliente 12, fuoco 5`, `Difesa: contundente 4`, `Velocità ×2`, `Esperienza: 3 / 10`; an extra case shows no stat row without served stats.
- `flutter test test/config test/shared/components/popup` → +225 all passed. Analyzer 47 info, ANALYZE_GATE_OK. All files formatter-clean.

## Deviations from Plan

1. [Rule 1 - Test harness] The rename tap test first failed because the rename row sat below the 360 px landscape viewport (the parchment is 1.3 x height): added `ensureVisible` before the tap, inside the GREEN commit of Task 1.
2. [Rule 1 - Test harness] The route test's opener `GestureDetector` around an empty `SizedBox` needed `HitTestBehavior.opaque`; fixed inside the GREEN commit of Task 2.
3. [Rule 3] `showCompanionDetails` wraps `CompanionInfoSheet` in a `SingleChildScrollView` (the plan skeleton omits it), as `Journal._buildInfoSheet` does, so the 1.3 x height parchment never overflows the screen-high box.
4. Extra cases beyond the plan list: unnamed companion title only, steady companion without status, no stat rows without served stats, no bookmark without `isEquipped`, rename 44 px target.
5. STATE `Plan: 5 of 17` and Progress `5/17 | In Progress` per the orchestrator: the plan's grep `Plan: 05 of 17` (Task 3 verify, VALIDATION 22-05-03 command) does not match, expected.
6. Wave-0 checkbox of the three test files ticked in 22-VALIDATION.md.

## Known Stubs

None. `companionCareEnabled` is intentionally false until the gate plan (Pitfall 3); no entry point reads it yet (later plans wire it through constructor defaults).

## Self-Check: PASSED
