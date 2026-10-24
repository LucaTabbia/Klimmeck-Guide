---
phase: 07
slug: travel
audited: 2026-10-24
status: secured
asvs_level: 1
block_on: high
threats_total: 58
threats_mitigated: 54
threats_accepted: 2
threats_transferred: 2
threats_open: 0
threats_open_blocking: 0
open_ids: []
---

# Phase 07 - Security (Travel, FE)

Audit of the `<threat_model>` blocks of plans 07-01..07-11 against HEAD 273e7fa of `feat/07-travel` (after the review fixes WR-01, WR-02, WR-03, IN-04, IN-05, IN-06). Evidence is the final code. Runs of this audit: `flutter analyze` = 54 issues, 0 errors (baseline, none in travel files); targeted suite (`test/models/travel`, `wire_lat_lng`, `models/character`, `travel_request`, `travel_failure`, `travel_repository`, `graphql_travel`, `services/time`, `test/screens/mainScreen`, `authenticated_shell`, `test/graphql`, `test/tool`) = 596 passed, 0 failed (the fixer ran the full suite: 1671 green). Schema check re-run for this audit: `git show origin/develop:src/schema.gql` (BE working tree untouched) + `dump_documents.dart` = 32 documents, 32 `OK`, 0 failures. `.env` untracked (`git ls-files` shows only `.env.example`); no command of this audit read it.

Disposition: M = mitigate (verified in code + test), A = accept (logged below), T = transfer (BE, documented below).

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| client -> GraphQL `travelPreview` / `startTravel` | Owner-only on the BE (`FORBIDDEN` even for the innkeeper). The client sends only the session character id and a city marker id from loaded data, as typed variables. Rejections are mapped by `extensions.code` only; the player sees fixed Italian copy, never server text. |
| BE snapshot -> renderer | `activeTravel` may be malformed, a polyline empty or 1 point, `duration` 0, `endTime` in the past. Parsing is tolerant at the boundary and the renderer never divides by zero or indexes an empty list. |
| device clock -> progress | Position and ETA derive from the server offset only; an unsynced clock decides no arrival and no reread (WR-03). Arrival and the snap are BE events (`characterUpdated`). |
| push payload -> camera | `travelEnd` ignores `intent.id` and only recentres on the own pawn; no navigation beyond the Map tab, no popup. |
| permission prompt | Asked only after `startTravel` answered `successful: true`, unawaited, errors swallowed; the sole call site in `lib` is `travel_repository.dart:51`. |
| FE documents <-> BE schema | 32/32 documents validate against `origin/develop` (re-run in this audit). |

## Threat Verification

