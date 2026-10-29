---
phase: 10
slug: admin-panel-innkeeper
audited: 2026-10-29
status: secured
asvs_level: 1
block_on: high
threats_total: 43
threats_mitigated: 30
threats_accepted: 2
threats_transferred: 6
threats_open: 0
threats_open_blocking: 0
threats_deferred: 5
open_ids: []
deferred_ids: [T-10-39, T-10-40, T-10-41, T-10-42, T-10-43]
updated: 2026-10-29
---

# Phase 10 - Security (Admin Panel, Innkeeper, FE)

Audit of the `<threat_model>` blocks of plans 10-01..10-11 (43 rows) against HEAD `e644ace` of `feat/10-admin-panel` (base `develop`, code review fixes of `10-REVIEW-FIX.md` included). Evidence is the final code. Plan 10-11 (gated on the BE Phase 10 PR: `pendingQuest` selection, device E2E, FORBIDDEN-as-adventurer, audit rows) is deliberately not executed: its five threats (T-10-39..T-10-43) are DEFERRED, not open.

Runs of this audit: `flutter test` over the 36 test files added or changed by the phase (`git diff --name-only --diff-filter=AM develop...HEAD -- test`, `*_test.dart`) = 488 passed, 0 failed (foreground). Full suite and analyzer taken from `10-REVIEW-FIX.md` / `10-VERIFICATION.md`, not re-run. Schema check 42/42 against BE `origin/develop` `8f30d1d` is taken from `10-02-SUMMARY.md` / `10-VERIFICATION.md` (BE read through git only); the registry holds 42 documents (`tool/schema_check/schema_check_documents.dart`, includes `GetPendingRequests`, `OnPendingRequestsUpdated`, `CompletePendingRequest`, `TeleportCharacter`). No command of this audit read `.env`, `google-services.json` or `Platform.environment`; `git ls-files` lists neither. The only non-lib/test/planning path in the phase diff is the schema registry. BE repo not touched. Implementation files were read only.

Disposition: M = mitigate (verified in code + test), A = accept (logged below), T = transfer (BE, documented below).

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `AuthState.user.role` -> panel visibility | `isInnkeeperSession` (`innkeeper_access.dart:5-6`) is UX only: it shows the Settings section (`innkeeper_section.dart`) and cancels the teleport mode on a lost role (`teleport_mode_landing.dart:46-52`). No data path trusts it; the BE enforces `@Roles(innkeeper)` and the FE reacts to `FORBIDDEN`. |
| BE `pendingRequests` / `pendingRequestsUpdated` -> `PendingRequest` | `PendingRequest.tryFromJson` is the boundary: null on any malformed entry, skipped item by item (`graphql.dart:239-248`), count-only log; an unreadable travel is kept as `hasUnreadableTravel` (fail-closed for «Completa»). |
| BE error answers -> `InnkeeperFailure` -> UI copy | Classified by `extensions.code` only (`innkeeper_failure.dart:46-60`, `graphQlErrorCode`), `unknown` default; `_guard` maps every throwable (`innkeeper_repository.dart:62-80`); UI shows fixed Italian copy; no `OperationException` / `.message` under `lib/screens/innkeeper` or the teleport map files (grep = 0). |
| form -> `completePendingRequest` | Input = `pendingQuestId` + only the changed participants (`participant_draft.dart` `asOverride`, `complete_pending_request_input.dart:15-19`); values clamped client-side; BE re-validates (`OUTCOME_OVERRIDE_INVALID`, `OUTCOME_NOT_PARTICIPANT`) and stays source of truth (CLAUDE.md rule 4). |
| Map drop -> `teleportCharacter` | Sends `characterId` + `poiId` only (`innkeeper_repository.dart:48-53`, `TravelRequest(id, poiId)`); the new position is never taken from the response (`:44`). |
| panel route / teleport mode -> session lifetime | Panel cubit is route-scoped and closed with the route; `AuthGate` pops root routes at session end (`auth_gate.dart:38`); `TeleportModeCubit` lives in the keyed `AuthenticatedShell` (`authenticated_shell.dart:225`). |
| WS subscription -> panel | Terminal on `FORBIDDEN` (`pending_requests_cubit.dart:196-203`), exponential backoff capped at `WsReconnectPolicy.maxReconnectDelay` otherwise, one timer. |
| widget lifecycle -> `MapAvailabilityCubit` | `isTeleportMode` is excluded from `isFreeBeneathRoutes` (`map_availability_state.dart:33-34`); `WorldMap.dispose` resets it (`world_map.dart:153-157`). |
| FE documents <-> BE Phase 10 schema | `pendingQuest` under `PendingRequestCharacter` NOT selected (`pending_request_fragment.dart`); DEFERRED to 10-11 (gate on the BE PR). |

