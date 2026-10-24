---
phase: 07-travel
reviewed: 2026-10-24T12:00:00Z
depth: standard
files_reviewed: 74
files_reviewed_list:
  - docs/rules/ui-ux.md
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/mutations/travel_mutations.dart
  - lib/graphql/queries/city_queries.dart
  - lib/graphql/queries/server_time_queries.dart
  - lib/graphql/queries/travel_queries.dart
  - lib/models/character/character_status.dart
  - lib/models/point_of_interest.dart
  - lib/models/request/travel_request.dart
  - lib/models/travel/active_travel.dart
  - lib/models/travel/travel_destination.dart
  - lib/models/travel/travel_path.dart
  - lib/models/travel/travel_preview.dart
  - lib/models/travel/travel_route.dart
  - lib/models/travel/travel_time_format.dart
  - lib/models/wire_lat_lng.dart
  - lib/repository/quest_acceptance_failure.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/time/server_clock_service.dart
  - lib/repository/travel_failure.dart
  - lib/repository/travel_repository.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/characterCubit/character_cubit.dart
  - lib/screens/mainScreen/components/notification_popup_registry.dart
  - lib/screens/mainScreen/components/satchel_availability.dart
  - lib/screens/mainScreen/components/satchel_layout.dart
  - lib/screens/mainScreen/components/travel_outcome_listener.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
  - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
  - lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart
  - lib/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart
  - lib/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_state.dart
  - lib/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart
  - lib/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_state.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/travelCubit/travel_cubit.dart
  - lib/screens/mainScreen/travelCubit/travel_notice.dart
  - lib/screens/mainScreen/travelCubit/travel_state.dart
  - test/graphql/character_fragment_test.dart
  - test/graphql/travel_documents_test.dart
  - test/helpers/fakes/fake_server_clock_service.dart
  - test/helpers/fixtures/travel_fixtures.dart
  - test/helpers/map_harness.dart
  - test/helpers/mocks.dart
  - test/models/character/character_status_test.dart
  - test/models/point_of_interest_test.dart
  - test/models/request/travel_request_test.dart
  - test/models/travel/active_travel_test.dart
  - test/models/travel/travel_destination_test.dart
  - test/models/travel/travel_path_test.dart
  - test/models/travel/travel_preview_test.dart
  - test/models/travel/travel_route_test.dart
  - test/models/travel/travel_time_format_test.dart
  - test/models/wire_lat_lng_test.dart
  - test/repository/services/graphql/graphql_travel_test.dart
  - test/repository/services/push/push_boundaries_test.dart
  - test/repository/services/time/server_clock_service_test.dart
  - test/repository/travel_failure_test.dart
  - test/repository/travel_repository_test.dart
  - test/screens/auth/authenticated_shell_test.dart
  - test/screens/mainScreen/components/notification_intent_landing_test.dart
  - test/screens/mainScreen/components/satchel_availability_test.dart
  - test/screens/mainScreen/components/travel_outcome_listener_test.dart
  - test/screens/mainScreen/main_screen_test.dart
  - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
  - test/screens/mainScreen/tabs/map/map_focus_cubit_test.dart
  - test/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit_test.dart
  - test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart
  - test/screens/mainScreen/tabs/map/travel_route_layer_test.dart
  - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
  - test/screens/mainScreen/travelCubit/travel_cubit_test.dart
  - test/screens/mainScreen/travelCubit/travel_notice_test.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-10-24T12:00:00Z
**Depth:** standard
**Files Reviewed:** 74
**Status:** issues_found

## Summary

All `lib/` files (and `tool/`, `docs/`) were read in full; `test/` was checked at standard depth (timers, fakes, mocks, vacuous patterns). Server authority is respected: no client-side ETA from distance/speed, completion only through `follow(null)`, `startTravel` never builds state from `CommonResponse`, `DateTime.now` appears only as the injectable default of `ServerClockService`. Lifecycle handling (preview token, 30 s hold, `close()`, single-flight sync, latch consumed once) is sound. No critical issues. Three warnings: a misleading "Resta" while `startTravel` is in flight, the "at most 2 rereads per travel" cap that is not really a cap, and refetch/ETA computed on an unsynced clock.

Limitation: the BE repo path in the brief (`.../Klimmeck-Guide-BE/Klimmeck-Guide-BE`) does not exist on this machine, so BACKEND-NOTES and `schema.gql` could not be cross-checked here; the `schema_check` documents are the only schema guard.

## Warnings

### WR-01: "Resta" stays active while `startTravel` is in flight

**File:** `lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart:134-137`
**Issue:** In `TravelStarting` the "Resta" button is still enabled; `cancel()` is a no-op there (only Previewing/Confirming), but `maybePop()` closes the sheet. The user believes the trip was cancelled while the request is in flight and the pawn then starts travelling. The transparent barrier (`world_map.dart:313`) also lets a map tap dismiss the sheet in the same state.
**Fix:** disable "Resta" while `state is TravelStarting` (`onPressed: state is TravelStarting ? null : ...`) and block barrier/back dismissal in that state (`PopScope(canPop: state is! TravelStarting)`).

