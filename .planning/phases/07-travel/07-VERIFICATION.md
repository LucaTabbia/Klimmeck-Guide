---
phase: 07-travel
verified: 2026-10-24T00:00:00Z
status: human_needed
score: 4/4 success criteria, 4/4 requirement IDs accounted for (automated); 12 device steps pending
overrides_applied: 0
re_verification: null
gaps: []
human_verification:
  - test: "UAT 1 - Preview + C1 probe (BE handoff 11 d.1, D-03/D-04, C1)"
    expected: "Drag the pawn from a city marker onto another city: the parchment sheet shows the city name (and image if the lore has one) at once, then distance (km), duration ('2 h 40 min' style) and arrival ('oggi/domani alle HH:mm'); no cost line. Behind the sheet the DASHED route starts exactly on the pawn and ends on the destination marker (if it starts elsewhere or looks mirrored, FAIL). Camera fits both ends. 'Resta': route gone, pawn back on its city."
    why_human: "Real travelPreview against the BE and the visual C1 probe (lat/lng order of road.coordinates on the map) cannot be observed without a device"
  - test: "UAT 2 - Same city (D-02)"
    expected: "Drag and release the pawn on its own city: it springs back, no sheet, no banner."
    why_human: "Gesture behaviour on device"
  - test: "UAT 3 - Start (D-05, D-06, D-08, D-12)"
    expected: "Drag again, tap 'Parti'. The notification permission prompt appears only now (only if the OS has not decided yet). The pawn leaves along the route; the travelled part has a different tone; only the remaining time floats above the pawn. Bacheca and Negozio dark and inert; Profilo, Diario, Libreria, Impostazioni open; tapping a city still opens its lore sheet; tapping the pawn does nothing."
    why_human: "Real startTravel, OS permission prompt timing, visual result"
  - test: "UAT 4 - Server time (BE 11 d.2, D-07)"
    expected: "Move the phone clock +/-2 h, return to the app: pawn at the same point of the route, remaining time unchanged (within a minute)."
    why_human: "Needs a real device clock change and the real serverTime query"
  - test: "UAT 5 - Kill mid-travel (BE 11 d.3, D-09, D-11, TRAVEL-04)"
    expected: "Swipe the app away, relaunch: after cold start the pawn is on the route at the right point, the camera frames it once, the label shows the remaining time; free panning does not snap back."
    why_human: "Real process kill and cold start"
  - test: "UAT 6 - Arrival (BE 11 d.4, D-10, D-15, D-16)"
    expected: "At the end the label reads 'In arrivo...' and the pawn waits on the last point. App in background/killed: push 'Viaggio completato'; tap opens the Map centred on the pawn, no popup. Short travel in foreground: pawn snaps to the new city and the in-app banner 'Viaggio completato' appears (tap goes to Map)."
    why_human: "Real FCM push, tap routing to camera, backend travel lifecycle"
  - test: "UAT 7 - Automatic quest travel (BE 11 d.5, D-13, D-17)"
    expected: "Accept a standard-lane quest whose marker is not the current position: Map with route, moving pawn and label like a free travel; quest paper says 'In viaggio'. At arrival the pawn snaps, the paper label switches to the per-type label, NO push and no FE banner."
    why_human: "Real BE quest-driven travel"
  - test: "UAT 8 - Rejections (BE 11 d.6, D-14)"
    expected: "Sheet open on a destination; by hand start a travel or accept a standard quest for the same character; tap 'Parti': sheet closes, pawn springs back, banner 'Sei gia in viaggio' (TRAVEL_IN_PROGRESS) or 'Non puoi partire durante una missione in corso' (QUEST_IN_PROGRESS), never technical text. Pawn not draggable during a travel nor while a standard quest is pending."
    why_human: "Needs a second client issuing mutations against the real BE"
  - test: "UAT 9 - Teleport by hand (BE 11 d.7)"
    expected: "As innkeeper, teleportCharacter on a character in a free travel: route disappears, pawn snaps to the new POI, no push; on a character with a pendingQuest the answer is QUEST_IN_PROGRESS."
    why_human: "Manual BE mutation, observed on device"
  - test: "UAT 10 - Pet (BE 11 d.8)"
    expected: "With the speedModifier: 2 pet equipped (assets.pet ObjectId) the preview duration for the same pair of cities is half of the one without the pet."
    why_human: "Backend data setup and real preview"
  - test: "UAT 11 - Board/Shop off a city (D-12)"
    expected: "With the character on a quest POI (after UAT 7), Bacheca and Negozio are dark and do nothing."
    why_human: "Needs the real post-quest location on device"
  - test: "UAT 12 - Nearest-city rule (Pitfall 10, observation only)"
    expected: "At low zoom release the pawn between cities where a village is hidden; note which city the sheet names (D-01 keeps 'nearest city'; 'Resta' is the escape). Not a pass/fail gate."
    why_human: "Subjective observation on device"
