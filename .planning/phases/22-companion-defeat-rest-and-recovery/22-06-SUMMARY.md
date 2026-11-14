---
phase: 22-companion-defeat-rest-and-recovery
plan: 06
subsystem: journal
tags: [companion, journal, vitality, details-sheet, long-press, d-09, d-22]
requires: ["22-03 CompanionVitalityCubit + scope", "22-04 CompanionCard name/level", "22-05 CompanionInfoSheet"]
provides: ["live companion life, rest and defeat on the Journal parchments", "slot life line", "Journal._selectCompanion / _buildCompanionSheet"]
affects: ["22-12 rename entry point (details sheet onRename)", "22-09 PET_DEFEATED mapping"]
tech-stack:
  added: []
  patterns: ["section-scoped BlocBuilder on CompanionVitalityCubit feeding stateless rows", "Journal Stack hosts the companion sheet after equipment and spell"]
key-files:
  created:
    - test/screens/mainScreen/tabs/journal/components/owned_companion_row_test.dart
    - test/screens/mainScreen/tabs/journal/journal_companion_details_test.dart
  modified:
    - lib/screens/mainScreen/tabs/journal/components/owned_companion_row.dart
    - lib/screens/mainScreen/tabs/journal/components/companion_slot.dart
    - lib/screens/mainScreen/tabs/journal/components/companion_content.dart
    - lib/screens/mainScreen/tabs/journal/sections/companion_section.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart
decisions:
  - "CompanionSlot gets name and level but no vitality parameter: the slot life line lives in CompanionContent under the box, so a vitality field on the slot would be unused"
  - "The companion sheet is wrapped in a SingleChildScrollView in the Journal Stack, like the equipment sheet (parchment is 1.3 x screen height)"
  - "The long press stays available during a mission (read only); only the tap and the sheet bookmark are locked"
metrics:
  duration: ~30 min
  completed: 2026-11-14
---

# Phase 22 Plan 06: Journal «Compagno» live life, rest, defeat and details Summary

Journal companion parchments now read «Vita: x / max» (companion's own max via the vitality) under the experience line, rising live from `CompanionVitalityCubit`, with «A riposo: in forze fra …» / «Sconfitto: torna fra …» and «Pozione: pronta fra …»; a defeated parchment is faded and refuses the tap until `fullLifeAt`; the slot shows the equipped companion's life; long press on a parchment or on the slot opens `CompanionInfoSheet` in the Journal Stack, its bookmark toggling the companion (off when defeated or on a mission, no rename).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Parchment states with live life, slot life and name | 34a72154 (RED), 5abdba7b (GREEN) |
| 2 | Long-press details hosted in the Journal Stack | f9f21f9c (RED), dcfba8e0 (GREEN) |
| 3 | Bookkeeping | this commit |

## RED evidence

- Task 1: compile failures — `No named parameter with the name 'vitality'` (row test), `No named parameter with the name 'onShowDetails'`, `Member not found: 'slotLifeKey'` (section test).
- Task 2: 7 of 8 cases failed with `Found 0 widgets with type "CompanionInfoSheet"` (or `Bad state: No element` from the sheet finder); «a tap outside the companion sheet closes it» was green at the first run (nothing is open, so nothing is found after the tap) and turns meaningful with the sheet wired.

## Retargeted pin

- «the life of the owned companion is shown nowhere (D-18)» → «the life of the owned companion is shown under its experience (D-09)» (`Vita: 7 / 12` below `Esperienza: 40 / 300`).
- «the slot holds the equipped companion with its speed (D-10)» unchanged and green.

## Tests

- New: owned_companion_row_test 11, journal_companion_details_test 8; companion_section_test +8 (new group «companion life, rest and defeat»), D-18 case retargeted. Net +27 → expected suite 4837 (full suite not run).
- `flutter test test/screens/mainScreen/tabs/journal` → +290 all passed.
- Analyzer 47 info / 0 warning / 0 error, ANALYZE_GATE_OK. All touched files were formatter-clean before and after.

## Deviations from Plan

1. **[Rule 1 - Test bug] Defeated row opacity finder** — found during Task 1 GREEN: `find.descendant(of: row, matching: AnimatedOpacity)` matched two widgets (the card has its own); the test uses `.first` (the row's fade). Committed with the GREEN commit 5abdba7b.
2. **CompanionSlot without `vitality`** — the plan lists a `vitality` parameter on the slot, but the slot life line sits in `CompanionContent` (as the plan's own step 3 says); an unused field was left out (Clean Code).
3. **SingleChildScrollView around the Journal companion sheet** — not in the plan skeleton; same host pattern as the equipment sheet.
4. Extra tests beyond the plan list: «no life line without a vitality», «an unnamed levelled companion reads «Livello 3»», «the life line uses the companion's own max (D-38, D-09)» (section, real cubit), «no slot life when the slot is empty», «the long press asks for the details during a mission», «a named companion reads its name on the slot card», «the equipped companion opens from the slot bookmarked», «a tap outside the companion sheet closes it».
5. STATE `Plan: 6 of 17` and Progress `6/17 | In Progress` per orchestrator format; the plan's literal grep `Plan: 06 of 17` (Task 3 verify, VALIDATION 22-06-03) does not match — expected.

## Known Stubs

None. The rename entry point (`onRename`) is deliberately not wired (Pitfall 3, plan 22-12).

## Self-Check: PASSED

- Files exist: owned_companion_row_test.dart, journal_companion_details_test.dart, all modified lib files.
- Commits present: 34a72154, 5abdba7b, f9f21f9c, dcfba8e0.