## Threat Verification

| Threat | Cat. | Component | Disp | Status | Evidence (file:line) | Test |
|--------|------|-----------|------|--------|----------------------|------|
| T-10-01 | DoS | `PendingRequest.tryFromJson` | M | CLOSED | `graphql.dart:239-248` `map(PendingRequest.tryFromJson).whereType` skips nulls | `pending_request_test.dart` group `tryFromJson` (null cases, `:115-150`); `graphql_pending_requests_test.dart` "skips a malformed entry and keeps the valid ones" |
| T-10-02 | Tampering | `travel` / presence | M | CLOSED | `hasUnreadableTravel` -> `ParticipantTravellingUnknown`; `RequestCard.canComplete` blocks it | `pending_request_test.dart:63` "an unreadable travel is fail-closed"; `participant_presence_test.dart:62,81`; `request_card_test.dart:152` |
| T-10-03 | Tampering | `ParticipantDraft` | M | CLOSED | `participant_draft.dart` `withHp` clamp `1..max`, `withConsumableUsed` `0..owned`, `withSpellUsed` `0..remaining`, `asOverride` keeps quantities >= 1 only | `participant_draft_test.dart:82,114,126,136-186`; `participant_override_test.dart:8` |
| T-10-04 | Info disc. | models | M | CLOSED | `lib/models/pending_request`, `lib/models/request`: no `twitchId`/`pointsSpent`/`user` (grep = 0) | `pending_request_documents_test.dart:30` |
| T-10-05 | Tampering | documents | M | CLOSED | Fragment without `pendingQuest`; registry 42; schema check 42/42 | `pending_request_documents_test.dart:30` "never selects the gated or private fields", `:57,:83,:117` "is registered in the schema check" |
| T-10-06 | Info disc. | `PendingRequestFragment` | M | CLOSED | `pending_request_fragment.dart` selects no `user`/`pointsSpent`; the only log is `graphql.dart:245` (a count) | `pending_request_documents_test.dart:30` |
| T-10-07 | EoP | admin ops | T | CLOSED | Transferred to BE `@Roles(innkeeper)`, see log; FE maps `FORBIDDEN` (`innkeeper_failure.dart:55`) | `innkeeper_failure_test.dart:14-30`, `innkeeper_repository_test.dart:72,136` |
| T-10-08 | Info disc. | error mapping | M | CLOSED | `innkeeper_failure.dart:46-60` code only; `_guard` `innkeeper_repository.dart:62-80`; `InnkeeperException.toString` prints the enum name (`:39`) | `innkeeper_failure_test.dart:47` "ignores the message text and relies on the code only", `:61`; `innkeeper_repository_test.dart:148` |
| T-10-09 | DoS | `_guard` | M | CLOSED | `innkeeper_repository.dart:28,64` 15 s `timeout` -> `timedOut` | `innkeeper_repository_test.dart:53,92` (fake_async) |
| T-10-10 | DoS | `_scheduleResubscribe` | M | CLOSED | `pending_requests_cubit.dart:210-221` single `_resubscribeTimer`, `exponentialBackoff(..., max: maxReconnectDelay)`, `_attempt = 0` on snapshot (`:113`) | `pending_requests_cubit_test.dart:215,231,251,262` |
| T-10-11 | EoP | FORBIDDEN | M | CLOSED | `:196-203` `_terminate()` (`:223`) (cancels timers and subscription, `isForbidden`); `_performRefetch` returns when terminated (`:92`) | `pending_requests_cubit_test.dart:276,490` |
| T-10-12 | DoS | timers after pop | M | CLOSED | `:232` `close()` cancels timers and both subscriptions; callbacks check `isClosed` (`:92,211`) | `pending_requests_cubit_test.dart:290,575` |
| T-10-13 | Tampering | arrival derivation | M | CLOSED | `grep DateTime.now` over `lib/screens/innkeeper`, `lib/repository/innkeeper*`, `lib/models/pending_request`, `lib/models/request` = 0; time only from `_clock.now()` | `pending_requests_cubit_test.dart:304-395`; `request_card_test.dart:138` |
| T-10-14 | Tampering | `teleportTo` | M | CLOSED | `teleport_mode_cubit.dart:61-84`: `isTeleporting` guard, `travelDestinationFor` null for the current city | `teleport_mode_cubit_test.dart:162,228` (current city no call; drop in flight ignored) |
| T-10-15 | Tampering | late responses | M | CLOSED | `_generation` checked after every await (`:48,57,77,81`) | `teleport_mode_cubit_test.dart:136` "a read answered after cancel does not enter the mode", `:271` |
| T-10-16 | EoP | `teleport` | T | CLOSED | Transferred to BE, see log; FE leaves the mode on `forbidden` (`:96-103`) | `teleport_mode_cubit_test.dart:216` "a lost role ends the mode" |
| T-10-17 | DoS (UX) | result presenter | M | CLOSED | `map_availability_state.dart:33-34` `isFreeBeneathRoutes` includes `!isTeleportMode` | `map_availability_cubit_test.dart:100-120` (teleport mode makes the map not free) |
| T-10-18 | EoP | `InnkeeperSection` | T | CLOSED | Transferred to BE, see log; gate `innkeeper_section.dart` `BlocSelector(isInnkeeperSession)`; FORBIDDEN pops (`innkeeper_panel_screen.dart:50`) | `innkeeper_section_test.dart:88,97,106,112`; `innkeeper_panel_route_test.dart:173` |
| T-10-19 | EoP | role liveness | A | CLOSED | Accepted, see log. Section follows the session role live; panel pops silently on a lost role and with a SnackBar on FORBIDDEN | `innkeeper_section_test.dart:112`; `innkeeper_panel_route_test.dart:173,193` |
| T-10-20 | DoS | panel route | M | CLOSED | `innkeeper_panel_route.dart:22-34` cubit created by the route, closed with it; `auth_gate.dart:38` `popUntil(isFirst)` at session end | `innkeeper_panel_route_test.dart:160` "popping the panel cancels the queue subscription" |
| T-10-21 | Info disc. | cards | M | CLOSED | `pending_request_fragment.dart` selects name/state fields only; `request_card_view.dart` renders quest, rows, «Completa» | `innkeeper_panel_screen_test.dart:201` "a card shows only the quest, the rows and «Completa» (D-08)" |
| T-10-22 | Tampering | `submit` | M | CLOSED | `request_completion_cubit.dart:74-75` `isSubmitting` guard | `request_completion_cubit_test.dart:328` "a second submit while in flight is ignored"; `request_completion_screen_test.dart:217` |
| T-10-23 | Tampering | double completion | T | CLOSED | Transferred to BE single transaction, see log; FE: `notFound` -> `CompletionGone` (`request_completion_screen.dart:87`) | `request_completion_screen_test.dart:451`; `innkeeper_panel_screen_test.dart:433` |
| T-10-24 | Tampering | overrides | M | CLOSED | Clamps (T-10-03); BE `OUTCOME_OVERRIDE_INVALID` kept as form failure (`innkeeper_failure.dart:57`, `request_completion_screen.dart:210`) | `request_completion_screen_test.dart:283`; `innkeeper_failure_test.dart:25` |
| T-10-25 | Repudiation | admin writes | T | CLOSED | Transferred to BE audit interceptor (ADMIN-08), see log | device proof deferred to 10-11 (T-10-42) |
| T-10-26 | Tampering | «Completa» | M | CLOSED | Form + `showDestructiveConfirmation` with the recap (`request_completion_screen.dart:194`), `barrierDismissible: false` (`destructive_confirmation_dialog.dart:63`) | `request_completion_screen_test.dart:174,194,206` |
| T-10-27 | Tampering | enabling | M | CLOSED | Button enabled by `canComplete(serverNow)` only; BE `QUEST_IN_PROGRESS` mapped (`CompletionBusy`, `request_completion_screen.dart:88`) | `innkeeper_panel_screen_test.dart:313,319,327,448` |
| T-10-28 | Info disc. | error UI | M | CLOSED | grep `OperationException\|\.message` over `lib/screens/innkeeper`, teleport map files = 0; fixed copy `request_completion_screen.dart:205-215`, `teleport_mode_chip.dart:9-15` | `request_completion_screen_test.dart:329-345` (generic text), `teleport_mode_chip_test.dart:11-29` |
| T-10-29 | EoP | revoked role | T | CLOSED | Transferred to BE `FORBIDDEN`, see log; FE `CompletionForbidden` -> `closeInnkeeperPanel` (`innkeeper_panel_screen.dart:107`) | `request_completion_screen_test.dart:395,451`; `innkeeper_panel_screen_test.dart:469` |
| T-10-30 | Tampering | drag extraction | M | CLOSED | `pawn_dragging.dart` shared by both pawns; Phase 7 tests untouched | `character_marker_layer_test.dart`, `world_map_travel_test.dart` (green in the 488-test run) |
| T-10-31 | Tampering | drop geometry | M | CLOSED | Layer-level conversion in `teleport_pawn_layer.dart`/`pawn_dragging.dart` | `teleport_pawn_layer_test.dart:126` "releasing east resolves the nearest city" |
| T-10-32 | Info disc. | chip | M | CLOSED | `teleport_mode_chip.dart:9-15` per-code Italian copy | `teleport_mode_chip_test.dart:11-29,111` |
| T-10-33 | Tampering | `WorldMap` drag routing | M | CLOSED | `world_map.dart:240-300` teleport mode builds `_teleportLayers` (no `CharacterMarkerLayer`); drop -> `teleportTo` only (`:486-490`) | `world_map_teleport_test.dart:163,219` (`verifyNever(travelCubit.preview)`) |
| T-10-34 | DoS (UX) | availability flag | M | CLOSED | `world_map.dart:153-157` `teleportModeChanged(false)` in `dispose`; `:389-391` on transitions | `world_map_teleport_test.dart:247,263,284` |
| T-10-35 | Tampering | lore tap | M | CLOSED | `_teleportLayers` builds `CityMarkersLayer` without `onCityTap` | `world_map_teleport_test.dart:185` "a city in teleport mode opens no lore" |
| T-10-36 | EoP | teleport mode | M | CLOSED | `teleport_mode_landing.dart:46-52` cancel on lost role; `main_screen.dart:219-221` cancel when `page != worldMapPageIndex` | `teleport_mode_landing_test.dart:192,201`; `main_screen_test.dart:519,529` |
| T-10-37 | DoS | re-push loop | M | CLOSED | `teleport_mode_landing.dart:38-42,63-66` `listenWhen` on the transition, `acknowledgeSuccess()` before `openInnkeeperPanel` | `teleport_mode_landing_test.dart:168,179` |
| T-10-38 | DoS (UX) | notification tap | A | CLOSED | Accepted, see log | - |