---

# Phase 7: Travel - Verification Report

**Phase Goal:** Users can initiate travel to a POI with an explicit confirmation showing backend-provided ETA, then watch their character move along the road in real time, with accurate reconstruction after an app kill mid-travel.
**Branch:** feat/07-travel @ 9e0b08f (105 files changed vs develop)
**Re-verification:** No, initial verification.

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test` (full) | 1644 passed, 0 failed ("All tests passed!") |
| `flutter analyze` | 54 issues, 0 errors (baseline matched; the sample shown is `avoid_print` in `tools/`) |
| `grep changeCharacterLocation lib test` | none (teleport stub dropped) |
| `grep DateTime.now` in `lib/models/travel`, `lib/screens/mainScreen/travelCubit`, `lib/screens/mainScreen/tabs/map` | none (all time goes through `ServerClockService`) |
| `grep package:flutter lib/models` | none (models stay Flutter-free) |
| Schema check (dump 32 documents, validate against `git show origin/develop:src/schema.gql`, BE @ 3df1b37, BE working tree untouched) | 32 documents dumped, all OK (including the three new travel operations) |
| `gsd-tools verify artifacts` on the 11 plans | all artifacts pass for every plan (01: 5/5, 02: 3/3, 03: 4/4, 04: 3/3, 05: 4/4, 06: 2/2, 07: 3/3, 08: 3/3, 09: 2/2, 10: 2/2, 11: 2/2) |
| `gsd-tools verify key-links` | Plans 10 and 11 pass as run. Plans 01 to 09 report failures that are all tool artefacts (double-escaped regexes such as `latLngFromWire\\(`, or patterns narrower than the real call). Each one was re-checked manually, see below: all WIRED. |

## Manual key-link confirmation (the tool's false negatives)

| Link | Status | Evidence |
|------|--------|----------|
| `point_of_interest.dart` -> `latLngFromWire` | WIRED | line 29 |
| `character_status.dart` -> `ActiveTravel.tryFromJson` | WIRED | line 61 (`activeTravel` field line 37) |
| `travel_time_format.dart` -> intl `DateFormat` | WIRED | lines 45, 48 (`HH:mm`, `dd/MM`) |
| `travel_failure.dart` -> `graphQlErrorCode` | WIRED | line 46 (`extensions.code` only) |
| `notification_popup_registry.dart` -> `MapFocusCubit` | WIRED | `travelEnd: focusCharacterOnMap` -> `requestCharacterFocus()` (line 19) |
| `travel_repository.dart` -> permission gate / `travelFailureFrom` | WIRED | lines 50 (`ensureRequested().then`, after success) and 61 |
| `travel_progress_cubit.dart` -> `travelProgress`, `_clock.now()`, `offsetChanges.listen` | WIRED | lines 25, 98-101, 110 |
| `travel_cubit.dart` -> `_repository.preview/start` | WIRED | lines 51, 70 |
| `travel_outcome_listener.dart` -> `publishNotice` | WIRED | line 48; mounted in `main_screen.dart` line 99 |
| `travel_confirmation_sheet.dart` -> format helpers | WIRED | lines 92-96 |
| `world_map.dart` -> `follow`, `preview` + sheet `.whenComplete(cancel)`, `consumeCharacterFocus`, `fitCamera(CameraFit.coordinates)` | WIRED | lines 78, 151, 294-319, 327, 161-162, 241-243 |
| `character_marker_layer.dart` drag gate | WIRED | draggable only when no `pendingQuest` and `TravelIdle` (lines 128-129); `onDragEnd` -> world map |

## Success criteria (ROADMAP as amended)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Explicit confirmation with destination + ETA from the backend before the mutation | VERIFIED (code and tests); device pending | `TravelCubit` preview -> confirm -> start; ETA = `now + result.duration` where `now` is the server-clock estimate (cubit line 114), no distance/speed math; `TravelConfirmationSheet` shows distance, duration, arrival, "Parti"/"Resta", no cost; `startTravel` fires only from the sheet; sheet dismissal cancels. Docs amended in 07-01 (no cost). Real preview: UAT 1, 3 |
| 2 | With `activeTravel`, character moves along `road.coordinates`, interpolated from `(now - startTime)/duration` on server timestamps | VERIFIED (code and tests); device pending | `TravelRoute` (cumulative-length interpolation), `travelProgress` pure function, `TravelProgressCubit` ticks on `ServerClockService.now()`, route memoised per `startTime`, resync on `offsetChanges`; `CharacterMarkerLayer` renders the travelling pawn with remaining-time label; `TravelRouteLayer` draws two-tone route. UAT 3, 4 |
| 3 | Backend clears `activeTravel` and updates `location`: UI snaps via subscription, no FE completion logic | VERIFIED (code); device pending | `WorldMap` follows `CharacterCubit` state through `follow(activeTravel)`; no completion/teleport code on the FE (`changeCharacterLocation` removed); arrival hold only shows "In arrivo..." and requests a silent refetch, location comes from the stream. UAT 6, 7, 9 |
| 4 | Kill mid-travel: relaunch reconstructs from `activeTravel` at the right position | VERIFIED (code and tests); device pending | Position is a pure function of `(activeTravel, serverNow)`; `TravelProgressCubit` is seeded with the current character state at creation (`world_map.dart` line 78) and the clock is synced at shell start (`authenticated_shell`, `lazy: false`); the progress waits for `isSynced` (cubit line 81). UAT 5 |

## Decisions honoured (07-CONTEXT)

D-01/D-02 (pawn drag trigger, same-city springs back): drag gate and `travelDestinationFor` in place. D-03/D-04 (parchment sheet, dashed preview route): `TravelRouteLayer` + `TravelConfirmationSheet`. D-05 (permission prompt only after success): repository gate after a successful start, unawaited. D-07 (server time offset, RTT midpoint, resync on resume): `ServerClockService`. D-12 (Board/Shop city-only and not while travelling): 07-04 wiring in `main_screen`/`satchel_availability`. D-14 (failures by `extensions.code`): `travel_failure.dart`, `TravelOutcomeListener`. D-15 (travelEnd centres camera, no popup): registry entry + `MapFocusCubit`. C1 (wire lat/lng order helper): `wire_lat_lng.dart` shared by POI and travel path, visual probe left to UAT 1. C3 (no cost in docs): amended in 07-01. C4 (ETA = serverNow + duration): confirmed. Research pitfalls checked in code: server-time (no `DateTime.now`), shared `travelInProgressCode` single definition, travel case of the disabled board (Pitfall 11).

## Requirements traceability

| ID | Plan(s) | Status | Evidence |
|----|---------|--------|----------|
| TRAVEL-01 | 07-01, 07-11 | SATISFIED (backend prerequisite) | Shipped on BE develop @ 3df1b37; FE fragment requests `activeTravel`; 32/32 documents validate against `origin/develop:src/schema.gql` |
| TRAVEL-02 | 07-01 to 07-03, 07-05, 07-07 to 07-11 | SATISFIED in code; device pending (UAT 1, 3, 8) | Confirmation flow as per criterion 1 |
| TRAVEL-03 | 07-02 to 07-06, 07-08 to 07-11 | SATISFIED in code; device pending (UAT 3, 4, 6, 7, 9) | Criteria 2 and 3 |
| TRAVEL-04 | 07-01, 07-06, 07-09 to 07-11 | SATISFIED in code; device pending (UAT 5) | Criterion 4 |

All four IDs from the PLAN frontmatter exist in REQUIREMENTS.md (lines 107-113); no orphaned requirement. The REQUIREMENTS checkboxes and the traceability row (`TRAVEL-01 through TRAVEL-04 | TBD | Pending`) are intentionally still open: plan 07-11 Task 3 ticks them after the device UAT. Not a gap.

## Anti-patterns

No TODO/FIXME or stub markers in the travel files (models/travel, travelCubit, map tab, travel_repository). No `DateTime.now` in the time-sensitive code. No `package:flutter` in models. Nothing blocking.

## Regression check (phases 3, 5, 6)

The full suite (1644 tests, 308 more than the Phase 6 baseline of 1336) passes, including the Phase 3 character subscription/fragment tests, the Phase 5 notification registry and popup tests, and the Phase 6 quest acceptance/board/map-paper tests. The Phase 6 `travelInProgress` banner mapping now reads the single `travelInProgressCode` from the travel catalogue (verified link 03). No regression found.

## Gaps Summary

No automated gaps. Every ROADMAP success criterion and every PLAN must-have is backed by code, wiring and passing tests; schema check is 32/32 against BE `origin/develop`. What remains is plan 07-11 Task 2 and Task 3: the 12-step device UAT (`07-HUMAN-UAT.md`, all steps pending, `status: in-progress`), then REQUIREMENTS ticking and the traceability row. Status is therefore `human_needed`.

---

_Verified: 2026-10-24_
_Verifier: Claude (gsd-verifier)_