### WR-02: Reread cap of 2 per travel is not enforced across remounts and clock changes

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:76-81, 154-159`; `travelProgressCubit/travel_progress_cubit.dart:122-125`
**Issue:** `arrivalRefetchCount` is recomputed from the clock on every snapshot and `_initializeTravelProgress` issues an extra `refreshCharacter()` whenever the count is already above 0 at mount. `WorldMap` is not kept alive (only `MainScreen` has `AutomaticKeepAliveClientMixin`), so each return to the map tab during the "arriving" window adds one reread; a backwards `offsetChanges` resync lowers the count and it re-crosses the thresholds, firing again. The documented cap (max 2 per travel) can be exceeded.
**Fix:** keep the fired-count in a longer-lived place (e.g. a `Set<int>` of fired thresholds keyed by `(startTime, endTime)` in the cubit owned by the shell) and have mount-time handling consume the same set; or make the count monotonic (`max(previous, computed)`).

### WR-03: Refetch and ETA can be driven by an unsynced (device) clock

**File:** `travelProgressCubit/travel_progress_cubit.dart:95-125`; `travelCubit/travel_cubit.dart:109-117`; `lib/repository/services/time/server_clock_service.dart:33`
**Issue:** Before the first successful sync `ServerClockService.now()` is the device clock (offset zero). `_snapshot` then computes `arrivalRefetchCount` and `isArriving` on it, so a device clock ahead of the server fires the 5 s / 65 s rereads early and shows "In arrivo…" early (corrected only at the next sync); `_confirmingFrom` computes the ETA the same way even if `isSynced` is false, and offers no resync attempt. Progress is corrected by `offsetChanges`, but the rereads already consumed their slot.
**Fix:** in `_refetchCountAt` return 0 while `!_clock.isSynced`; in `TravelCubit.preview` call `unawaited(_clock.sync())` when `!_clock.isSynced` (the next `offsetChanges` already refreshes the pawn).

## Info

### IN-01: Two coordinate helpers, different strictness

**File:** `lib/models/point_of_interest.dart:28-30`; `lib/models/wire_lat_lng.dart:7-19`; `lib/models/travel/travel_path.dart:17`
**Issue:** Order is consistent (C1 holds), but POI uses `latLngFromWire` (throws on malformed data, no range check, and `json["location"][0]` throws on an empty list) while road points use `tryLatLngFromWire` (silently dropped). A dropped middle point distorts the polyline without notice.
**Fix:** use `tryLatLngFromWire` in `PointOfInterest.fromJson` (null location) so one bad POI cannot drop the character, and guard `location is List && location.isNotEmpty`.

### IN-02: `CharacterStatus.copyWith` cannot change `activeTravel`

**File:** `lib/models/character/character_status.dart:101`
**Issue:** `activeTravel: activeTravel` always preserves the old value and the parameter is missing; harmless today, a trap for the next caller.
**Fix:** add `ActiveTravel? activeTravel` and use `activeTravel ?? this.activeTravel`, or note the intent in a comment.

### IN-03: Magic numbers in `_fitPreviewRoute`

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:330`
**Issue:** `48`, `0.5`, `24` inline (sheet takes half screen).
**Fix:** named constants in `MapConstants`.

### IN-04: `_isSameTravel` compares only start and end time

**File:** `travelProgressCubit/travel_progress_cubit.dart:91-93`
**Issue:** If the BE ever re-emits the same times with a different `road` or `to`, the cached `TravelRoute` stays stale.
**Fix:** compare `travel == _travel` (ActiveTravel is Equatable) instead.

### IN-05: Duplicated field set in `TravelConfirming` / `TravelStarting`

**File:** `travelCubit/travel_state.dart:27-62`; `travel_cubit.dart:119-124`
**Issue:** Identical four fields and copy constructor; any new field must be added in two states and in `_numbersOf`.
**Fix:** extract a shared base (`sealed class TravelQuote`) or have `TravelStarting` wrap a `TravelConfirming`.

### IN-06: `successful: false` is surfaced as the generic "unknown" banner

**File:** `lib/repository/services/graphql/graphql.dart:507-509`; `lib/repository/travel_repository.dart:64-66`
**Issue:** A `FormatException` for a non-successful `startTravel` falls into `on Object` and shows "Qualcosa è andato storto"; fine as a fallback, but it conflates malformed data with a refusal. Also `worldMap._handleCharacterDragEnd` opens the sheet even when `preview()` ignored the call (state not Idle); the post-frame guard covers only Idle/Failed.
**Fix:** acceptable as is; optionally have `preview()` return `bool` and open the sheet only on `true`.

## Verified clean

- Server authority: no ETA/duration from distance or speed; ETA = server now + BE `duration`; no completion logic; snap only on `follow(null)`; `startTravel` ignores the response body beyond `successful`.
- `DateTime.now` only as default of `ServerClockService`; offset-change path restarts the ticker (`_refresh` re-arms `_timer`), settled ticker cannot freeze.
- `TravelCubit`: `_previewToken` + `state is! TravelPreviewing` discard late answers; `cancel()` bumps the token; hold timer cancelled in `reset()`/`close()`; `SafeEmit` covers emits after close.
- `ServerClockService`: single-flight `_inFlight`, timeout, silent failure, `dispose()` cancels subscription and closes the stream, add guarded by `isClosed`.
- `TravelRoute`/`travelProgress`: 0/1 points, zero length, `duration <= 0`, past `endTime` do not throw or divide by zero; `splitAt` at 0 and 1 yields coherent segments.
- `travelFailureFrom` uses `extensions.code` only; banner copy from FE catalogue; `unauthenticated` yields no banner; permission prompt only after a successful `startTravel`, unawaited with errors swallowed.
- `MapFocusCubit` latch consumed once; `_isMapReady` gate; `travelEnd` popup only requests camera focus.
- UI rules: no AlertDialog/AppBar/SnackBar in gameplay; theme tokens only; drag disabled with `activeTravel`/pending quest/non-idle travel; Board and Shop disabled off city and during travel; `changeCharacterLocation` removed with no leftover references; `travelInProgressCode` defined once.
- Tests: `FakeServerClockService` and `mocks.dart` additions are consistent with the production API; no real `Future.delayed` or `DateTime.now()` in travel tests.

---

_Reviewed: 2026-10-24T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
