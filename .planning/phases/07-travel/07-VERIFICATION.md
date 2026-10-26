---
phase: 07-travel
verified: 2026-10-24T00:00:00Z
status: passed
score: 4/4 success criteria, 4/4 requirement IDs accounted for; device UAT 2026-10-26 steps 1-11 pass, step 12 observed
overrides_applied: 0
re_verification: null
gaps: []
human_verification: []  # resolved 2026-10-26 by the device UAT (07-HUMAN-UAT.md, status: complete); the 12 steps are listed in the outcome section below
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

## Human verification outcome (2026-10-26)

Device UAT on Android (Samsung SM-S938B, USB, `adb reverse tcp:3000`), FE `feat/07-travel` @ 596e6c7, local BE from `feat/09-combat-result-admin-outcomes` @ c4582b9 (contains `origin/develop` 3df1b37 + BE Phase 9, PR #13). Full record with the user's verbatim notes and the DB preparation in `07-HUMAN-UAT.md` (`status: complete`).

| UAT | Step | Result |
|-----|------|--------|
| 1 | Preview + C1 probe | pass (route starting on the pawn: no anomaly reported) |
| 2 | Same city | pass |
| 3 | Start | pass (gold dash colour requested → follow-up quick task) |
| 4 | Server time | pass |
| 5 | Kill mid-travel | pass |
| 6 | Arrival (background push + foreground snap/banner) | pass (6b redone with coherent `startTime`/`endTime`; first attempt invalid, orchestrator DB error, no FE defect) |
| 7 | Automatic quest travel | pass |
| 8 | Rejections (`QUEST_IN_PROGRESS`, `TRAVEL_IN_PROGRESS`, no drag) | pass |
| 9 | Teleport by hand (9A free travel, 9B `QUEST_IN_PROGRESS`) | pass |
| 10 | Pet `speedModifier: 2` | pass |
| 11 | Board/Shop off a city | pass |
| 12 | Nearest-city rule (observation) | observed: "Ulby" |

The `human_needed` items above are resolved: status `passed`, no gaps. TRAVEL-01..04 ticked in REQUIREMENTS.md and the roadmap row closed by plan 07-11 Task 3.