## Deferred to Plan 10-11 (gated by the BE Phase 10 PR)

DEFERRED. Not counted as OPEN, not blocking.

| Threat | Cat. | Component | Disp | Status | What closes it |
|--------|------|-----------|------|--------|----------------|
| T-10-39 | DoS | `pendingQuest` selection | M | DEFERRED | BE gate (`awk` on `PendingRequestCharacter`), schema check 42/42 after the change. Interim verified: no `pendingQuest` selection in the queue fragment; the parser already tolerates its absence (`pending_request_test.dart:30`). |
| T-10-40 | Info disc. | E2E session secrets | M | DEFERRED | No command reads `.env`; UAT notes without ids/tokens (to verify when 10-11 runs). |
| T-10-41 | EoP | role guard on device | T | DEFERRED | BE `@Roles(innkeeper)`; proven by the FORBIDDEN-as-adventurer step. FE half closed under T-10-18/T-10-29. |
| T-10-42 | Repudiation | audit / traceability | M | DEFERRED | `admin_audit_logs` read on device; requirements ticked only for passed steps. |
| T-10-43 | Tampering | BE working tree | M | DEFERRED | BE via `fetch`/`show`/`ls-tree` only. Observed in this audit: no BE path in `git diff --name-only develop...HEAD`. |

