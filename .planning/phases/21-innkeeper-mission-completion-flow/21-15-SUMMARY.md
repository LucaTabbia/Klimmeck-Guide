---
phase: 21-innkeeper-mission-completion-flow
plan: 15
subsystem: innkeeper
tags: [wizard, guided-mission, widget-test, prizes, recap, completion]
requires: ["21-14"]
provides:
  - "QuantityStepper({label, value, max, onChanged, min = 0}) — «−» enabled when value > min"
  - "PrizesStep(draft, isSubmitting, onNext(List<MissionPrizeInput>)) — «Premi» over the served prefilled prizes and the served catalogue"
  - "PrizeCatalogueSheet(options, onPickItem, onPickPet, onPickSpell) — tabs «Oggetti / Compagni / Magie», «Cerca», lazy lists, pick pops the sheet"
  - "missionRecapLinesOf({questTitle, draft}) + RecapStep(card, draft, isSubmitting, onComplete) — «Riepilogo» with neutral confirmation"
  - "host: pages prizes and recap wired; savePrizes(step: recap) → «Riepilogo»; «Completa» → complete() → CompletionCompleted"
affects: [21-16, 21-17, 21-18]
tech-stack:
  added: []
  patterns: ["step pages render rows lazily from a list of row builders (`List<Widget Function()>` + ListView.builder) so long per-character sections stay lazy", "number fields: TextField + FilteringTextInputFormatter.digitsOnly, controllers owned by the page state (rows scrolled away keep their text)"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/steps/prizes_step.dart
    - lib/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet.dart
    - lib/screens/innkeeper/missionCompletion/steps/recap_step.dart
    - test/screens/innkeeper/components/quantity_stepper_test.dart
    - test/screens/innkeeper/missionCompletion/steps/prizes_step_test.dart
    - test/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet_test.dart
    - test/screens/innkeeper/missionCompletion/steps/recap_step_test.dart
  modified:
    - lib/screens/innkeeper/components/quantity_stepper.dart
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
decisions:
  - "PrizesStep reads the prize options itself (`loadAll(participant ids)` in initState) instead of the host: the page is mounted exactly when «Premi» is entered; the host only asks for them when a draft reopens directly on «Riepilogo» (names of the chosen prizes)"
  - "The cure row shows only while the input keeps the served cure (remove only, no add-back): MissionPrizeOptions does not model the block cure and the BE accepts `cure` only when the rank block has one"
  - "While a character's options load, its entries are replaced by a `KGLoader(height: 32)`; if the read failed, entries show fallback names (`quantityLine(q, 'Oggetto')`, the pet id, 'Magia sconosciuta') and «Aggiungi premio» stays disabled"
  - "«Ferite:» in the recap lists labels in lower case (plan literal «Ferite: mano destra schiacciata», same style as `healedLine`), duplicates across fights removed, fight order kept"
  - "A fight without a served verdict reads 'Scontro k: …' without the ' · verdict' suffix; a character whose first outcome or last effective effect is missing gets no PV line"
metrics:
  duration: "~55 min"
  completed: 2026-11-14
---

# Phase 21 Plan 15: Wizard UI 3 — «Premi» and «Riepilogo» Summary

«Premi» edits each character's served prefilled prize (free digit-only coins and PE, items 1..99, removable item/pet/spell/cure, additions only from the served catalogue sheet) and «Riepilogo» lists quest, fights, PV, injuries and chosen prizes, then completes after the neutral «Completa la missione» confirmation. The wizard now covers the whole flow; the Locanda «Completa» is wired to it in 21-16 after the BE merge.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | «Premi» — prefilled served prizes, free coins and xp, served catalogue sheet | RED `41319643`, GREEN `da6aaeff` |
| 2 | «Riepilogo», explicit confirmation and completion | RED `c0de7750`, GREEN `663bebb6` |
| 3 | Bookkeeping | `docs(phase-21): record plan 15 progress` |

### RED evidence

- Task 1: `quantity_stepper_test` failed to compile («No named parameter with the name 'min'»), `prize_catalogue_sheet_test` / `prizes_step_test` failed to compile (files missing); in `mission_completion_screen_test` the two new prize cases failed (prizes page was `SizedBox.shrink()`), 141 others green.
- Task 2: `recap_step_test` and `mission_completion_screen_test` failed to compile (`recap_step.dart` missing, `RecapStep` / `missionRecapLinesOf` undefined).
- Green at first run once implemented (no extra code needed): «min defaults to 0 (Phase 10 D-12)» (existing behaviour pinned), ««Indietro» from «Premi» with zero fights goes to «Scontri» (D-24)» and ««Indietro» from «Riepilogo» goes back to «Premi»» (navigation already in 21-14's `_enterPrevious`) — they could not run in RED only because the files did not compile / the host test file needed the new import.

## Verification

- `flutter test test/screens/innkeeper` → +358, all passed (Task 1 end: +343).
- Analyzer gate: `47 issues found` → `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error), after each code task.
- Acceptance greps: `\.block` in prizes_step = 0; `rarity|minXpToLearn|maxRarity` = 0 in sheet and page; `ListView.builder` in sheet = 3; `digitsOnly` = 1; `maxPrizeItemQuantity` = 1; prizes_step_test D-15 = 2, D-22 = 4; recap_step `showDestructiveConfirmation` = 1, `primaryButtonStyle` = 2, `rifiut|aiuto|soccorso|reject` = 0; recap_step_test D-08 = 3, D-24 = 2; `openMissionCompletion` in innkeeper_panel_screen = 0 (still not wired, D-28).
- Formatter: every touched file formatted one by one (all were formatter-clean before; pre-check exit 0 on quantity_stepper.dart, mission_completion_screen.dart and its test). Formatter reflowed prizes_step.dart, recap_step.dart and the new tests.
- Trailer check `0` after every commit; `git status --short` clean.

## New copy for the UAT

Beyond D-30 / Open Question 8: «Rimuovi» (tooltip of the remove buttons), «Compagni» (catalogue tab). «Monete» and «PE» reuse existing words; «Cura» is the fallback of the cure row when `lifeShareLine` gives no line (cure share 0) — an existing word of the item lines. Other strings come from existing code: «Aggiungi premio», «Oggetti», «Magie», «Cerca», «Completa», «+N XP», «Vita: …», «Scontro k: … · Vittoria/Sconfitta», «Nome: PV a → b», «Ferite: …».

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test finders in the RED commits**
- **Found during:** Task 1 and Task 2 GREEN
- **Issue:** `tester.widget<IconButton>(find.byTooltip(...))` returns the `Tooltip` (type error); `find.byType(ButtonStyleButton)` matches the exact type only and found no `ElevatedButton`.
- **Fix:** `find.ancestor(of: find.byTooltip(..), matching: find.byType(IconButton))` / `find.widgetWithIcon(IconButton, Icons.remove|add)`; `find.byWidgetPredicate((w) => w is ButtonStyleButton)`. Expectations unchanged.
- **Files modified:** quantity_stepper_test.dart, prizes_step_test.dart, recap_step_test.dart
- **Commits:** `da6aaeff`, `663bebb6`

**2. [Rule 2 - Missing functionality] Prize names on a draft reopened at «Riepilogo»**
- **Found during:** Task 2
- **Issue:** with `loadAll` only in «Premi», a draft served at step `recap` would show fallback names.
- **Fix:** `_openServedStep` calls `MissionPrizeOptionsCubit.loadAll(ids)` when the served page is recap; pinned by «a draft reopened on «Riepilogo» reads the prize names (D-22)».
- **Commit:** `663bebb6`

Extra tests beyond the plan's list: «a character whose options are loading shows a small loader», «entering «Premi» reads the prize options of everyone (D-22)», ««Completa» is disabled while submitting» also at step level, «cancel does not complete (D-08)», two pure tests of `missionRecapLinesOf`.

## Known Stubs

None. The wizard is complete but unreachable from the Locanda until 21-16 (D-28, by design).

## Threat Flags

None (no new endpoint, no logging; T-21-51/52/53 mitigated as planned: catalogue-only additions, 1..99, digit-only inputs, no client filter greps, explicit neutral confirmation).

## Self-Check: PASSED

- Files exist: prizes_step.dart, prize_catalogue_sheet.dart, recap_step.dart and the four new test files.
- Commits found: 41319643, da6aaeff, c0de7750, 663bebb6.