| Threat | Cat. | Sev. | Disp | Status | Evidence (file:line) | Test |
|--------|------|------|------|--------|----------------------|------|
| T-07-01-01 | DoS | high | M | closed | `active_travel.dart:33-40` `tryFromJson` (non-map -> null, `on Object` -> null); `character_status.dart:61` uses it; `wire_lat_lng.dart:18-25` `tryLatLngFromWire` drops bad and out-of-range points; `travel_path.dart:17` | `active_travel_test.dart`, `wire_lat_lng_test.dart`, `character_status_test.dart` malformed case |
| T-07-01-02 | Tampering | low | M | closed | `character_status.dart:78-101` `copyWith` has no `activeTravel` parameter (carries the existing value); field comes only from `fromJson` (`:61`) | `character_status_test.dart` copyWith case |
| T-07-01-03 | Info disc. | low | M | closed | `character_fragment.dart` selects `activeTravel { road startTime endTime duration to }` and no `pet` (grep empty) | `character_fragment_test.dart` no-`pet` assertion |
| T-07-01-04 | Tampering | med | M | closed | single helper `wire_lat_lng.dart:11,18` for POI (`latLngFromWire`) and polylines (`travel_path.dart:17`) | `travel_path_test.dart` C1; device probe = UAT step 1 (pending, see Notes) |
| T-07-01-05 | Repudiation | low | M | closed | dated amendments in `REQUIREMENTS.md:234` footer (Phase 7 discuss: TRAVEL-02/03, no travel cost) | doc review |
| T-07-02-01 | DoS | high | M | closed | `travel_route.dart:98` `durationMs <= 0 -> 1`; `:36-37` empty -> null, zero length -> first point; `:14` duplicates collapsed; `:48,:45` `splitAt` empty-safe | `travel_route_test.dart` empty / one point / duration 0 |
| T-07-02-02 | Tampering | med | M | closed | `travel_route.dart:93-101` `travelProgress(serverNow:)` never reads the device clock; `grep DateTime.now` in `lib/models/travel`, `tabs/map`, `travelCubit`, `travel_repository.dart` = 0 matches | `travel_route_test.dart` server time; `travel_progress_cubit_test.dart` "only the server time moves the pawn" |
| T-07-02-03 | Spoofing | low | M | closed | `travel_destination.dart:13` same marker -> null; `world_map.dart:302-306` returns without preview | `travel_destination_test.dart` |
| T-07-02-04 | Info disc. | low | A | closed | logged below; `travel_time_format.dart` carries only durations, distances, clock times | - |
| T-07-03-01 | Tampering | med | M | closed | `server_clock_service.dart:33,50` offset = serverTime - RTT midpoint; `:18` resync on every `foregrounded`; wired `authenticated_shell.dart:163-173` | `server_clock_service_test.dart` device clock |
| T-07-03-02 | DoS | med | M | closed | `server_clock_service.dart:21,47` 10 s timeout; `:41-42` single flight; `:53-55` never throws, no retry loop | timeout / single-flight / failure tests |
| T-07-03-03 | Info disc. | med | M | closed | `travel_failure.dart:49-65` switch on `graphQlErrorCode` only; `travel_notice.dart:8-28` fixed copy, no code tokens; `toString` prints enum name (`:45`) | `travel_failure_test.dart` message ignored; `travel_notice_test.dart` |
| T-07-03-04 | Spoofing | low | M | closed | `travel_notice.dart:25` `unauthenticated -> null` (`:27` no notice) | `travel_notice_test.dart` |
| T-07-03-05 | Repudiation | low | M | closed | `travel_failure.dart:6` single `travelInProgressCode`; quest catalogue imports it (`grep`) | grep criterion |
| T-07-04-01 | EoP | med | M | closed | `satchel_availability.dart:10-16` `isTravelling` disables Board/Shop; `main_screen.dart:200,210-222` same guard in `onItemTap`; `:91-99` selector | `satchel_availability_test.dart`, `main_screen_test.dart` travelling case |
| T-07-04-02 | Tampering | low | M | closed | `notification_popup_registry.dart:13-19` `travelEnd -> requestCharacterFocus()` ignores `intent.id` | `notification_intent_landing_test.dart` (real registry) |
| T-07-04-03 | DoS | med | M | closed | `map_focus_cubit.dart:14-22` latched request; `world_map.dart:249-254` consumed only when `_isMapReady` | `map_focus_cubit_test.dart`, `world_map_travel_test.dart` |
| T-07-04-04 | EoP | low | T | closed | transferred to BE Phase 9 D-18 (`SHOP_NOT_IN_CITY`); FE request recorded in `BACKEND-NOTES.md:19`; FE filters first | `satchel_availability_test.dart` |
| T-07-05-01 | EoP | med | T | closed | BE owner-only (`FORBIDDEN`, BE BACKEND-NOTES §2/§3 step 1); FE sends `TravelRequest(id: characterId, poiId)` with `characterId` = session id (`travel_cubit.dart:77`, `world_map.dart:308`) and `$request: TravelRequest!` typed variable (`travel_mutations.dart`, `graphql.dart:504-505`) | `graphql_travel_test.dart` variables |
| T-07-05-02 | Tampering | med | M | closed | `graphql.dart:512-515` non-bool -> `FormatException`; `travel_repository.dart:45` `successful: false` -> `TravelFailure.declined` (IN-06); no position set from the answer | `graphql_travel_test.dart`, `travel_repository_test.dart` |
| T-07-05-03 | Info disc. | med | M | closed | `travel_repository.dart:58-67` `_guard` wraps `OperationException`, `TimeoutException`, any `Object`; `graphql.dart:570-578` malformed preview -> `FormatException` with `runtimeType` only | `travel_repository_test.dart` |
| T-07-05-04 | DoS | med | M | closed | `travel_repository.dart:25,60` 15 s timeout -> `timedOut` | `travel_repository_test.dart` fake_async |
| T-07-05-05 | Spoofing | med | M | closed | `travel_repository.dart:45-46,49-56` gate after a confirmed start, `unawaited`, `onError` swallowed; only call site of `ensureRequested` in `lib` | `travel_repository_test.dart` gate cases |
| T-07-05-06 | DoS | high | M | closed | registry 32 (`schema_check_documents.dart`); schema check re-run in this audit: 32/32 OK against `origin/develop` | `schema_check_documents_test.dart` (in the 596 green) |
| T-07-06-01 | Tampering | high | M | closed | `travel_progress_cubit.dart:50-56,67-73` only `follow(null)` returns to idle; `_isSettled` (`:93-95`) stops the timer, never completes the travel | "after endTime the pawn holds the last point with no snap" |
| T-07-06-02 | DoS | high | M | closed | `:37-40,93-95,137-140` two delays, timer stops at count 2 and arriving; `arrival_reread_ledger.dart:12-20` session cap (WR-02); `world_map.dart:233-237` | "asks for two silent rereads at most, then stops ticking", "an endTime days in the past settles with no timer", ledger tests ("remounted map", "backward resync") |
| T-07-06-03 | DoS | high | M | closed | `travel_progress_cubit.dart:123` `pointAt` null for empty; `travel_route.dart:98` duration <= 0 | "an empty polyline has no position", "a zero duration is arriving immediately" |
| T-07-06-04 | Tampering | med | M | closed | `travel_progress_cubit.dart:112` `_clock.now()` only; grep `DateTime.now` = 0 | "only the server time moves the pawn, never the device clock" |
| T-07-06-05 | DoS | low | M | closed | `:67-73` `_stopFollowing`, `:143-147` `close()` cancel timer and `_offsetSubscription`; `world_map.dart:129` closed in `dispose` | "follow(null) mid-travel cancels the timer", "close() mid-travel cancels the timer" |
| T-07-06-06 | Tampering | med | M | closed | `:28,75-80` every `offsetChanges` recomputes; `:127-128` `isArriving` and rereads only when `isSynced` (WR-03) | "a resync corrects a stale unsynced offset", "an unsynced clock decides no arrival and no reread (WR-03)" |
| T-07-07-01 | Tampering | med | M | closed | `travel_cubit.dart:70-73` `start()` only from `TravelConfirming`, moves to `TravelStarting` before the await; sheet "Parti" enabled only in `TravelConfirming` (`travel_confirmation_sheet.dart:160`) | "a double 'Parti' sends one request" |
| T-07-07-02 | Spoofing | low | M | closed | `travel_cubit.dart:42,53,61,93-97,113-114` `_previewToken` + state check | "a late successful/failed preview after cancel is ignored", "the token drops the answer of a replaced equal request" |
| T-07-07-03 | Info disc. | med | M | closed | `travel_outcome_listener.dart:45-52` `travelNoticeFor(failure)`, dedup key `travel|failure.name|destination.id` | `travel_outcome_listener_test.dart` |
| T-07-07-04 | Tampering | med | M | closed | `travel_state.dart` `TravelStarted` carries destination and preview, no position; `travel_outcome_listener.dart:25-29,54-57` settles only on `activeTravel` from `CharacterCubit` | listener settle tests |
| T-07-07-05 | DoS | low | M | closed | `travel_cubit.dart:30,140-145` 30 s hold back to idle | "returns to idle by itself after the default hold", "close cancels the hold timer" |
| T-07-07-06 | EoP | low | M | closed | `authenticated_shell.dart:162-186` cubit, clock (`dispose: clock.dispose`) and ledger scoped to the shell, which is built per session (`main.dart:334`); `SafeEmit` + `isClosed` guard (`travel_cubit.dart:80`) | `authenticated_shell_test.dart` "provides the travel cubit and closes it on removal"; "drops a late start answer after close" |
| T-07-08-01 | DoS | med | M | closed | `travel_route_layer.dart:34,43-47,75-76` < 2 points not drawn, empty -> `SizedBox.shrink` | `travel_route_layer_test.dart` degenerate cases |
| T-07-08-02 | Tampering | med | M | closed | `travel_confirmation_sheet.dart:157-162` "Parti" enabled only in `TravelConfirming`; WR-01 `:61-64` `PopScope(canPop: !TravelStarting)`, "Resta" disabled in `TravelStarting` (`:150`), `world_map.dart:328,337-338` stops sheet drag-dismiss while starting | `travel_confirmation_sheet_test.dart` incl. WR-01 cases, `world_map_travel_test.dart` |
| T-07-08-03 | Info disc. | low | M | closed | sheet renders destination name/image and formatted numbers only (`:75-109`); no error text | sheet tests |
| T-07-08-04 | EoP | low | M | closed | grep of `KlimmeckGraphQl|TravelRepository|ServerClockService` in `travel_confirmation_sheet.dart` and `travel_route_layer.dart` = 0 matches; both read `TravelCubit`/`TravelProgressCubit` states | grep (this audit) |
| T-07-08-05 | DoS | low | M | closed | `travel_confirmation_sheet.dart:25,129` placeholder `…` inside the sheet, no overlay/spinner | previewing test |
| T-07-09-01 | Tampering | med | M | closed | `grep changeCharacterLocation lib test` = 0 matches; `world_map.dart:298-311` drag end only previews | drag tests in `world_map_travel_test.dart` |
| T-07-09-02 | DoS | high | M | closed | `world_map.dart:241-254` `_isMapReady` set by `onMapReady`, focus/move only after; `:343` fit guarded | focus-before-mount test |
| T-07-09-03 | DoS | med | M | closed | `world_map.dart:157-162` listener fires only when `arrivalRefetchCount` increases; `:233-237` ledger claim | refetch count tests |
| T-07-09-04 | DoS | low | M | closed | `world_map.dart:129` `_progressCubit.close()` in `dispose` | "no pending timer" test |
| T-07-09-05 | Spoofing | low | M | closed | `world_map.dart:302-306` `travelDestinationFor` | same-city drag test |
| T-07-09-06 | EoP | low | M | closed | `world_map.dart:325-326` `BlocProvider.value(value: travelCubit)` in the sheet builder | sheet test |
| T-07-10-01 | Tampering | med | M | closed | `character_marker_layer.dart:56-57,89-117` travelling pawn at `progress.position`; destination shown only for `TravelPreviewing/Confirming/Starting` (`:133-138`) | snap test, `TravelStarted` test |
| T-07-10-02 | EoP | low | M | closed | `character_marker_layer.dart:126-129,159` `maxSimultaneousDrags: 0` unless no `activeTravel`, no `pendingQuest`, `TravelIdle`; BE judges | blocked-mode tests |
| T-07-10-03 | DoS | med | M | closed | `character_marker_layer.dart:93-94` `position ?? status.location` | position-null test |
| T-07-10-04 | Repudiation | low | M | closed | pawn derived from states (`character_marker_layer.dart:52-64`), no reset listeners | "unrelated" test |
| T-07-10-05 | Info disc. | low | A | closed | logged below; `character_marker_layer.dart:119-122` label is a formatted duration or `In arrivo...` | label tests |
| T-07-11-01 | DoS | high | M | closed | schema check 32/32 OK against `origin/develop` (recorded in `07-VERIFICATION.md:63`, re-run in this audit) | schema-check output |
| T-07-11-02 | Info disc. | high | M | closed | `.env` untracked; no phase file reads or prints it (grep of `lib`, `.planning/phases/07-travel` for token/`.env` reads); `07-HUMAN-UAT.md:12` states hand calls stay in the user's client, no token or real-user id recorded; this audit read no `.env` | execution notes |
| T-07-11-03 | Tampering | med | M | closed | unit coverage in 07-02/07-03/07-06 (T-07-02-02, T-07-03-01, T-07-06-04); device proof = UAT step 4 pending (see Notes) | unit tests above |
| T-07-11-04 | Spoofing | med | M | closed | code: prompt only after `successful: true` (T-07-05-05); device proof = UAT step 3 pending (see Notes) | `travel_repository_test.dart` gate cases |
| T-07-11-05 | Repudiation | low | M | closed | `REQUIREMENTS.md:107-113` TRAVEL-01..04 still `[ ]`, traceability row `Pending` (`:219`); `07-HUMAN-UAT.md` all steps `pending`, `status: in-progress`: nothing ticked without proof | doc review |
| T-07-11-06 | Tampering | low | M | closed | BE accessed only with `git show origin/develop:...` and read of the BE notes in this audit; `git status` of the FE tree clean; schema check used the scratchpad | execution notes |