## Accepted Risks Log

| Threat | Risk | Rationale | Bound |
|--------|------|-----------|-------|
| T-10-19 | A stale JWT role (after a promotion/demotion) can leave the Locanda visible or hidden wrongly (C8). | BE concern (HARDEN-02, Phase 12). FE hides on `userUpdated`, pops on `FORBIDDEN` with a veto-able SnackBar; the BE refuses every call regardless. UAT re-logs in after a promotion. | `innkeeper_section_test.dart:112`, `innkeeper_panel_route_test.dart:173,193` |
| T-10-38 | A notification tap pops the panel mid-flow (same rule as every root route, research P12). | Cosmetic; the GM reopens from Settings; no data loss, the BE holds the state. | - |

## Transferred Risks

| Threat | Transferred to | Documentation |
|--------|----------------|---------------|
| T-10-07 | BE `@Roles(innkeeper)` + audit (BE Phases 3/8/9) on `pendingRequests`, `completePendingRequest`, `teleportCharacter` | `BACKEND-NOTES.md`; FE maps `FORBIDDEN` to `InnkeeperFailure.forbidden`, shows fixed copy; device proof in 10-11 |
| T-10-16 | BE `@Roles(innkeeper)` on `teleportCharacter` (BE 08 §7) | FE ends the mode on `forbidden` (`teleport_mode_cubit.dart:96-103`) |
| T-10-18 | BE `@Roles(innkeeper)`: a forged client gate gets `FORBIDDEN` | The gate is UX only (`innkeeper_access.dart`); panel pops on FORBIDDEN |
| T-10-23 | BE single transaction: the second completer gets `NOT_FOUND` | FE removes the card and refetches (`CompletionGone`) |
| T-10-25 | BE audit interceptor on `completePendingRequest` (ADMIN-08) | Verified on device in 10-11 (T-10-42) |
| T-10-29 | BE `FORBIDDEN` after a demotion | FE closes the panel (`CompletionForbidden`) |

