---
phase: 10-admin-panel-innkeeper
plan: 01
subsystem: admin-models
tags: [admin, innkeeper, models, tdd, pending-request]
requires: []
provides:
  - PendingRequest / PendingRequestQuest / PendingRequestCharacter (+ tryFromJson)
  - QueuedTravel
  - sealed ParticipantPresence + presenceOf
  - RequestCard + requestCardsOf
  - ParticipantDraft / ConsumableLine / SpellLine + overridesOf
  - ParticipantOverride, CompletePendingRequestInput
  - test fixtures pendingRequestJson / queuedTravelJson / worldMissionEntriesJson / participantCharacterJson
affects: [10-02, 10-03, 10-04, 10-05, 10-06, 10-07, 10-11]
tech-stack:
  added: []
  patterns: [entry-level tryFromJson, sealed presence on server clock, pure draft diff into wire input]
key-files:
  created:
    - lib/models/pending_request/queued_travel.dart
    - lib/models/pending_request/pending_request.dart
    - lib/models/pending_request/participant_presence.dart
    - lib/models/pending_request/request_card.dart
    - lib/models/request/participant_draft.dart
    - lib/models/request/participant_override.dart
    - lib/models/request/complete_pending_request_input.dart
    - test/helpers/fixtures/pending_request_fixtures.dart
    - test/models/pending_request/pending_request_test.dart
    - test/models/pending_request/participant_presence_test.dart
    - test/models/pending_request/request_card_test.dart
    - test/models/request/participant_draft_test.dart
    - test/models/request/participant_override_test.dart
  modified: []
decisions:
  - "The draft diff getter is `ParticipantDraft.asOverride`, not `override`: a member named `override` shadows the `@override` annotation inside the class (compile error)"
  - "`awaitingAidJson` is re-exported from travel_fixtures.dart instead of redefined, so a test importing both fixture files has no ambiguous name"
metrics:
  duration: 8min
  completed: 2026-10-29
---

# Phase 10 Plan 01: Admin panel pure models Summary

Flutter-free queue domain for the innkeeper panel: item-by-item `PendingRequest` parsing with the optional BE-HARD-08 `pendingQuest` and a fail-closed `QueuedTravel`, presence on the server clock, per-quest `RequestCard`s (BE order, hidden busy lanes, seats, completability), and a `ParticipantDraft` whose diff yields only the GM's changes as `ParticipantOverride` / `CompletePendingRequestInput`.

## Tasks

| Task | RED commit | GREEN commit | Tests |
|------|-----------|--------------|-------|
| 1 Queue entry models + fixtures | beaead3 | 131a6b6 | pending_request_test 15/15 |
| 2 Presence + request cards | 92f80a4 | 7581c0c | participant_presence_test 7/7, request_card_test 12/12 |
| 3 Draft, override diff, completion input | 991444c | 1151e0e | participant_draft_test 17/17, participant_override_test 5/5 |

Total: `flutter test test/models/request/participant_draft_test.dart test/models/request/participant_override_test.dart test/models/pending_request` → +56, all passed.

### RED failures seen

- Task 1: `Error: Undefined name 'PendingRequest'` (and missing `lib/models/pending_request/pending_request.dart`), compile failure.
- Task 2: `Error when reading 'lib/models/pending_request/request_card.dart': No such file or directory`, `Type 'RequestCard' not found`, `Method not found: 'requestCardsOf'`.
- Task 3: `Error when reading 'lib/models/request/participant_draft.dart': No such file or directory`, `Type 'ParticipantDraft' not found`, `Couldn't find constructor 'ConsumableLine'`.

## Verification

- Analyzer repo-wide: 52 issues (51 info + 1 pre-existing warning), no issue in the new files, no new issue vs the baseline. The pre-existing warning (`unnecessary_cast` in `test/repository/services/auth/auth_token_service_contract_test.dart:40`, file untouched since Phase 1) makes the plan's literal gate command exit 1 on the baseline itself; logged in `deferred-items.md`.
- `dart format --set-exit-if-changed` clean on all 13 files; no `package:flutter/` in the new models; no `DateTime.now` in presence/cards; no `ActiveTravel`, `twitchId`, `pointsSpent` in `pending_request.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `ParticipantDraft.override` renamed to `asOverride`**
- **Found during:** Task 3 GREEN
- **Issue:** a getter named `override` shadows `dart:core`'s `override` inside the class, so every `@override` annotation in `ParticipantDraft` failed to compile («Not a constant expression»).
- **Fix:** getter `ParticipantOverride? get asOverride`; `overridesOf` and the draft test updated in the GREEN commit. Plan 10-06's interface line (`ParticipantOverride? get override`) must read `asOverride`.
- **Commit:** 1151e0e

**2. [Rule 3 - Blocking] fixture `pendingQuest` typed `Object?`**
- The plan's `String? pendingQuest` parameter cannot express the required `pendingQuest: 42` (non-string) case; typed `Object?` so the null-return test is expressible.

**3. [Clean code] `awaitingAidJson` re-exported, not redefined**
- `test/helpers/fixtures/travel_fixtures.dart` already defines `awaitingAidJson({quest = 'q-1', aidQuest = 'aid-1', since})`; a second top-level function with the same name would make any test importing both files ambiguous. `pending_request_fixtures.dart` does `export 'travel_fixtures.dart' show awaitingAidJson;` (ids `q-1` / `aid-1` instead of the plan's `quest-boss-1` / `quest-aid-1`; no test depends on them).

**4. Extra fixture constants** `fireballSpellId = 'spell-fireball'` and `potionItemId = 'loot-potion'` added for the draft tests (values as in the plan).

## Known Stubs

None.

## Self-Check: PASSED
