---
phase: 21-innkeeper-mission-completion-flow
plan: 09
subsystem: innkeeper
tags: [teleport, resume, pending-requests, draft-flag]
requires: ["21-08"]
provides:
  - "lib/screens/innkeeper/completion_exit.dart — sealed CompletionExit + CompletionCompleted(results), CompletionGone, CompletionBusy, CompletionForbidden (moved verbatim; request_completion_route.dart re-exports it until 21-17)"
  - "openInnkeeperPanel(context, {String? resumeCardKey}) → InnkeeperPanelScreen(resumeCardKey: ...)"
  - "InnkeeperPanelScreen({openCompletion = openRequestCompletion, resumeCardKey}) — one-shot BlocListener on the first loaded snapshot: card from requestCardsOf(state.requests) (raw, Pitfall 5) → _complete, else SnackBar goneMessage (D-28)"
  - "TeleportModeLanding forwards TeleportSucceeded/TeleportCancelled.resumeCardKey to openInnkeeperPanel"
  - "PendingRequest.missionDraftStartedAt (DateTime?, lenient, in props; NOT selected before the gate)"
  - "RequestCard.hasMissionDraft (default false; any entry with the draft); RequestCardView.completeLabel 'Completa' / resumeLabel 'Riprendi'"
affects: [21-13, 21-16, 21-17]
tech-stack:
  added: []
  patterns: ["one-shot listenWhen on the first loaded snapshot", "card rebuilt from the fresh raw snapshot after the Map"]
key-files:
  created:
    - lib/screens/innkeeper/completion_exit.dart
  modified:
    - lib/screens/innkeeper/request_completion_route.dart
    - lib/screens/innkeeper/innkeeper_panel_route.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - lib/screens/mainScreen/components/teleport_mode_landing.dart
    - lib/models/pending_request/pending_request.dart
    - lib/models/pending_request/request_card.dart
    - lib/screens/innkeeper/components/request_card_view.dart
    - test/screens/mainScreen/components/teleport_mode_landing_test.dart
    - test/screens/innkeeper/innkeeper_panel_route_test.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
    - test/models/pending_request/pending_request_test.dart
    - test/models/pending_request/request_card_test.dart
decisions:
  - "The panel keeps importing only request_completion_route.dart (it needs openRequestCompletion; a second import of completion_exit.dart is an unnecessary_import info that breaks the 47-info baseline)"
metrics:
  duration: ~10 min
  completed: 2026-11-14
---

# Phase 21 Plan 09: Return to the wizard after the Map and the «Riprendi» flag Summary

After a teleport prepared with a `resumeCardKey`, success and «Annulla» reopen the Locanda with that key and the panel opens that card's completion once, on its first loaded snapshot, rebuilding the card from the raw requests (also when it is not actionable); a card gone from the queue shows «Richiesta non più disponibile». The card-level «Teletrasporta» (no key) reopens the bare panel as before. The completion exits now live in `completion_exit.dart` for the future wizard. The queue entry models `missionDraftStartedAt` leniently and a card with a started draft reads «Riprendi» (inert until the gated plan selects the field).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Shared exits and the resume of a card's completion after the Map | 871331ac (RED), d3831a15 (GREEN) |
| 2 | Draft flag on the queue entry and the «Riprendi» card label | cd785c4b (RED), 6842c65b (GREEN) |
| 3 | Bookkeeping | this commit |

## RED evidence

- Task 1: compile failure — `The getter 'resumeCardKey' isn't defined for the type 'InnkeeperPanelScreen'` (landing and route tests), `No named parameter with the name 'resumeCardKey'` (route and panel tests).
- Task 2: compile failure — `The getter 'missionDraftStartedAt' isn't defined for the type 'PendingRequest'`, `The getter 'hasMissionDraft' isn't defined for the type 'RequestCard'`, `RequestCardView.resumeLabel` undefined.

## Tests

- `flutter test test/screens/innkeeper test/screens/mainScreen/components` → +353, all passed.
- `flutter test test/models/pending_request test/screens/innkeeper test/graphql/pending_request_documents_test.dart` → +242, all passed.
- New cases: landing ×4 (two no-key pins asserting `resumeCardKey == null`, two D-28 with key), route ×1 (D-28), panel group 'resume after the Map (Phase 21)' ×5, panel group 'draft label (Phase 21)' ×2, pending_request ×3 (one extra: equality differs on the draft, D-17), request_card ×2.
- Green at first run: none (every RED failed at compile time).

## Gates

- Formatter: all 12 touched existing files were formatter-clean before the change; every touched file formatted one by one (`innkeeper_panel_route.dart` and `innkeeper_panel_screen_test.dart` reflowed by the formatter).
- Analyzer: `47 issues found` — 47 info / 0 warning / 0 error, `ANALYZE_GATE_OK` after each code task.
- Acceptance greps: `sealed class CompletionExit` 1 in completion_exit.dart / 0 in the route; export 1; `resumeCardKey` landing 5, panel 4; `requestCardsOf` panel 1; `D-28` in the panel test 4; `missionDraftStartedAt` model 4 / fragment 0; `hasMissionDraft` 4; `'Riprendi'` 1. Trailer check 0 on every commit.

## Deviations from Plan

- The pinned landing cases (success/cancel without key) were left untouched; the «`resumeCardKey == null`» assertions were added as two separate new cases instead of editing the pins.
- The plan's step «import completion_exit.dart instead of reaching the exits through the form route» does not apply to the panel: it still needs `openRequestCompletion` from the route, and the extra import is flagged `unnecessary_import` (info 48). No lib file uses only the exits today.

## Known Stubs

- `missionDraftStartedAt` is not selected in `PendingRequestFragment` (gated selection, 21-16): «Riprendi» never shows on today's BE. No caller passes a `resumeCardKey` yet (the wizard, 21-13, will).

## Self-Check: PASSED