## Unregistered Flags

None. `10-05`, `10-07`, `10-08`, `10-09` SUMMARYs carry a `## Threat Flags` section; all report "None" and name registered ids. The other SUMMARYs have no such section.

## Observations (no threat id)

- O-1: until 10-11 the queue fragment does not select `pendingQuest`, so `isBusy` is false for every entry and a busy lane is not hidden client-side. The BE refuses with `QUEST_IN_PROGRESS`, which is mapped to `CompletionBusy` (T-10-27). Known, by design (gate on the BE PR).
- O-2: logging in the phase diff is one `debugPrint` with a count (`graphql.dart:245`). `graphql.dart:320` prints a quest id on a skipped quest: pre-existing, id only, not part of Phase 10. `character_fragment.dart` still selects `pointsSpent` on the player's own character: pre-existing, outside the phase diff and outside the queue fragment.
- O-3: `TeleportModeCubit.cancel()` is ignored while a teleport is in flight (by design, so the outcome, including a FORBIDDEN, is still handled); a lost role is therefore handled at the response, not before it.
- O-4: no new permission, plugin, asset or network host: the phase diff touches no `pubspec.yaml`, `android/` or `ios/` file.
- O-5: no document is string-built; the four new documents are constants registered in the schema check.

## Audit Trail

| Date | Event |
|------|-------|
| 2026-10-29 | Audit of plans 10-01..10-10 at HEAD `e644ace` (code review fixes included): 38 threats verified (30 mitigate, 2 accept, 6 transfer), all CLOSED; 5 threats of plan 10-11 DEFERRED; 488 targeted tests green over 36 files; no unregistered flags; `.env` untracked and not read; BE repo untouched; queue fragment has no `pendingQuest`. |