## Key properties confirmed

- The client never starts, completes or moves a travel by itself: `startTravel` returns `successful` only; `activeTravel` enters the app only via `CharacterStatus.fromJson` (`characterUpdated`), `copyWith` cannot set it; `changeCharacterLocation` is gone; the snap is `follow(null)` on the BE event.
- Time is the server's: `DateTime.now` does not appear in `models/travel`, `tabs/map`, `travelCubit`, `travel_repository.dart`; the only device clock read is inside `ServerClockService`, corrected by the measured offset. On an unsynced clock the pawn advances but nothing is decided (no arrival, no reread, no ETA).
- Errors are mapped by `extensions.code` only; the player sees fixed copy; `TravelException.toString` prints the enum name; the repository wraps every throwable.
- Hostile snapshots cannot crash the map: malformed `activeTravel` -> no travel; bad/out-of-range points dropped; empty route, one point, `duration` 0, `endTime` days ago all covered by tests and by a bounded refetch (2 per travel, session ledger).
- Double-fire is blocked at three layers: `start()` only from `TravelConfirming`, "Parti" disabled otherwise, BE conditional write (`TRAVEL_IN_PROGRESS`). The sheet cannot be dismissed while the start is in flight (WR-01).
- Authorisation: owner-only is a BE rule (transferred); the FE sends only the session character id, never a user-typed id. Board/Shop are disabled off a city and while travelling in both the menu render and `onItemTap`; the pawn drag is disabled during travel, a pending quest and an open flow.
- No new logging: the only `print` in the area is the pre-existing `world_map_cubit.dart:24` (lore load, unchanged by this branch, prints a lore error, no secret).

