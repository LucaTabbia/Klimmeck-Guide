---
phase: 10-admin-panel-innkeeper
plan: 07
subsystem: admin-panel
tags: [admin, innkeeper, completion, form, dialog, ui, tdd]
requires: [10-01, 10-03, 10-05, 10-06]
provides:
  - ParticipantOverrideSection, InjuryChips, QuantityStepper (lib/screens/innkeeper/components/)
  - confirmationRecapOf, resultRecapLinesOf, recapNameOf (lib/screens/innkeeper/components/completion_recap.dart)
  - sealed CompletionExit + openRequestCompletion (lib/screens/innkeeper/request_completion_route.dart)
  - RequestCompletionScreen (lib/screens/innkeeper/request_completion_screen.dart)
  - showResultsRecap (lib/screens/innkeeper/components/results_recap_dialog.dart)
  - RequestCardView.onComplete + completeKeyFor; InnkeeperPanelScreen.openCompletion
affects: [10-10, 10-11]
tech-stack:
  added: []
  patterns: [typed route result (sealed CompletionExit) translated by the caller, injectable route opener for widget tests, failureSerial-driven BlocConsumer listenWhen]
key-files:
  created:
    - lib/screens/innkeeper/components/quantity_stepper.dart
    - lib/screens/innkeeper/components/injury_chips.dart
    - lib/screens/innkeeper/components/participant_override_section.dart
    - lib/screens/innkeeper/components/completion_recap.dart
    - lib/screens/innkeeper/components/results_recap_dialog.dart
    - lib/screens/innkeeper/request_completion_route.dart
    - lib/screens/innkeeper/request_completion_screen.dart
    - test/screens/innkeeper/components/completion_form_test.dart
    - test/screens/innkeeper/components/completion_recap_test.dart
    - test/screens/innkeeper/request_completion_screen_test.dart
  modified:
    - lib/screens/innkeeper/components/request_card_view.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
key-decisions:
  - "The form exits with a typed CompletionExit (Completed/Gone/Busy/Forbidden, null on back): the screen pops, the panel translates (markCompleted, refetch, SnackBar, close) — the form never touches the panel route"
  - "NOT_FOUND / QUEST_IN_PROGRESS / FORBIDDEN pop the form both at open (LoadFailed) and at submit (Editing failure); NOT_PARTICIPANT keeps the form and the screen calls PendingRequestsCubit.refetch() (UI orchestrates)"
  - "The FORBIDDEN close + SnackBar is one static helper (_closeUnavailable) shared by the queue listener and the form exit, guarded by ModalRoute.isActive so a double FORBIDDEN never shows two SnackBars"
  - "The form scrolls in a SingleChildScrollView (participants are few) with «Conferma» and the form error pinned below it"
requirements-completed: []
duration: 30min
completed: 2026-10-29
---

# Phase 10 Plan 07: Completion UI Summary

«Completa» on every queue card (enabled only by `card.canComplete(serverNow)`) opens a root-route completion form with an HP slider, 28 injury chips and bounded consumable/spell steppers per participant; «Conferma» asks through the neutral confirmation dialog with a recap of only the changes, and the typed exit is mapped on the panel per BE code (results recap dialog, card removal, refetch, SnackBars, panel close on FORBIDDEN).

## What was built

- **Form controls (Task 1):** `QuantityStepper({label, value, max, onChanged})` (IconButtons «Diminuisci»/«Aumenta», 48 px targets); `InjuryChips({existing, added, onToggled})` (`FilterChip` per `InjuryType.values`, key `completion.injury.<name>`, existing chips selected + disabled); `ParticipantOverrideSection({draft, onHpChanged, onInjuryToggled, onConsumableChanged, onSpellChanged})` with `static hpSliderKey(characterId)` → `completion.hp.<id>`, stepper keys `completion.consumable.<charId>.<itemId>` / `completion.spell.<charId>.<spellId>`, fallbacks «Oggetto» / «Magia sconosciuta», notes «Nessun consumabile» / «Nessuna magia attiva».
- **Recap + route + screen (Task 2):** pure `confirmationRecapOf`, `resultRecapLinesOf`, `recapNameOf`; `sealed CompletionExit` (`CompletionCompleted(results)`, `CompletionGone`, `CompletionBusy`, `CompletionForbidden`); `openRequestCompletion(panelContext, card)` hands `PendingRequestsCubit` over with `.value` and creates `RequestCompletionCubit(..)..load()`; `RequestCompletionScreen({card})` (constants `title`, `confirmLabel`, `loadFailedMessage`, `retryLabel`).
- **Panel (Task 3):** `showResultsRecap(context, {card, results})` («Richiesta completata», «Chiudi»); `RequestCardView` gains `required onComplete` + `static completeKeyFor(questId)` → `innkeeper.complete.<questId>`; `InnkeeperPanelScreen({openCompletion = openRequestCompletion})` with `goneMessage` / `busyMessage` and `_complete` mapping every exit.

## TDD evidence

- Task 1 RED (`767bd93`): compile failure — `Error: Undefined name 'QuantityStepper'` / missing `participant_override_section.dart`. GREEN (`cc89f3b`): 16/16.
- Task 2 RED (`44ee3c3`): compile failure — `Error when reading 'lib/screens/innkeeper/components/completion_recap.dart': No such file or directory`, `Method not found: 'confirmationRecapOf'`. GREEN (`65c2b74`): recap 7/7, screen 23/23.
- Task 3 RED (`775b1f0`): compile failure — `Member not found: 'RequestCardView.completeKeyFor'`, `No named parameter with the name 'openCompletion'`. GREEN (`734a089`): `test/screens/innkeeper` 131/131.
- Full suite: 2767 tests green (2711 + 56). Analyzer: 51 issues (all info), gate exit 0.

## Deviations from Plan

1. **[Rule 1 - Bug] Form body uses SingleChildScrollView + Column instead of a lazy ListView** — a lazy list never built the second participant section off screen (test found 1 of 2 sections). Participants are few, so the eager column is correct. Commit `65c2b74`.
2. **[Rule 2 - Correctness] `_closeUnavailable` guards on `ModalRoute.of(context)?.isActive`** — the queue listener and the form's FORBIDDEN exit can both fire; without the guard a second SnackBar would show after the panel is already gone. Commit `734a089`.
3. **Existing 10-05 test updated** — «a card shows only the quest and the rows (D-08)» now also expects the «Completa» label in the card texts (renamed «…the rows and «Completa»»). Commit `775b1f0`.
4. Recap/result dialog names use `titleMedium` / `bodyLarge`: the theme has no `titleSmall` token.

## Known Stubs

None. Copy is provisional (D-22) as planned.

## Threat Flags

None — no new surface beyond the plan's threat model (T-10-26..29 mitigated: explicit confirm with `barrierDismissible: false`, `canComplete` gating, per-code Italian copy only, FORBIDDEN closes the panel).

## Self-Check: PASSED

- Files created exist; commits 767bd93, cc89f3b, 44ee3c3, 65c2b74, 775b1f0, 734a089 present on `feat/10-admin-panel`.
