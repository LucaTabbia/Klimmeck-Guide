---
phase: 21-innkeeper-mission-completion-flow
plan: 13
subsystem: innkeeper
tags: [wizard, guided-mission, widget-test, teleport, mission-draft]
requires: ["21-12"]
provides:
  - "openMissionCompletion(panelContext, card) → Future<CompletionExit?> (route with repository, queue and teleport mode by .value + the four wizard cubits)"
  - "MissionCompletionScreen(card) + enum MissionPage { place, encounters, fight, prizes, recap } + all wizard copy/keys as static constants"
  - "MissionStepHeader(stepNumber, title) — 'Passo k di 5 · titolo'"
  - "StartStep(isStarting, onStart), PlaceStep(draft, participants, isSubmitting, onTeleport, onStay)"
affects: [21-14, 21-15, 21-16, 21-17]
tech-stack:
  added: []
  patterns: ["served step picks the page only on the first Ready (initState for an already-Ready cubit, listener otherwise)", "_runThenOpen moves the page only when the failureSerial is unchanged", "single exit guard (_hasLeft) for queue + reply racing"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/mission_completion_route.dart
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - lib/screens/innkeeper/missionCompletion/components/mission_step_header.dart
    - lib/screens/innkeeper/missionCompletion/steps/start_step.dart
    - lib/screens/innkeeper/missionCompletion/steps/place_step.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_route_test.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
    - test/screens/innkeeper/missionCompletion/steps/place_step_test.dart
  modified: []
decisions:
  - "A MissionDraftLoadFailed with NOT_FOUND / QUEST_IN_PROGRESS / FORBIDDEN exits like an action failure; any other load failure shows its line + «Riprova» (no extra copy: the load-failed text reuses the four error lines)"
  - "Back is also blocked while «Inizia la missione» is in flight (Absent.isStarting), not only on Ready.isSubmitting"
  - "«Indietro» = previous MissionPage in enum order, no call; disabled on «Luogo» and while submitting. The fight index is a final field (0) until 21-14 adds navigation between fights"
  - "Discard uses the default destructive (red) confirm style, unlike the neutral completion confirm"
metrics:
  duration: "~35 min"
  completed: 2026-11-14
---

# Phase 21 Plan 13: Wizard UI 1 Summary

Route and host screen of the guided mission wizard over the served draft: explicit «Inizia la missione» (no draft on open), resume at the served step, «Passo k di 5 · titolo» header with the leave note, discard with confirmation, Phase 10-style exits (`CompletionGone` / `CompletionBusy` / `CompletionForbidden` / `CompletionCompleted`, `null` on discard), raw-queue gone listener (Pitfall 5), and the «Luogo» page with the group teleport (`resumeCardKey: card.cardKey`) and «Resta qui».

**Not wired: «Completa» still opens the Phase 10 form** (`grep -c openMissionCompletion lib/screens/innkeeper/innkeeper_panel_screen.dart` = 0, D-28; wiring in 21-16).

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 Route and host screen | `98b17410` test(innkeeper): expect the mission wizard shell · `911a25b7` feat(innkeeper): add the mission wizard shell | RED: compile failure (route/screen files missing); GREEN: `flutter test test/screens/innkeeper/missionCompletion` +79 (screen 30 + route 1 + 48 cubit tests of 21-12) |
| 2 «Luogo» page | `72030afb` test(innkeeper): expect the place step of the wizard · `d41b191e` feat(innkeeper): add the place step of the wizard | RED: compile failure (`place_step.dart` missing); GREEN +89 |
| 3 Bookkeeping | docs(phase-21): record plan 13 progress | ROADMAP 13/18, STATE `Plan: 13 of 18`, VALIDATION 21-13-01..03 green |

Tests: `mission_completion_screen_test` +34, `mission_completion_route_test` +1, `place_step_test` +6; `flutter test test/screens/innkeeper/missionCompletion` +89; `flutter test test/screens/innkeeper` +270 green.

Green at first run after GREEN of Task 1 (no RED of their own beyond compile): «a later save never moves the page», «back is allowed with no call in flight», ««Indietro» is disabled on «Luogo»» — they pin behaviour of the shell written in the same task. In Task 2 the screen-level «a refused «Resta qui» stays on «Luogo» (T-21-46)» pins `_runThenOpen`.

Formatted files (one by one): the 8 files above (formatter reflowed `mission_completion_screen.dart` and the screen test once). Analyzer: `47 issues found` — 47 info / 0 warning / 0 error, `ANALYZE_GATE_OK` after each code task. Trailer check 0 on every commit.

## Deviations from Plan

None in behaviour. Notes:
- Extra cases beyond `<behavior>` (served steps prizes/recap, later save not moving the page, back disabled/back one page, cancel discard, NOT_FOUND at start, FORBIDDEN at open, four failure lines, back allowed, refused «Resta qui», place-step disabled while submitting).
- The doc comment of `place_step.dart` avoids the literal «Resta qui» so the acceptance grep stays at 1.

## Known Stubs

- `mission_completion_screen.dart` `_buildPage`: pages `encounters`, `fight`, `prizes`, `recap` render `const SizedBox.shrink()` by plan; 21-14 and 21-15 replace them and add the primary action («Avanti» etc.) of each page to the bottom bar (`nextLabel` / `nextKey` are declared, unused).

## Notes for the next plans

- A participants read failure (`MissionParticipantsFailed`) leaves both «Luogo» buttons disabled with no retry in the page (plan scope); 21-14/15 may add a retry if the UAT asks.
- `TeleportPreparationFailed` is also caught by the panel's own listener (the panel stays mounted under the wizard): after 21-16 the message may be queued twice; consider a guard there.

## Self-Check: PASSED