## Accepted risks log

| Threat | Rationale |
|--------|-----------|
| T-07-02-04 | Travel strings contain only durations, distances and clock times; no ids and no server text. |
| T-07-10-05 | The pawn label shows only a formatted remaining duration or `In arrivo...`; no ids and no server text. |

## Transfers

| Threat | Transferred to | Documentation |
|--------|----------------|---------------|
| T-07-04-04 | BE Phase 9 D-18 | `SHOP_NOT_IN_CITY` on `doTransaction`; request logged in `.planning/phases/07-travel/BACKEND-NOTES.md:19`, accepted in the BE Phase 9 discuss. Until it ships the FE is the only filter (a client bypass reaches the BE shop from any place). Low severity, tracked as a BE follow-up. |
| T-07-05-01 | BE owner-only guard | `FORBIDDEN` for `startTravel`/`travelPreview` on a character that is not the caller's `currentCharacter`, even for the innkeeper (BE BACKEND-NOTES §2 and §3 step 1); the FE sends the session character id as a typed variable. |

## Unregistered flags

None. `## Threat Flags` of 07-01..07-10 SUMMARY files (07-02, 07-03, 07-04, 07-01, 07-06, 07-07, 07-05 checked explicitly) state no new surface; every flagged item maps to a registered threat id. Plan 07-11 has no SUMMARY yet.

## Notes (informational, non-blocking)

- Plan 07-11 Task 2 and 3 (12-step device UAT) are not executed: `07-HUMAN-UAT.md` is `in-progress` with all steps `pending`; `07-VERIFICATION.md` is `human_needed`. T-07-01-04 (visual C1 probe, step 1), T-07-11-03 (clock change, step 4) and T-07-11-04 (prompt timing, step 3) are closed on code and unit evidence; the device confirmation is still owed and none of the three is `high`. Re-open them if a UAT step fails.
- WR-02 and WR-03 are flagged "requires human verification" in `07-REVIEW-FIX.md`; the code and tests above were checked in this audit, the on-device behaviour is part of the UAT.
- While the clock is unsynced and a travel is live, the 1 s ticker keeps running (no arrival is decided, so `_isSettled` is false) until the next successful sync (resume or the first sync). It is map-scoped and cheap; the pawn keeps moving by design. No action.
- `T-07-05-02` as written says `successful: false` -> `unknown`; after IN-06 it is the dedicated `declined` failure. The property (no optimistic state, state only from `characterUpdated`) holds.
- Existing format-dirty baseline files (`world_map.dart`, `map_constants.dart`) are untouched by this audit; the `print` in `world_map_cubit.dart:24` is a pre-existing Boy Scout candidate outside this phase.

## Audit Trail

| Date | Auditor | Result |
|------|---------|--------|
| 2026-10-24 | gsd-security-auditor | 58/58 threats closed (54 mitigated, 2 accepted, 2 transferred), 0 open, 0 open blocking |
