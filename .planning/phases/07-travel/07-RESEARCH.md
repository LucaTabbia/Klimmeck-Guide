# Phase 7: Travel - Research

**Researched:** 2026-10-24
**Domain:** Flutter map rendering (flutter_map 8.2.1), server-anchored time interpolation, GraphQL mutation/failure slice (graphql_flutter 5.2.1), BLoC wiring
**Confidence:** HIGH for code/contract facts (read this session); MEDIUM for the coordinate-order finding (C1, inferred from BE + FE source, needs one device probe)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Trigger and confirmation sheet (TRAVEL-02)
- **D-01 (user decision):** **The trigger is the pawn drag** (the existing `Draggable` in `CharacterMarkerLayer`), not a button in the city sheet. On release the destination is the **city nearest to the release point** (existing behaviour: city whose area contains the point, otherwise `MapUtils.findNearestCity`) and the confirmation sheet opens; the legacy `CharacterCubit.changeCharacterLocation` no-op and the "drag = teleport" behaviour are removed. The pawn is **not draggable** while `status.activeTravel` is set or `quests.pendingQuest` is set (client pre-check; the backend stays the judge: an unexpected rejection goes to the banner, D-14). Tapping a city marker keeps opening the lore sheet only.
- **D-02 (user decision):** Release on the city the character already stands on (`status.location.id == City.markerLocation.id`): the pawn springs back **silently** — no `travelPreview` call, no banner.
- **D-03 (user decision):** The confirmation is a **parchment bottom sheet** (not full screen; the `PaperSheetModal` language, no `AlertDialog`) with: destination name and image (from the city lore), **distance in km**, **duration** in readable form ("2 h 40 min"; days when ≥ 24 h), **ETA** = estimated server now + duration (clock time; add the date when the arrival is not today — format at Claude's discretion), and two game-style actions **"Parti" / "Resta"**. **No cost**: BE Phase 8 has none; the "ETA + costo" wording of PROJECT.md/REQUIREMENTS is superseded and amended by the first plan. The numbers come only from `travelPreview` (owner-only, same rules and codes as `startTravel`). While the preview is in flight the sheet already shows the destination and fills the numbers when they arrive (explicit user action: a subtle in-sheet loading is allowed, never a blocking overlay — technical default). A preview rejection closes the sheet, springs the pawn back and publishes the banner (D-14).
- **D-04 (user decision):** While the sheet is open the map **draws the preview polyline** (dashed) behind it and the camera fits start and destination. "Resta", a rejection or a dismissal removes the route and springs the pawn back to the real location.
- **D-05 (user decision):** **Permission prompt:** right after `startTravel` answers `successful: true`, call `NotificationPermissionGate.ensureRequested()` once (it prompts only when the OS status is not determined). Never before the mutation, never on sheet open (Phase 5 D-10 call site). `startTravel` itself never builds state from its `CommonResponse`: the travel arrives on `characterUpdated` (Phase 6 D-03 pattern).

#### Travel in progress on the Map (TRAVEL-03, TRAVEL-04)
- **D-06 (user decision):** The **whole route stays visible** for the duration of the travel, with the **travelled part in a different tone**. The polyline is parsed/measured once per `startTime` (it travels on every `characterUpdated`; BE handoff §5) and reused by the preview and the live renderer.
- **D-07:** The pawn position is interpolated along the polyline **by cumulative segment length** at `progress = clamp((now + offset − startTime) / duration, 0, 1)`, where `offset = serverTime − device now` is read from the `serverTime` query at **bootstrap and on resume** (BE handoff §5); the device clock never drives it. Smooth animation (ticker) at Claude's discretion. No client-side ETA math anywhere (TRAVEL-02/03).
- **D-08 (user decision):** A **floating label above the pawn** shows only the **remaining time** ("1 h 12 min"), then **"In arrivo…"** at progress 1. No travel paper in the corner, **no tap on the pawn** during travel, no details sheet.
- **D-09 (user decision):** **Camera:** when the Map tab is shown while a travel is active the camera frames the pawn **once**; no continuous follow and **no recenter control** (the player pans freely).
- **D-10 (user decision):** At progress 1 the pawn stays on the **last point of the route** with "In arrivo…" until the backend event (`activeTravel: null` + new `location`): the snap happens only then (TRAVEL-03). A silent character refetch a few seconds after `endTime` is at Claude's discretion and is not completion logic.
- **D-11:** **Reconstruction after a kill:** the Character snapshot of `characterUpdated` carries `activeTravel`; the same renderer resumes at the interpolated position (TRAVEL-04). Nothing about the travel is persisted on the device.

#### Blocks, rejections and automatic quest travel
- **D-12 (user decision):** During a travel everything stays **readable** (city lore sheet, quest markers' read-only sheet, journal/equipment/settings). Disabled: the pawn drag, the **Board** and the **Shop**. New rule: **Board and Shop are available only while the character stands on a city marker** — on a quest POI and during any travel both satchel cells use the dark-scrim disabled visual of Phase 6 D-11/D-13 (`disabledSatchelPages` grows with the shop page index and the `activeTravel` case). The backend will enforce the shop rule too (BE Phase 9, code `SHOP_NOT_IN_CITY`; the FE stays the first filter).
- **D-13 (user decision):** **Automatic quest travel** (standard lane accepted with marker ≠ position, `pendingQuest.startDate == null`) is rendered **exactly like a free travel**: route, moving pawn, floating label. The quest paper keeps "In viaggio" (Phase 6 D-15) until `startDate` arrives; at arrival the pawn snaps and the paper label switches to the per-type label; **no banner** generated by the FE and no push from the BE (handoff §6).
- **D-14 (user decision, revised during the discussion):** Rejections of `travelPreview`/`startTravel` surface in the **Phase 5 in-app banner** with an **FE catalogue chosen by `extensions.code`** (same pattern as Phase 6 D-04; the user first picked "show the BE message verbatim", then reverted to the catalogue): `TRAVEL_IN_PROGRESS`, `TRAVEL_SAME_LOCATION`, `TRAVEL_DESTINATION_NOT_ALLOWED`, `TRAVEL_NO_PATH`, `QUEST_IN_PROGRESS`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`; connection/timeout/unknown → a generic domain line. Italian copy at Claude's discretion, starting from the BE messages (handoff §2). `TRAVEL_NO_PATH` and `TRAVEL_DESTINATION_NOT_ALLOWED` are data defects: **banner only**, the BE already logs a WARN for the GM.

#### Arrival, popup and notifications
- **D-15 (user decision):** Tap on the "Viaggio completato" push (killed/background): the app lands on the Map tab (Phase 5 D-15) and the `travelEnd` entry of `defaultNotificationPopups` only **centres the camera on the pawn** — no sheet, no popup.
- **D-16 (user decision):** Arrival with the app in foreground: snap of the pawn + the Phase 5 banner ("Viaggio completato", tappable → Map). Nothing more.
- **D-17 (user decision):** Arrival of an automatic quest travel: nothing beyond the snap and the quest paper label change (D-13).

#### Documents, models and contract (technical defaults)
- **D-18:** `CharacterFragment.statusFields` gains `activeTravel { road { coordinates distance } startTime endTime duration to }` (fragment-only change, Phase 3 D-05); new documents for `travelPreview(request: TravelRequest!)`, `startTravel(request: TravelRequest!)` and `serverTime`; Flutter-free Equatable models `ActiveTravel`, `TravelPath`, `TravelPreview` in `lib/models/`; `to` (POI id, not populated) is resolved against the cities already loaded by `MainScreenCubit`; `road.coordinates` is `[lon, lat]` per point (BE handoff §1) → map to `LatLng(lat, lon)`. `assets.pet` is **never selected** (handoff §11 b). The final plan verifies every document with `tool/schema_check` against `Klimmeck-Guide-BE/src/schema.gql` at `origin/develop` (`git -C <BE> fetch origin develop`, never a checkout of the BE working tree) and runs the manual E2E on the Android device with the UAT data of the BE handoff §11.
- **D-19:** Repository/Cubit shape follows the acceptance pattern of Phase 6 (`QuestAcceptanceRepository` → domain failure by code, `QuestAcceptanceCubit` + `QuestAcceptanceOutcomeListener` publishing the banner): e.g. a `TravelRepository` (preview/start, `TravelFailure` enum), a `TravelCubit` (idle → previewing → confirming → starting, rejection state) and a travel renderer fed by `CharacterCubit` (`activeTravel`) plus a clock-offset service for `serverTime`; names and files at Claude's discretion (`docs/rules/naming.md`, `architecture.md`, `state-management.md`). Cubits never call Cubits; the UI never sees exceptions.
- **D-20:** Branch **`feat/07-travel`** off `develop`, PR to `develop`, no BE lockstep. Planning docs travel with the code. Tests first (TDD): pure interpolation/offset/formatting units, bloc_test for the cubit, widget tests with fakes and recorded `QueryResult`s (patterns of Phases 3–6), never `dart format` on directories (Phase 11 D-38).

### Claude's Discretion
- Route styling (colours, dash, travelled tone), label styling, duration/ETA formatting for multi-day travels, pawn animation, the in-sheet loading while the preview is in flight, the optional refetch at progress 1, the clock-offset service shape, exact file/class names, drag threshold details, the quest-marker read-only sheet during travel (unchanged from Phase 6).

### Deferred Ideas (OUT OF SCOPE)
- **Backend shop guard** — `doTransaction` rejected off a city marker or during a travel (`SHOP_NOT_IN_CITY`): agreed for **BE Phase 9** (BE 09-CONTEXT D-18). The FE rule of D-12 ships first.
- **Travel details sheet on pawn tap / recenter control / arrival popup with the city lore / "Segnalalo al locandiere" copy / pet bonus line in the dialog** — all declined by the user for this phase; may return later.
- **Travel cost** — none by BE design (Phase 8); not planned.
- **Cancel or re-route a travel** — excluded by backend design (BE Phase 8 D-05).
- **Push for automatic quest travel** — excluded (BE Phase 8 D-14).
- **Return to the city after a quest** (free travel chosen by the player from the quest marker) and the "awaiting aid" state that blocks travel — BE/FE Phase 9.
- **Admin teleport UI** — FE Phase 10 (backend already shipped).
- **Quest countdown on screen** — stays dropped (Phase 6 D-15).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRAVEL-01 | Backend exposes `status.activeTravel` (prerequisite) | **Shipped**: verbatim SDL from `origin/develop` (`3df1b37`) in "Contract (schema wins)"; the first plan ticks it in REQUIREMENTS.md and fills the traceability row (still `TBD` at REQUIREMENTS.md:216) |
| TRAVEL-02 | Explicit confirmation with destination + backend ETA before the mutation | Drag trigger rewrite (Pattern 1), `TravelCubit` states (Pattern 3), `GetTravelPreview` document, ETA = `ServerClock.now() + preview.duration` computed in the cubit, Italian formatter (Pattern 6), cities document gains `relatedLore.image` for the sheet (Pattern 4) |
| TRAVEL-03 | Character moves along `road.coordinates` interpolated on server time; snap only on the backend event | `ServerClock` (Pattern 2), pure `TravelRoute` measure/interpolate (Pattern 5), `TravelProgressCubit` ticker (Pattern 5), route layer split travelled/remaining with `PolylineLayer` (flutter_map API section), coordinate order **C1** |
| TRAVEL-04 | Reconstruction after kill from `activeTravel` | `CharacterStatus.activeTravel` parse + fragment (Pattern 7); the renderer is a pure function of `(activeTravel, serverNow)` so a fresh snapshot resumes at the right spot; D-09 one-shot framing on `onMapReady` |
</phase_requirements>

## Project Constraints (from CLAUDE.md and docs/rules)

Same authority as locked decisions:

- **No UI chrome on gameplay screens**: the confirmation is a parchment bottom sheet (no `AlertDialog`, `AppBar`, `SnackBar`, `MaterialBanner`). `destructive_confirmation_dialog.dart` is utility-only. [CITED: CLAUDE.md rule 1; docs/rules/ui-ux.md]
- **No blocking loading in session**: `serverTime` sync, the character refetch at arrival and WS reauth are invisible; the only loading is an in-sheet placeholder for the numbers while `travelPreview` is in flight (explicit user action). [CITED: CLAUDE.md rule 2; CONTEXT D-03]
- **Backend is the source of truth**: no completion logic, no ETA/duration math from distance; the pawn snaps only on `characterUpdated` with `activeTravel: null`. [CITED: CLAUDE.md rule 4; D-07, D-10]
- **Layering UI → Cubit → Repository → Service**; the UI never reads a Service/Repository to compute state (so the clock is consumed by cubits, not widgets); no `OperationException` reaches the UI; Cubits never call Cubits (orchestration via `BlocListener`). [CITED: docs/rules/architecture.md, state-management.md, graphql.md]
- **Documents in `lib/graphql/`**, one named operation each, Query `GetXxx`, Mutation imperative verb (`StartTravel`), files `<domain>_queries.dart` / `<domain>_mutations.dart`; every new named operation must be added to `tool/schema_check/schema_check_documents.dart` (enforced by `test/tool/schema_check_documents_test.dart`). [CITED: docs/rules/graphql.md, naming.md; VERIFIED: test file]
- **Models Flutter-free** (`lib/models/`): `latlong2` is allowed (already used by `PointOfInterest`, `City`), `package:flutter/*` is not. [VERIFIED: lib/models/point_of_interest.dart imports]
- **Theme tokens only** (`lib/theme/kg_theme.dart`); domain SVG via `CachedSvg`. [CITED: docs/rules/ui-ux.md, assets.md]
- **TDD red → green → refactor**; travel confirm is named in testing.md as a critical gameplay widget needing smoke + interaction tests written first. [CITED: docs/rules/testing.md]
- **Formatting**: never `dart format` on directories; only on new files and touched files measured clean (list in Pitfall 9). [CITED: Phase 11 D-38; user memory]
- **Commits**: Conventional Commits in English, scope `phase-7` for docs (`docs(phase-7): …`), **no `Co-Authored-By` trailer** (user rule overrides the generic attribution reminder). Branch `feat/07-travel`, PR to `develop` with `GH_TOKEN=$(gh auth token --user LucaTabbia)`. [CITED: user memory, docs/rules/workflow.md]
- **No secrets**: nothing here touches `.env`; never print it.

## Summary

The backend contract is merged and stable on BE `origin/develop` (`3df1b37`, PR #11 + #12): `CharacterStatus.activeTravel { duration endTime road { coordinates distance } startTime to }`, `travelPreview(request: TravelRequest!): TravelPreview!`, `startTravel(request: TravelRequest!): CommonResponse!`, `serverTime: DateTime!`. All four proposed FE documents (and the `cities` selection extended with `relatedLore.image`) were validated against that schema in this session with the project's own `tool/schema_check` (5/5 `OK`; the existing 29 documents are also all `OK`). No new package is needed: flutter_map 8.2.1 has `PolylineLayer` + `StrokePattern.dashed`, `MarkerLayer`, `MapController.fitCamera(CameraFit.coordinates(...))` and `MapOptions.onMapReady`; `intl` 0.20.2 is declared but unused, and numeric `DateFormat('HH:mm')` works without `initializeDateFormatting`.

The FE work splits into five vertical slices: (1) a Flutter-free **`ServerClock`** (offset from `serverTime`, synced at shell creation and on `AppLifecycleEvents.foregrounded`, RTT-compensated); (2) the **travel models + fragment** (`ActiveTravel`, `TravelPath`, `TravelPreview` with a single shared wire→`LatLng` helper); (3) the **mutation slice** mirroring Phase 6 exactly (`TravelRequest`, `KlimmeckGraphQl.previewTravel/startTravel/getServerTime`, `TravelFailure` by `extensions.code`, `TravelRepository` with 15 s timeout and the permission gate after success, `TravelCubit`, `TravelOutcomeListener` → `publishNotice`); (4) the **map**: drag trigger rewrite, confirmation sheet, a route layer (dashed preview / two-tone live), a `TravelProgressCubit` ticking at 1 s that turns `(activeTravel, serverNow)` into pawn position + remaining time, one-shot framing on `onMapReady`, and a latched `MapFocusCubit` for the `travelEnd` popup; (5) **satchel availability** (Board + Shop only on a city marker and never during a travel).

The research found one material conflict: **C1 — coordinate order**. CONTEXT D-18 (copying BE handoff §1) says to swap `[lon, lat]` → `LatLng(lat, lon)`. But the BE builds the polyline endpoints from `PointOfInterest.location` *verbatim* and city markers are *exact* road nodes, so polyline points are in the same order as `PointOfInterest.location` — which the FE already renders as `LatLng(location[0], location[1])` (no swap) and has done correctly through six UATs. Swapping would draw the route mirrored across the diagonal and detached from the markers. The safe rule is: **parse polyline points exactly like `PointOfInterest.location` (one shared helper), plus a unit-test invariant that `road.coordinates.first` equals the departure POI and a Wave 0 device probe.**

**Primary recommendation:** build ServerClock + models + mutation slice first (all pure/fake-testable), then the map layers on top, then satchel + popup wiring, and make the schema check + device E2E the last plan; resolve C1 in the CONTEXT before planning (amend D-18 to "same order as `PointOfInterest.location`").

## Conflicts with CONTEXT

| # | Decision | Finding | Evidence | Recommended amendment |
|---|----------|---------|----------|-----------------------|
| **C1** | D-18: "`road.coordinates` is `[lon, lat]` per point → map to `LatLng(lat, lon)`" | The polyline uses **the same order as `PointOfInterest.location`**, and the FE reads that as `LatLng(p[0], p[1])` (no swap). Swapping only the polyline would detach the route from the markers. | BE `src/roads/road-route.ts:36` builds `coordinates: collapse([from, ...nodes.map(coordOf), to])` where `from`/`to` are `fromPOI.location`/`toPOI.location` (`travel-planner.service.ts:142,174`) passed through unchanged (`travel-timing.ts:53-55` maps `[lon, lat] → [lon, lat]`); BE 08 handoff §8: "167/167 city markers are **exact nodes**" (POI location identical to a road coordinate). FE `lib/models/point_of_interest.dart:25-31` and `lib/models/city.dart` parse `[0]` as latitude, and the map (Epsg4326, `world_map.dart:63-91`) has displayed cities correctly through Phases 1-6. The BE labels its tuples "LonLat" (`roads.service.ts:43-48` haversine reads `[lon1, lat1]`), so one of the two labels is wrong about the stored data — but the *relative* order is provably identical. [VERIFIED: source read; MEDIUM until probed on device] | Amend D-18: "parse each `road.coordinates` point with the same helper as `PointOfInterest.location` (today `LatLng(p[0], p[1])`); a unit test asserts first/last points equal the departure POI/destination marker of the fixture; the Wave 0 device probe compares the raw first coordinate of `travelPreview.road` with `status.location.location`." If the BE's distance numbers are geographically off because of its own label, that is a BE concern, out of scope here. |
| C2 | D-18: "`to` … is resolved against the cities already loaded" | For an **automatic quest travel** `to` is the quest marker POI, which is not any `City.markerLocation`, so resolution returns null. No decision actually needs the destination name during travel (D-08 shows only remaining time). | BE handoff §3 (D-02); `lib/graphql/queries/city_queries.dart` (cities expose only `markerLocation`). | Parse `to` as a `String` and keep it on the model; resolve it only where needed (nothing in this phase). Not blocking. |
| C3 | D-03 amends "ETA + costo" in PROJECT.md/REQUIREMENTS | The same wording is also in a **rule file**: `docs/rules/ui-ux.md:45` ("Travel conferma: modal con ETA + costo"), plus PROJECT.md:20 and :59. | grep this session. | The first plan amends PROJECT.md:20/:59 and `docs/rules/ui-ux.md:45` too ("foglio di pergamena con distanza, durata ed ETA dal backend"); CLAUDE.md says rule-file changes need the user's word — D-03 is that decision, flag it in the plan summary. Also remove the stale duplicate open question at STATE.md:663 (line 662 already marks it resolved). |
| C4 | D-07 "No client-side ETA math anywhere" vs D-03/D-08 | The sheet ETA (`serverNow + preview.duration`) and the remaining time (`endTime − serverNow`) are arithmetic on server values. This is exactly what BE handoff §4/§5 prescribes; the prohibition is about deriving duration/ETA from distance or speed. | BE 08 handoff §4 ("l'ETA da mostrare nel dialog è `serverNow + duration`"). | No amendment; state it in the plan so reviewers do not flag it. |

No other D-xx is contradicted.

## Contract (schema wins) — verbatim from BE `origin/develop:src/schema.gql`

Read with `git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql` (HEAD `3df1b37`, PR #12 merged). [VERIFIED]

```graphql
type ActiveTravel {
  duration: Float!
  endTime: DateTime!
  road: TravelPath!
  startTime: DateTime!
  to: ID!
}
type TravelPath {
  coordinates: [[Float!]!]!
  distance: Float!
}
type TravelPreview {
  distance: Float!
  duration: Float!
  road: TravelPath!
}
type CharacterStatus {
  activeTravel: ActiveTravel
  coins: Coins!
  currentLifePoints: Int!
  injuries: [InjuryType!]!
  level: Int!
  location: PointOfInterest!
  maxActiveSpells: Int!
  maxLifePoints: Int!
  spells: [Spell!]!
  title: String!
  xp: Int!
}
type CommonResponse {
  response: String!
  successful: Boolean!
}
type PointOfInterest {
  city: City
  id: ID!
  location: [Float!]!
  quest: ID
  type: [PoiType!]!
}
input TravelRequest {
  id: String!
  poiId: String!
}
scalar DateTime
```

```graphql
# type Mutation (schema.gql:315-316)
  startTravel(request: TravelRequest!): CommonResponse!
  teleportCharacter(request: TravelRequest!): CommonResponse!
# type Query (schema.gql:442, 445)
  serverTime: DateTime!
  travelPreview(request: TravelRequest!): TravelPreview!
# type Subscription (schema.gql:557)
  characterUpdated(id: String!): Character!
# Lore (for the sheet image): image: String (nullable), name: String!
```

Semantics the FE relies on (BE 08 handoff, `3df1b37`): `duration` in **ms** (= `endTime − startTime`); `distance` in game km; `to` = destination POI id (not populated); `serverTime` is authenticated (BE 07 handoff §5) and returns `clock.now()` (`src/time/server-time.resolver.ts`); rejections carry `extensions` exactly `{ code }`; evaluation order `TRAVEL_DESTINATION_NOT_ALLOWED → TRAVEL_IN_PROGRESS → QUEST_IN_PROGRESS → TRAVEL_SAME_LOCATION → TRAVEL_NO_PATH` after auth/ownership/`NOT_FOUND`; `startTravel` responds within ~2 s even with Redis down (queue timeout, §6); `travelEnd` push only for free travels (`id` = characterId); arrival = `characterUpdated` with `activeTravel: null` + new `location`, normally seconds after `endTime`, at worst one sweep interval (60 s default) later. [CITED: BE 08 BACKEND-NOTES §1-§6]

### Proposed FE documents (validated this session: 5/5 `OK`)

```graphql
query GetServerTime { serverTime }

query GetTravelPreview($request: TravelRequest!) {
  travelPreview(request: $request) { distance duration road { coordinates distance } }
}

mutation StartTravel($request: TravelRequest!) {
  startTravel(request: $request) { response successful }
}

# CharacterFragment.statusFields gains:
activeTravel { road { coordinates distance } startTime endTime duration to }

# cities (getAllCities) gains image on relatedLore (for the sheet, D-03):
relatedLore { id description image }
```

The validation used the probe names `PreviewTravel`/`ActiveTravelProbe`/`CitiesImageProbe`; the operation names in code should follow naming.md (`GetTravelPreview`, `GetServerTime`, `StartTravel`). [VERIFIED: `node tool/schema_check/validate_documents.js` with BE `node_modules/graphql`]

## Standard Stack

No new runtime dependency. [VERIFIED: pubspec.yaml + pubspec.lock]

### Core (already present)
| Library | Locked version | Purpose here |
|---------|----------------|--------------|
| flutter_map | 8.2.1 | `PolylineLayer`/`Polyline` + `StrokePattern.dashed`, `MarkerLayer`, `MapController.fitCamera`/`move`, `MapOptions.onMapReady` |
| latlong2 | 0.9.1 | `LatLng` value type (equality by lat/lon, `LatLng.dart:99-102`); `Distance` available but not recommended (see Pattern 5) |
| flutter_bloc / bloc | 9.1.1 | Cubits, `BlocListener`, `BlocSelector` |
| equatable | 2.0.7 | Models and states |
| graphql_flutter | 5.2.1 | `performQuery`/`performMutation` (`FetchPolicy.noCache`) |
| intl | 0.20.2 | `DateFormat('HH:mm')`, `DateFormat('dd/MM')` (declared in pubspec, unused in `lib/` today) |

### Supporting (tests)
| Library | Version | Use |
|---------|---------|-----|
| flutter_test | SDK 3.35.5 / Dart 3.9.2 | widget tests (`tester.pump(Duration)` drives `Timer.periodic`) |
| bloc_test | 10.0.0 | `blocTest`, `MockCubit`, `whenListen` |
| mocktail | 1.0.5 | `MockKlimmeckGraphQl` (exists), new `MockTravelRepository`, `MockServerClock` |
| fake_async | 1.3.3 | timers for `TravelProgressCubit`, `ServerClock`, repository timeouts |

### Alternatives Considered
| Instead of | Could use | Why not |
|-----------|-----------|---------|
| Plain `fitCamera`/`move` | `flutter_map_animations` package | New dependency for a provisional visual (no UI phase); the project already has a Timer-based pan (`world_map.dart:239-272`) and an unused `LatLngTween` (`map_utils.dart:83-94`) if animation is wanted |
| 1 s `Timer.periodic` in a cubit | 60 fps `Ticker`/`AnimationController` | Travels last 20 min to ~3.4 days (BE §8): the pawn moves well under 1 px/s at map scale; 60 fps rebuilds of a `PolylineLayer` with hundreds of points cost battery for no visible gain |
| `package:clock` | `DateTime Function() now` injection | The project's established pattern (`in_app_notifications_cubit.dart:23`, `ws_reconnect_policy.dart:24`, `session_auth_token_service.dart:51`) |
| `initializeDateFormatting('it')` | Numeric patterns on the default locale + Italian words in code | Avoids an async init in `main.dart`; `en_US` symbols are built in (`intl/src/date_format_internal.dart:39`), numeric `HH:mm`/`dd/MM` are locale-independent |

## Current code inventory (what the planner touches)

### Pawn drag path
- `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart`
  - `BlocConsumer` listener `:41-47` **resets `_tmpLocation` to the real location on every `CharacterLoaded`** — any unrelated `characterUpdated` (coins, spells) while the sheet is open would spring the pawn back (Pitfall 3).
  - `Marker(point: displayLocation, …)` `:58-74` uses the **default 30×30 box** with a `Transform.scale` child (Pitfall 7 for the floating label).
  - `Draggable` `:84-101` (`feedback` 60 px SVG, `childWhenDragging` opacity 0); disable with `maxSimultaneousDrags: 0` ("Set this to 0 if you want to prevent the draggable from actually being dragged", Flutter `drag_target.dart:311-319`). [VERIFIED: SDK source]
  - `_handleDragUpdate` `:104-118` (global → local → `camera.screenOffsetToLatLng`, calls `onDragUpdate` for auto-pan).
  - `_handleDragEnd` `:120-147`: `findCityContainingPoint` → `findNearestCity` → sets `_tmpLocation` to the city marker → `onDragEnd(newLocation, targetCity)`.
- `lib/screens/mainScreen/tabs/map/world_map.dart`
  - Map options `:76-91` (`Epsg4326`, bounds `(-90,-180)..(90,180)` `:63-65`, `pinchZoom | drag`, `CameraConstraint.contain`); add `onMapReady` here for D-09/D-15.
  - Layer order `:123-148`: image → `CityMarkersLayer` → `QuestMarkersLayer` → `CharacterMarkerLayer` → `QuestPaperLayer` → `QuestInfoOverlay`. The route layer goes **right after the image** (markers stay on top).
  - `_handleCharacterDragUpdate` `:184-195` + `_animateMapTo` `:239-272` (Timer at `MapConstants.smoothScrollInterval` 16 ms with acceleration/damping) — keep for drag auto-pan; `_stopAnimation` `:274-279` on drag end.
  - `_handleCharacterDragEnd` `:197-206` → calls `CharacterCubit.changeCharacterLocation` — **replace** with "same city → silent spring back (D-02), else `TravelCubit.preview(...)` + open sheet".
  - `_showCityInfoModal` `:225-236`: the `showModalBottomSheet(useSafeArea: false, isScrollControlled: true, backgroundColor: transparent, builder: PaperSheetModal(...))` idiom to copy for the confirmation sheet.
- `lib/screens/mainScreen/characterCubit/character_cubit.dart:98-101` — `changeCharacterLocation` empty stub (plus the now-unused `latlong2` import `:16`): delete both (Boy Scout). Only call site: `world_map.dart:201`. [VERIFIED: grep]
- `lib/screens/mainScreen/tabs/map/utils/map_utils.dart`: `findNearestCity` `:40-61` (squared Euclidean in degrees over **all** cities, including those hidden at the current zoom), `findCityContainingPoint` `:63-73` (uses `City.area`, which the `cities` document does **not** select, so it always falls through to nearest), `clampToBounds` `:75-80`, `LatLngTween` `:83-94` (unused anywhere).
- `lib/screens/mainScreen/tabs/map/utils/map_constants.dart`: zoom thresholds, `mapAnimationDuration` 100 ms, `smoothScrollInterval` 16 ms, `characterMarkerSize` 60. Add travel constants here (tick interval, label offset, arrival refetch delays).
- `WorldMapCubit.loadLoreData` (`cubit/world_map_cubit.dart:17-27`) emits `WorldMapLoadData`, which `world_map.dart:110-116` turns into the **city lore sheet** — do not reuse it to fetch the sheet image (it would open the lore sheet); use `City.relatedLore.image` from the extended `cities` document.

### Quest paper / "In viaggio"
- `lib/models/quest/quest_state_label.dart:5-17`: `startDate == null → 'In viaggio'`, else per-type label. Already correct for D-13; nothing to change.
- `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart:29-44`: rebuilt from `CharacterCubit` + `QuestCubit`; the label flips when `characterUpdated` brings `startDate` (BE sets it to the planned `endTime` at completion, handoff §6).

### Satchel availability
- `lib/screens/mainScreen/components/satchel_availability.dart:8-13`: `disabledSatchelPages({location, cities})` → `{boardPageIndex}` off a city marker.
- `lib/screens/mainScreen/components/satchel_layout.dart:38` `boardPageIndex = 4`; the Shop entry is `pageIndex: 5` (`:84-90`) — add `shopPageIndex = 5`.
- `lib/models/quest/board_policy.dart:10-19`: `currentCityOf`, `isOnCityMarker` (marker id equality, Phase 6 D-20 G2).
- `lib/screens/mainScreen/main_screen.dart:83-95`: `BlocSelector<CharacterCubit, CharacterState, PointOfInterest?>` selecting **only the location**; passes `disabledPages` to `MenuBackground` `:113-118` and `SatchelMenu` `:119-124`; defensive `_isPageDisabled` `:207-218` recomputes the same set. Both must get the travel flag. **Note:** during a free travel and during an automatic quest travel `status.location` is still the departure city marker (it changes only at completion), so without the `activeTravel` input the Board/Shop would stay enabled.

### Notifications
- `NotificationPermissionGate.ensureRequested()` (`lib/repository/services/push/notification_permission_gate.dart:6-20`): Flutter-free, idempotent while in flight, prompts only on `notDetermined`; provided at the app root `lib/main.dart:271-273` (above `MaterialApp`, so reachable from any route).
- `defaultNotificationPopups` (`notification_popup_registry.dart:12-13`, `const {}`), type `void Function(BuildContext, NotificationIntent)`; called by `NotificationIntentLanding._consumePendingIntent` (`notification_intent_landing.dart:48-60`) **after** `popUntil(isFirst)` and `jumpToPage(0)` in the same frame, with the landing's context (an ancestor of `WorldMap`, so it cannot reach the `MapController`; the map may not even be mounted yet).
- Foreground `travelEnd` banner (D-16) already works with no change: `ForegroundPushEvents` → `InAppNotificationsCubit.publish` → banner; tap → `open(event)` → `NotificationTapRouter.handle` (`notification_tap_router.dart:21-29`) → personal intent → landing → popup. So the D-15 popup also runs for the foreground banner tap. [VERIFIED]
- `InAppNotificationsCubit.publishNotice(KGNotification, {dedupKey})` (`in_app_notifications_cubit.dart:63-75`): Phase 6 local notice path; tap = dismiss.

### Fragment, models, service
- `lib/graphql/fragments/character_fragment.dart:23-42` `statusFields` (used by `fullFields` `:108-114`, which feeds both `GetCharacter` and `characterUpdated` — fragment-only change covers bootstrap, refresh and live).
- `lib/models/character/character_status.dart`: `fromJson` `:34-56`, `copyWith` `:71-95` (`??` style, cannot clear a nullable — Pitfall 6), `props` `:98-109`. No production code calls `CharacterStatus.copyWith` today (grep).
- `lib/models/point_of_interest.dart:25-31` — `LatLng(location[0], location[1])`.
- `lib/repository/services/graphql/graphql.dart`: `performQuery` `:58-70`, `performMutation` `:72-84` (both `noCache`), `subscribeToCharacter` `:105-112`, `acceptQuest` `:454-466` (the method to mirror), `_dataOrThrow` `:498-502`.
- `lib/repository/services/graphql/graphql_error_code.dart`: `graphQlErrorCode(OperationException?)` reads `graphqlErrors[*].extensions['code']` (plus the WS payload fallback); constants `forbiddenCode`, `notFoundCode`; `unauthenticatedCode` lives in `services/auth/auth_api_exception.dart`.

### Phase 6 acceptance slice to mirror
- `lib/repository/quest_acceptance_repository.dart:10-42` (15 s `.timeout`, `OperationException → failureFrom`, `TimeoutException → timedOut`, `Object → unknown`).
- `lib/repository/quest_acceptance_failure.dart:1-69` (code constants incl. `travelInProgressCode` `:13`, enum, exception, `…FailureFrom`: `code == null && linkException != null → connection`).
- `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart` (`SafeEmit`, re-entrancy guard `state is QuestAccepting`, `reset()`), `quest_acceptance_state.dart` (sealed, `final class`), `quest_acceptance_notice.dart` (copy catalogue, `unauthenticated → null`).
- `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart:15-81` (session-level `BlocListener`, `publishNotice` with `dedupKey`, then `reset()`), mounted in `main_screen.dart:96`.
- Cubit provided in `AuthenticatedShell` (`authenticated_shell.dart:144-147`) so a late answer survives tab switches; **dialogs/sheets on the root navigator are outside these providers** (`authenticated_shell.dart:60-62`) — pass cubits with `BlocProvider.value`.

### Lifecycle hooks (Phase 3)
- `AppLifecycleEvents` (`lib/repository/services/sync/app_lifecycle_events.dart:8-11`): `backgrounded`/`foregrounded` streams, fed by `AppLifecycleBridge` from `onPause`/`onRestart`; instance created in `main.dart:150`, provided at `main.dart:266`. Consumers today: `CharacterCubit` (`character_cubit.dart:66-68` → silent `refreshCharacter()` on foreground), `SessionSyncCubit`, `NotificationPermissionCubit`.
- `UserRefreshRequests` (`user_refresh_requests.dart`) is a bus for "refetch `me`" — not a resume hook; `ServerClock` does not need it.

## Architecture Patterns

### Recommended structure (new/changed files)
```
lib/
├── graphql/
│   ├── fragments/character_fragment.dart        # + activeTravel in statusFields (DIRTY: no dart format)
│   ├── queries/travel_queries.dart              # NEW: GetTravelPreview
│   ├── queries/server_time_queries.dart         # NEW: GetServerTime
│   ├── queries/city_queries.dart                # + relatedLore.image in getAllCities (DIRTY: no dart format)
│   └── mutations/travel_mutations.dart          # NEW: StartTravel
├── models/
│   ├── wire_lat_lng.dart                        # NEW: latLngFromWire(List) shared by POI + TravelPath (C1)
│   ├── travel/active_travel.dart                # NEW
│   ├── travel/travel_path.dart                  # NEW
│   ├── travel/travel_preview.dart               # NEW
│   ├── travel/travel_route.dart                 # NEW: pure measure + interpolate + split (Pattern 5)
│   ├── travel/travel_time_format.dart           # NEW: Italian duration/ETA strings (Pattern 6)
│   ├── request/travel_request.dart              # NEW
│   ├── character/character_status.dart          # + activeTravel (fromJson/toJson/props/copyWith)
│   └── point_of_interest.dart                   # use latLngFromWire
├── repository/
│   ├── server_clock.dart                        # NEW: ServerClock (Pattern 2)  [name: see Open Q4]
│   ├── travel_failure.dart                      # NEW: codes + enum + exception + travelFailureFrom
│   ├── travel_repository.dart                   # NEW: preview/start, timeout, permission gate
│   ├── quest_acceptance_failure.dart            # import travelInProgressCode from travel_failure.dart (Boy Scout)
│   └── services/graphql/graphql.dart            # + getServerTime/previewTravel/startTravel
├── screens/mainScreen/
│   ├── travelCubit/travel_cubit.dart|travel_state.dart|travel_notice.dart   # NEW
│   ├── components/travel_outcome_listener.dart  # NEW (banner + reset), mounted next to QuestAcceptanceOutcomeListener
│   ├── components/satchel_availability.dart     # + hasActiveTravel, + shop
│   ├── components/satchel_layout.dart           # + shopPageIndex = 5
│   ├── components/notification_popup_registry.dart  # + travelEnd entry
│   ├── main_screen.dart                         # selector (location, hasActiveTravel)
│   └── tabs/map/
│       ├── world_map.dart                       # drag end → TravelCubit, sheet, onMapReady framing, focus listener (DIRTY)
│       ├── mapFocusCubit/map_focus_cubit.dart   # NEW: latched "centre on pawn" request (D-15)
│       ├── travelProgressCubit/travel_progress_cubit.dart|_state.dart  # NEW (Pattern 5)
│       ├── layers/travel_route_layer.dart       # NEW: PolylineLayer preview/live
│       ├── layers/character_marker_layer.dart   # idle draggable vs travelling pawn + label (DIRTY)
│       ├── components/travel_confirmation_sheet.dart  # NEW (PaperSheetModal child)
│       └── utils/map_constants.dart             # + travel constants (DIRTY)
├── screens/auth/authenticated_shell.dart        # + ServerClock, TravelCubit, MapFocusCubit providers
└── screens/mainScreen/characterCubit/character_cubit.dart  # − changeCharacterLocation, − latlong2 import
```

### Pattern 1: drag trigger (D-01, D-02, D-04)
1. Pawn widget chooses its mode from state: travelling (`activeTravel != null`) → non-draggable pawn at the interpolated point + label; `pendingQuest != null` → `Draggable(maxSimultaneousDrags: 0)` (or a plain pawn); otherwise the existing `Draggable`.
2. On release `_handleDragEnd` keeps the existing target resolution (D-01 locks it), then:
   - target is the current city (`target.markerLocation?.id == status.location?.id`) → spring back silently (D-02);
   - else `context.read<TravelCubit>().preview(characterId: …, destination: target)` and open the sheet.
3. Pawn display position is a **pure selector**, not a field reset by the character listener:
   `pawnPoint = travelling ? progress.position : (travelState.destination?.markerLocation?.location ?? status.location.location)` while dragging the drag point wins. When the sheet closes (`Resta`, dismissal, rejection) the cubit returns to idle and the pawn falls back to the real location — that is the spring back.

### Pattern 2: `ServerClock` (D-07, BE 07 handoff §5)
```dart
// Flutter-free; lib/repository/server_clock.dart (name at discretion)
class ServerClock {
  ServerClock({required Future<DateTime> Function() fetchServerTime,
               required Stream<void> foregrounded,
               DateTime Function() now = DateTime.now})
      : _fetch = fetchServerTime, _now = now {
    _sub = foregrounded.listen((_) => unawaited(sync()));
  }
  Duration _offset = Duration.zero;   // provisional until the first sync
  bool _isSynced = false;

  DateTime now() => _now().add(_offset);          // estimated server "now" (UTC instant)
  bool get isSynced => _isSynced;

  Future<void> sync() async {                      // never throws, never emits loading
    final sentAt = _now();
    try {
      final server = await _fetch().timeout(const Duration(seconds: 10));
      final receivedAt = _now();
      final midpoint = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
      _offset = server.difference(midpoint);       // RTT-compensated
      _isSynced = true;
    } on Object { /* keep previous offset; next resume retries */ }
  }
  Future<void> dispose() => _sub.cancel();
}
```
- `fetchServerTime` = `KlimmeckGraphQl.getServerTime()` (`DateTime.parse(data['serverTime'])`, `_dataOrThrow`).
- Created in `AuthenticatedShell` with `RepositoryProvider(create: … ..sync(), dispose: (c) => c.dispose())` (needs the authenticated client; same lifetime as `CharacterCubit`). Bootstrap sync runs in parallel with `loadCharacter`.
- Consumers are **cubits** (`TravelCubit` for the ETA, `TravelProgressCubit` for progress/remaining) so widgets never read the repository.
- Before the first sync the offset is zero (device clock) for the few hundred ms of cold start; when the sync lands the next tick corrects the position. This is the only moment the device clock is used, and it is self-correcting (decision recorded in Open Questions).

### Pattern 3: travel mutation slice (mirror of Phase 6)
- `TravelRequest { id, poiId }` with `toJson` (Equatable), like `AcceptQuestRequest`.
- `KlimmeckGraphQl.previewTravel(TravelRequest) → TravelPreview` (parse via a guarded `_travelPreviewFrom`, `FormatException` on malformed), `startTravel(TravelRequest) → void` (`successful != true → FormatException('startTravel not successful')`), `getServerTime() → DateTime`.
- `travel_failure.dart`: constants `travelInProgressCode` (moved here), `travelSameLocationCode = 'TRAVEL_SAME_LOCATION'`, `travelDestinationNotAllowedCode`, `travelNoPathCode`, `questInProgressCode = 'QUEST_IN_PROGRESS'`; `enum TravelFailure { inProgress, sameLocation, destinationNotAllowed, noPath, questInProgress, notFound, forbidden, unauthenticated, connection, timedOut, unknown }`; `travelFailureFrom(OperationException)` identical in shape to `questAcceptanceFailureFrom`.
- `TravelRepository({graphQl, permissionGate, timeout = 15 s})`: `preview(...)` and `start(...)`; on `start` success → `unawaited(_permissionGate.ensureRequested().catchError(...))` (D-05: after success only, never blocks, Repository orchestrating two services is allowed by architecture.md).
- `TravelCubit(repository, clock)` sealed states:
  `TravelIdle` → `TravelPreviewing(destination)` → `TravelConfirming(destination, preview, eta)` → `TravelStarting(destination, preview)` → `TravelStarted(destination, preview)` | `TravelFailed(destination, failure, stage)`; `cancel()` (Resta/dismiss) → idle unless starting; `reset()` after the listener handled the outcome; re-entrancy guards like `QuestAcceptanceCubit`; `SafeEmit`. `eta = clock.now().add(Duration(milliseconds: preview.duration.round()))` computed when the preview arrives.
- `TravelOutcomeListener` (session level, next to `QuestAcceptanceOutcomeListener` in `MainScreen`): on `TravelFailed` → `travelNoticeFor(failure)` → `publishNotice(notice, dedupKey: 'travel|${failure.name}|${destination.id}')` → `reset()`; `unauthenticated → null` (no banner). The sheet itself listens to `TravelCubit` and pops on `TravelFailed`/`TravelStarted`.
- Provided in `AuthenticatedShell` (like `QuestAcceptanceCubit`, `authenticated_shell.dart:144-147`).

### Pattern 4: confirmation sheet (D-03, D-04)
- `showModalBottomSheet(useSafeArea: false, isScrollControlled: true, backgroundColor: Colors.transparent, barrierColor: Colors.transparent /* route stays visible */, builder: (_) => BlocProvider.value(value: travelCubit, child: PaperSheetModal(child: TravelConfirmationSheet(city: target))))`; `.whenComplete(travelCubit.cancel)` covers swipe-down/barrier dismissal.
- Content: `city.name`, `CachedSvg(url: city.relatedLore.image)` (nullable → omit), distance `"%.1f km"`-style, duration, ETA, "Parti" / "Resta". Numbers show a subtle placeholder while `TravelPreviewing`.
- The app is **landscape-only** (`main.dart:76-79`, test surface 780×360 in `test/helpers/landscape.dart`); `PaperSheetModal` opens at `initialChildSize: 0.5`, so fit the camera with `EdgeInsets.only(bottom: screenHeight * 0.5 + margin)`.
- Route preview: `CameraFit.coordinates(coordinates: preview.road.points, padding: …, maxZoom: MapConstants.maxZoom)` once when `TravelConfirming` arrives.

### Pattern 5: route geometry and progress (D-06..D-11)
Pure, Flutter-free (`lib/models/travel/travel_route.dart`):
```dart
class TravelRoute extends Equatable {
  factory TravelRoute.of(List<LatLng> points);   // precomputes cumulative lengths once
  final List<LatLng> points;
  final List<double> cumulative;                 // cumulative[0] = 0, last = total
  LatLng pointAt(double progress);               // clamp 0..1, binary search on cumulative, lerp in segment
  (List<LatLng> travelled, List<LatLng> remaining) splitAt(double progress);
}
double travelProgress({required DateTime serverNow, required DateTime startTime, required double durationMs})
    => durationMs <= 0 ? 1 : ((serverNow.difference(startTime).inMilliseconds) / durationMs).clamp(0, 1);
```
- **Length metric: planar Euclidean on the parsed `LatLng` (degrees).** The map is plate carrée (`Epsg4326`), so equal planar lengths are equal on-screen lengths: the pawn moves at constant visual speed, and the result is independent of the C1 lat/lon labelling. BE handoff §5 states "basta il rapporto". If `latlong2.Distance` is preferred, it **must** be `Distance(roundResult: false)` — the default rounds every segment to whole metres (`Distance.dart:42-47`), which collapses short segments.
- Edge cases: 0 points → no route (pawn at `status.location`); 1 point or total length 0 → that point; duplicate consecutive points (BE collapses them, `road-route.ts:51-58`, but be defensive) → zero-length segments skipped.
- Memoise by `startTime` (D-06): `TravelProgressCubit.follow(ActiveTravel?)` rebuilds the `TravelRoute` only when `startTime` changes; equal `ActiveTravel`s are no-ops.
- `TravelProgressCubit(clock, {tick = 1 s})`: `follow(activeTravel)`; `Timer.periodic(tick)` emits `TravelProgressState(route, position, travelled, remaining, remainingTime, isArriving)`; `isArriving = progress >= 1`; `follow(null)` cancels the timer and emits idle (snap). Provided **inside `WorldMap`** (`BlocProvider(create: (ctx) => TravelProgressCubit(ctx.read<ServerClock>())..follow(current))`) so it ticks only while the Map tab is mounted; a `BlocListener<CharacterCubit>` in `WorldMap` feeds `follow(...)` (Cubits never call Cubits).
- D-10 optional refetch: when `isArriving` first becomes true, the state carries `refetchDueAt` = `endTime + 5 s` and, if still travelling, `endTime + 65 s` (covers the 60 s sweep); a `BlocListener` calls `context.read<CharacterCubit>().refreshCharacter()` (silent, never `Loading`, `character_cubit.dart:78-96`). This is not completion logic: it only re-reads the backend.
- Route layer: `PolylineLayer(polylines: [Polyline(points: travelled, color: tokenA, strokeWidth: …), Polyline(points: remaining, color: tokenB, pattern: StrokePattern.dashed(segments: [12, 8]))])`; preview = one dashed polyline. Keep `simplificationTolerance` default (0.3).

### Pattern 6: Italian time strings (D-03, D-08)
Pure functions in `travel_time_format.dart` (unit-tested, no locale init):
- `formatTravelDuration(Duration d)`: `< 1 min → "meno di 1 min"`, `< 1 h → "40 min"`, `< 24 h → "2 h 40 min"` (drop `0 min` → `"2 h"`), `≥ 24 h → "1 g 3 h"` (drop minutes; drop `0 h`). Round **up** to the minute for remaining time so it never reads "0 min" before arrival.
- `formatArrival(DateTime eta, {required DateTime serverNow})` in local time (`toLocal()` on both): same local date → `"oggi alle 16:40"`, next date → `"domani alle 09:10"`, otherwise `"il 27/10 alle 09:10"` (`DateFormat('HH:mm')`, `DateFormat('dd/MM')`). BE §8: longest travel ~82 h, so the date is always within the week; no weekday names (they would need `initializeDateFormatting('it')`).
- Label at progress 1: `"In arrivo…"`.

### Pattern 7: models and fragment (D-18)
- `latLngFromWire(List<dynamic> p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())` used by `PointOfInterest.fromJson` **and** `TravelPath.fromJson` (C1: one order for both).
- `TravelPath { List<LatLng> points; double distance }`, `ActiveTravel { TravelPath road; DateTime startTime; DateTime endTime; double duration; String to }` (`DateTime.parse` like `pending_quest.dart:24-26`; ISO with `Z` → UTC instant), `TravelPreview { double distance; double duration; TravelPath road }`; all Equatable, `fromJson`/`toJson`.
- `CharacterStatus.activeTravel` nullable, in `fromJson`, `toJson`, `props`; `copyWith` either omits it or uses a "clear" flag — never `activeTravel ?? this.activeTravel` (Pitfall 6).
- Never select `assets { pet }` (BE §11 b).

### Pattern 8: satchel availability (D-12)
```dart
Set<int> disabledSatchelPages({required PointOfInterest? location, required List<City> cities, required bool isTravelling}) =>
    isOnCityMarker(cities, location) && !isTravelling
        ? const {}
        : const {SatchelLayout.boardPageIndex, SatchelLayout.shopPageIndex};
```
`MainScreen` selects a record `(PointOfInterest?, bool)` (`(status?.location, status?.activeTravel != null)`; Dart records have value equality, so `BlocSelector` rebuilds only on change) and `_isPageDisabled` passes the same flag.

### Pattern 9: camera framing once (D-09) and the `travelEnd` popup (D-15)
- `WorldMap` is **disposed and re-created on every Map-tab visit** (`PageView` has `cacheExtent: 0`, Phase 6 research; no page uses `AutomaticKeepAliveClientMixin`, grep), and its camera already resets to `initialCenter (0,0)` each time. So "once per tab show" = `MapOptions.onMapReady` of that `WorldMap` instance: if a travel is active → `_mapController.move(progress.position, zoom)`.
- `MapFocusCubit` (shell level, latched like `NotificationIntentCubit`): `requestCharacterFocus()` sets `pending = true`; `WorldMap` consumes it in `onMapReady` **and** via `BlocListener` when already mounted → move to the pawn (interpolated if travelling, else `status.location`). Registry entry: `NotificationCategory.travelEnd: _focusCharacter` with a top-level `void _focusCharacter(BuildContext c, NotificationIntent _) => c.read<MapFocusCubit>().requestCharacterFocus();` (a top-level tear-off keeps the map `const`).
- `MapController.camera` throws before the `FlutterMap` is rendered (`map_controller_impl.dart:57-72`); never call `move`/`fitCamera` before `onMapReady`.

### Anti-Patterns to Avoid
- Swapping the polyline order independently from `PointOfInterest` (C1).
- Reading `ServerClock` or `TravelRepository` from a widget (layering).
- Using `WorldMapCubit.loadLoreData` for the sheet image (opens the lore sheet).
- `CharacterCubit.changeCharacterLocation`-style optimistic moves: the pawn never moves to the destination before `characterUpdated`.
- A 60 fps ticker or `setState` on the whole `WorldMap` per tick: rebuild only the route + pawn layers (`BlocBuilder` scoped to them).
- `AlertDialog`/`SnackBar` for confirmation or errors.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Dashed polyline | custom `CustomPainter` | `Polyline(pattern: StrokePattern.dashed(segments: [..]))` (flutter_map 8.2.1 `stroke_pattern.dart:34-46`) | handles projection, culling, simplification |
| Fit two points / a route | manual bounds + zoom math | `CameraFit.coordinates(coordinates:, padding:, maxZoom:)` + `MapController.fitCamera` (`camera_fit.dart:51-57`, `map_controller.dart:129`) | padding in pixels, respects constraints |
| Error-code extraction | parsing messages | `graphQlErrorCode(exception)` | already handles HTTP and WS shapes |
| Banner | new overlay/snackbar | `InAppNotificationsCubit.publishNotice` | queue, 5 s auto-dismiss, dedup |
| Permission prompt | `permission_handler` calls in the map | `NotificationPermissionGate.ensureRequested()` | single call site by Phase 5 D-10 |
| Clock injection | `package:clock` | `DateTime Function() now` param | project convention |
| Silent refetch | new query path | `CharacterCubit.refreshCharacter()` | no `Loading`, last-write-wins guard |

## Common Pitfalls

### Pitfall 1: coordinate order (C1)
**What goes wrong:** route drawn mirrored, pawn leaves the road at start/end. **Avoid:** shared `latLngFromWire`; unit test "first point equals departure POI parsed from the same fixture"; device probe in Wave 0. **Warning sign:** the dashed preview does not start on the pawn.

### Pitfall 2: device clock leaking into progress
**What goes wrong:** `DateTime.now()` used in the renderer; changing the phone clock moves the pawn (BE §11 d.2 checks exactly this). **Avoid:** only `ServerClock.now()` in cubits; a test sets the fake device clock +2 h with offset −2 h and asserts the same position.

### Pitfall 3: pawn springs back while the sheet is open
**What goes wrong:** `character_marker_layer.dart:41-47` resets `_tmpLocation` on every `CharacterLoaded`. **Avoid:** derive the pawn point from `TravelCubit` state + character (Pattern 1), delete the reset listener.

### Pitfall 4: flicker between "Parti" and the first `activeTravel`
**What goes wrong:** sheet closes, route disappears, then reappears when `characterUpdated` arrives. **Avoid:** route layer draws `activeTravel ?? (TravelStarted.preview)`; the pawn sits on the real location (progress 0) meanwhile; `TravelStarted` is reset when `activeTravel` appears or after the repository timeout.

### Pitfall 5: sheet route outside the shell providers
**What goes wrong:** `context.read<TravelCubit>()` inside the bottom sheet throws `ProviderNotFoundException` (root navigator). **Avoid:** `BlocProvider.value` in the builder (`authenticated_shell.dart:60-62` documents this).

### Pitfall 6: `copyWith` cannot clear `activeTravel`
**What goes wrong:** `activeTravel ?? this.activeTravel` keeps a finished travel. **Avoid:** do not add it to `copyWith` (nobody calls `CharacterStatus.copyWith` in `lib/`), or add an explicit clear; test it.

### Pitfall 7: `Marker` default size 30×30
**What goes wrong:** the floating label overflows/clips or shifts the pawn anchor. **Avoid:** give the travelling pawn marker explicit `width`/`height` and `alignment` so the pawn's foot stays on `point`; label in a `Column` above the pawn; `auto_size_text` for the string.

### Pitfall 8: `MapController` used before render
**What goes wrong:** `Exception('You need to have the FlutterMap widget rendered…')` (`map_controller_impl.dart:57-72`) when framing in `initState` or from the popup on cold start. **Avoid:** `onMapReady` + latched `MapFocusCubit`.

### Pitfall 9: `dart format` and analyzer gates
Measured this session: **DIRTY (never format):** `world_map.dart`, `character_marker_layer.dart`, `map_utils.dart`, `map_constants.dart`, `character_fragment.dart`, `world_map_cubit.dart`, `city_markers_layer.dart`, `city_queries.dart`. **CLEAN (may check with `dart format --output=none --set-exit-if-changed <file>`):** `character_status.dart`, `main_screen.dart`, `satchel_availability.dart`, `notification_popup_registry.dart`, `character_cubit.dart`, `graphql.dart`, `authenticated_shell.dart`, `point_of_interest.dart`, `main.dart`, `quest_acceptance_outcome_listener.dart`, `notification_intent_landing.dart`, `tool/schema_check/schema_check_documents.dart`, plus every new file. `flutter analyze` baseline: **54 issues, 0 errors, 2 warnings** — gate ≤ 54, 0 errors (`world_map_cubit.dart:24 avoid_print` disappears if that file is touched and the `print` removed).

### Pitfall 10: `findNearestCity` picks a hidden village
**What goes wrong:** at low zoom villages are hidden (`MapConstants.villageVisibleZoom 3.2`) but `findNearestCity` searches all cities; the sheet then names a city the player cannot see. **Avoid:** D-01 locks the existing rule; the sheet shows the destination name so "Resta" is the escape. Restricting to visible cities would change D-01 — leave it unless the user asks (noted for the E2E).

### Pitfall 11: Board/Shop stay enabled during a travel
**What goes wrong:** location is still the departure city marker until completion. **Avoid:** Pattern 8 `isTravelling` input.

### Pitfall 12: schema-check registry
**What goes wrong:** a new document not registered fails `test/tool/schema_check_documents_test.dart` (it scans `lib/graphql/{queries,mutations,subscriptions}` for operation names). **Avoid:** add `GetServerTime`, `GetTravelPreview`, `StartTravel` (29 → 32 entries) in the same commit as the documents.

### Pitfall 13: popup runs with no map mounted
The landing calls the popup right after `jumpToPage(0)` (`notification_intent_landing.dart:52-59`); `WorldMap` is built in the next frame. Latch, don't call the controller.

## Code Examples

### Document + service method (mirrors `acceptQuest`)
```dart
// lib/graphql/mutations/travel_mutations.dart
class TravelMutations {
  /// Avvia il viaggio libero verso il marker di una città (BE Phase 8).
  static const String startTravel = r'''
    mutation StartTravel($request: TravelRequest!) {
      startTravel(request: $request) {
        response
        successful
      }
    }''';
}

// lib/repository/services/graphql/graphql.dart
Future<void> startTravel(TravelRequest request) async {
  final data = _dataOrThrow(await performMutation(
    query: TravelMutations.startTravel,
    variables: {'request': request.toJson()},
  ));
  final result = data['startTravel'];
  if (result is! Map<String, dynamic> || result['successful'] != true) {
    throw const FormatException('startTravel not successful');
  }
}
```

### Recorded responses in tests (existing helpers)
`test/helpers/fixtures/sync_event_fixtures.dart`: `dataResponse(Map)`, `errorCodeResponse(String code)`; `KlimmeckGraphQl(resolveClient: () => GraphQLClient(link: Link.function(...), cache: GraphQLCache(store: InMemoryStore())))` as in `test/repository/services/graphql/graphql_quest_acceptance_test.dart:10-24`.

### Interpolation test shape
```dart
test('progress anchors on server time, not the device clock', () {
  var device = DateTime.utc(2026, 10, 24, 12);           // device says 12:00
  final clock = ServerClock(fetchServerTime: () async => DateTime.utc(2026, 10, 24, 10),
                            foregrounded: const Stream.empty(), now: () => device);
  // after sync: offset ≈ -2 h → server now ≈ 10:00
});
```

### Mounting map layers in widget tests (Wave 0 helper, none exists today)
```dart
Widget mapHarness(List<Widget> layers, {MapController? controller}) => buildTestApp(
  home: SizedBox(width: 780, height: 360, child: FlutterMap(
    mapController: controller,
    options: const MapOptions(crs: Epsg4326(), initialCenter: LatLng(0, 0), initialZoom: 2),
    children: layers,
  )),
);
```
No test mounts `FlutterMap`/`WorldMap` today (grep); no network is involved (no `TileLayer`), so it runs offline. Assert on `find.byType(PolylineLayer)` + `tester.widget<PolylineLayer>(…).polylines` and on `Marker.point` via `tester.widget<MarkerLayer>(…)`.

## State of the Art

| Old approach (in repo) | Current approach | Impact |
|------------------------|------------------|--------|
| Drag = teleport no-op (`changeCharacterLocation`) | Drag → `travelPreview` → sheet → `startTravel`; pawn moves only from `activeTravel` | removes the stub |
| "ETA + costo" (PROJECT/ui-ux) | distance + duration + ETA, no cost (BE Phase 8) | doc amendments (C3) |
| Board disabled only off a marker | Board **and** Shop disabled off a marker **or** during a travel | `disabledSatchelPages` signature change |
| flutter_map < 7 `isDotted` | `StrokePattern.dotted/dashed/solid` | use the 8.x API |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | The FE map has been rendering POIs correctly with `LatLng(location[0], location[1])` (so that order is the truth for the polyline too) | C1 | If markers were in fact transposed and nobody noticed, both POIs and route would be transposed together — still consistent with each other; only absolute placement on the image would be off (pre-existing). The device probe settles it. [ASSUMED from six UATs on device recorded in STATE/PROJECT] |
| A2 | A 1 s tick is visually smooth for the shortest real travels (~22 min city→city, BE §8) | Pattern 5 | Slight stepping on very short test travels; drop the tick to 250 ms via a constant |
| A3 | Barrier-transparent bottom sheet is acceptable visually (route visible) | Pattern 4 | Provisional per "no UI phase"; user reworks |

## Open Questions (RESOLVED)

1. **Coordinate order (C1)** — RESOLVED: parse with the same helper as `PointOfInterest.location` (no swap); amend D-18; unit-test invariant + Wave 0 device probe (log, debug only, the raw first point of `travelPreview.road.coordinates` next to `status.location.location`).
2. **Where the clock is consumed** — RESOLVED: only in cubits (`TravelCubit` for the ETA, `TravelProgressCubit` for progress/remaining); `ServerClock` lives in the shell as a `RepositoryProvider`, synced at creation and on `foregrounded`, RTT-compensated, silent on failure (keeps the last offset).
3. **Before the first `serverTime` answer** — RESOLVED: offset 0 for the cold-start window, corrected on the next 1 s tick; no blocking wait (rule 2). The final position never depends on the device clock once synced.
4. **Naming of the clock** — RESOLVED: `ServerClock` in `lib/repository/server_clock.dart`; if the plan-checker enforces the `Repository`/`Service` suffix literally (naming.md "Repository/Service: suffisso"), name it `ServerClockService` in `lib/repository/services/time/server_clock_service.dart`. Recommend the suffixed form to avoid a review round-trip.
5. **Ticker rate** — RESOLVED: `Timer.periodic(MapConstants.travelTickInterval = 1 s)` inside `TravelProgressCubit`, alive only while `WorldMap` is mounted.
6. **Refetch at progress 1 (D-10 discretion)** — RESOLVED: silent `refreshCharacter()` at `endTime + 5 s` and, if still travelling, at `endTime + 65 s`; nothing else.
7. **Sheet image source** — RESOLVED: add `image` to `cities { relatedLore { … } }` (validated `OK`); no extra request, no `WorldMapCubit` reuse.
8. **Destination `to` for quest travel** — RESOLVED: parsed and stored, not resolved (C2).
9. **Permission prompt call site** — RESOLVED: inside `TravelRepository.start` after `successful: true`, unawaited, errors swallowed (UI never calls services; D-05 satisfied).
10. **`travelEnd` popup reaching the camera** — RESOLVED: latched `MapFocusCubit` in the shell, consumed by `WorldMap` on `onMapReady` or live via `BlocListener`.
11. **Camera animation** — RESOLVED: plain `move`/`fitCamera` (provisional visual, no new package); `LatLngTween` remains available if the user wants motion later.
12. **Locale for dates** — RESOLVED: no `initializeDateFormatting`; numeric patterns + Italian words in code (Pattern 6).
13. **Pawn during `pendingQuest` without travel** — RESOLVED: shown at `status.location`, not draggable (`maxSimultaneousDrags: 0`), still no tap action.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Flutter / Dart | all | yes | 3.35.5 / 3.9.2 | — |
| flutter_map / latlong2 / intl in pub cache | build, source checks | yes | 8.2.1 / 0.9.1 / 0.20.2 | — |
| Node + BE `node_modules/graphql` | `tool/schema_check` | yes (ran this session) | graphql 16.x from BE | — |
| BE repo `origin/develop` | schema, handoff | yes (`3df1b37`) | — | `git show origin/develop:…` (never checkout) |
| Running BE (Mongo + Redis) with UAT data (BE §11 a-c) | device E2E, C1 probe | not verified from here (user-run) | — | none for E2E; unit/widget tests need no BE |
| Android device + `adb reverse tcp:3000` | E2E (drag, sheet, push, kill) | user's Samsung (memory) | — | none |

**Missing with no fallback:** running BE + device for the final E2E (user-run, as in Phases 5-6).

## Validation Architecture

(`.planning/config.json` has no `workflow.nyquist_validation: false` → required.)

### Baseline (measured 2026-10-24 on `feat/07-travel`, clean tree)
- `flutter test` → **1350 tests, all passed, ~40 s wall** (99 s user CPU).
- `flutter analyze` → **54 issues, 0 errors, 2 warnings**.
- `tool/schema_check` → **29/29 `OK`** against `origin/develop:src/schema.gql`; the 5 proposed documents/selections → **5/5 `OK`**.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 + fake_async 1.3.3 |
| Config file | none; shared mocks `test/helpers/mocks.dart`, fixtures `test/helpers/fixtures/`, fakes `test/helpers/fakes/`, `buildTestApp`, `useLandscapePhone`, `seedSvgCache` |
| Quick run command | `flutter test test/models test/graphql test/repository test/screens/mainScreen test/tool` (~15-20 s) |
| Full suite command | `flutter test` (~40 s) + `flutter analyze` (≤ 54, 0 errors) + `dart format --output=none --set-exit-if-changed <each new/clean touched file>` |

### Phase Requirements → Test Map
| Req ID | Behavior | Type | Automated command | File exists? |
|--------|----------|------|-------------------|--------------|
| TRAVEL-01 | `activeTravel` parsed from `CharacterStatus` JSON (null and populated), Equatable, `toJson` round trip; fragment selects `activeTravel { road { coordinates distance } startTime endTime duration to }` and never `pet` | unit | `flutter test test/models/character test/models/travel test/graphql/character_fragment_test.dart` | fragment test exists (extend); models Wave 0 |
| TRAVEL-01 | `latLngFromWire` shared; polyline first/last equal departure POI / destination marker of the fixture (C1) | unit | `flutter test test/models/travel/travel_path_test.dart` | Wave 0 |
| TRAVEL-02 | Documents `GetServerTime`, `GetTravelPreview`, `StartTravel`: one named operation, `$request: TravelRequest!`; registry lists them | unit | `flutter test test/graphql/travel_documents_test.dart test/tool/schema_check_documents_test.dart` | Wave 0 / exists |
| TRAVEL-02 | `KlimmeckGraphQl.previewTravel/startTravel/getServerTime`: operation name, variables `{request:{id,poiId}}`, `successful:false`/missing → `FormatException`, code preserved | unit | `flutter test test/repository/services/graphql/graphql_travel_test.dart` | Wave 0 |
| TRAVEL-02 | `travelFailureFrom`: every BE code → enum, link error → `connection`, no code → `unknown`, message ignored | unit | `flutter test test/repository/travel_failure_test.dart` | Wave 0 |
| TRAVEL-02 | `TravelRepository`: never leaks `OperationException`; 15 s → `timedOut` (fake_async); permission gate called once **only after** success, never on preview, never on failure | unit | `flutter test test/repository/travel_repository_test.dart` | Wave 0 |
| TRAVEL-02 | `TravelCubit`: `[Previewing, Confirming(eta = clock.now + duration)]`, preview failure, `cancel`, `[Starting, Started]`, start failure, double "Parti" ignored, late answer after close ignored | cubit | `flutter test test/screens/mainScreen/travelCubit/travel_cubit_test.dart` | Wave 0 |
| TRAVEL-02 | Copy catalogue exhaustive, Italian, `unauthenticated → null` | unit | `flutter test test/screens/mainScreen/travelCubit/travel_notice_test.dart` | Wave 0 |
| TRAVEL-02 | Sheet: shows name immediately, numbers after preview, "Parti" calls `start`, "Resta"/dismiss calls `cancel`, rejection pops the sheet; outcome listener publishes once with the dedup key | widget | `flutter test test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart test/screens/mainScreen/components/travel_outcome_listener_test.dart` | Wave 0 |
| TRAVEL-02 | Drag: release on another city → `preview` with that city's marker id; on the current city → nothing (D-02); not draggable with `activeTravel` or `pendingQuest`; `changeCharacterLocation` gone | widget | `flutter test test/screens/mainScreen/tabs/map/character_marker_layer_test.dart` | Wave 0 (needs map harness) |
| TRAVEL-02 | Duration/ETA strings ("40 min", "2 h 40 min", "2 h", "1 g 3 h", "oggi/domani/il dd/MM alle HH:mm", ceil to minute) | unit | `flutter test test/models/travel/travel_time_format_test.dart` | Wave 0 |
| TRAVEL-03 | `TravelRoute`: cumulative lengths, `pointAt` at 0/0.5/1 and inside a segment, clamp <0 / >1, zero-length segments, 1-point route, `splitAt` | unit | `flutter test test/models/travel/travel_route_test.dart` | Wave 0 |
| TRAVEL-03 | `ServerClock`: offset with RTT midpoint, failure keeps previous offset, resync on `foregrounded`, device clock shift does not change `now()` after sync | unit (fake_async) | `flutter test test/repository/server_clock_test.dart` | Wave 0 |
| TRAVEL-03 | `TravelProgressCubit`: ticks every 1 s, position from server time, `isArriving` at ≥1 and stays on last point, refetch due at +5 s/+65 s, `follow(null)` snaps and stops the timer, same `startTime` reuses the route | cubit (fake_async) | `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit` | Wave 0 |
| TRAVEL-03 | Route layer: dashed preview; live = travelled + remaining polylines; none when idle; pawn label "1 h 12 min" → "In arrivo…"; no tap handler on the travelling pawn | widget | `flutter test test/screens/mainScreen/tabs/map/travel_route_layer_test.dart test/screens/mainScreen/tabs/map/character_marker_layer_test.dart` | Wave 0 |
| TRAVEL-03 | Satchel: Board + Shop disabled off a marker and while travelling, enabled on a marker without travel; `MainScreen` guard honours the flag | unit + widget | `flutter test test/screens/mainScreen/components/satchel_availability_test.dart test/screens/mainScreen/main_screen_test.dart` | exist (extend) |
| TRAVEL-03 | `travelEnd` popup → `MapFocusCubit.requestCharacterFocus`; landing test with the real registry | widget | `flutter test test/screens/mainScreen/components/notification_intent_landing_test.dart test/screens/mainScreen/tabs/map/map_focus_cubit_test.dart` | exists (extend) / Wave 0 |
| TRAVEL-04 | A fresh `CharacterLoaded` with `activeTravel` (startTime in the past) renders the pawn at the interpolated point on first build; framing happens once in `onMapReady` | widget | `flutter test test/screens/mainScreen/tabs/map/world_map_travel_test.dart` | Wave 0 |
| all | Shell provides `ServerClock`, `TravelCubit`, `MapFocusCubit` | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | exists (extend) |
| all | Every document validates against BE `origin/develop` | scripted | commands below | — |
| E2E | BE §11 d checklist 1-8 on the Android device (preview + confirm, interpolation with the device clock moved, kill mid-travel, arrival push + tap → camera, automatic quest travel without push, `TRAVEL_IN_PROGRESS`/`QUEST_IN_PROGRESS` banners, teleport via GraphQL by hand, pet halves the duration) + Board/Shop disabled + C1 probe | manual-only | UAT recipe (needs running BE + device) | — |

### Schema check (last plan; same as Phase 6 D-16)
```bash
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide
git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE fetch origin develop
SCRATCH=$(mktemp -d)
git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"
NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
  node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"
```
Expected: 32 `OK` (29 today + 3 new; `characterUpdated`, `character` and `cities` change in place).

### Sampling Rate
- **Per task commit:** the task's test file(s) + `flutter analyze` on touched files + format check on new/clean files only.
- **Per wave merge:** quick run command.
- **Phase gate:** full `flutter test` green (≥ 1350 + new), `flutter analyze` ≤ 54 / 0 errors, schema check 32/32, device E2E recorded in the phase summary and in BE `08-HUMAN-UAT.md` (BACKEND-NOTES §3).

### Wave 0 Gaps
- [ ] `test/helpers/fixtures/travel_fixtures.dart`: `activeTravelJson(...)`, `travelPreviewJson(...)`, character JSON with/without `activeTravel` (polyline whose first point equals the character POI location).
- [ ] `test/helpers/map_harness.dart`: minimal `FlutterMap` wrapper (Code Examples).
- [ ] `test/helpers/mocks.dart`: `MockTravelRepository`, `MockTravelCubit`, `MockTravelProgressCubit`, `MockMapFocusCubit`, `MockServerClock` (or a `FakeServerClock` with settable `now`), `MockNotificationPermissionGate` (or reuse `fake_notification_permission_port.dart` with the real gate).
- [ ] C1 device probe step written into the E2E recipe.
- [ ] Doc amendments in the first plan: REQUIREMENTS TRAVEL-01 ticked + traceability row; PROJECT.md:20/:59 and `docs/rules/ui-ux.md:45` without "costo"; STATE.md:663 stale duplicate removed; D-18 amended per C1.

## Security Domain

`security_enforcement` not disabled → included.

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes (inherited) | authenticated client + silent refresh; `serverTime`/`travelPreview`/`startTravel` all require a bearer; `UNAUTHENTICATED` → no banner, session flow acts |
| V3 Session Management | yes (inherited) | shell keyed by character id; cubits/clock closed with the shell; `SafeEmit` drops late answers |
| V4 Access Control | yes | BE owner-only (`FORBIDDEN`, even for the innkeeper); FE sends only `CharacterLoaded.character.id` and a `poiId` taken from loaded city data, never user-typed |
| V5 Input Validation | yes | typed variables (`$request: TravelRequest!`), no id interpolation into documents; guarded parsing of `activeTravel` (malformed → `FormatException` at the service boundary like `_characterFrom`) |
| V7 Error Handling and Logging | yes | copy by `extensions.code`, never server text; debug logs carry ids only (C1 probe prints coordinates, not tokens/payloads) |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|--------|--------|-----------|
| Client fakes arrival/position | Tampering | FE never moves the pawn without `characterUpdated`; BE completes by DB condition |
| Device clock manipulation to "arrive early" | Tampering | display-only; BE `endTime` is authoritative; FE uses server offset |
| Starting travel for another character | Elevation | id from session; BE `FORBIDDEN` |
| Double "Parti" | Tampering | cubit guard while `TravelStarting`; BE conditional write → `TRAVEL_IN_PROGRESS` |
| Error text leak | Information disclosure | fixed Italian catalogue |

## Sources

### Primary (HIGH confidence)
- FE code read this session (all files cited with line numbers above), `pubspec.yaml`/`pubspec.lock`, `test/helpers/*`, `test/tool/schema_check_documents_test.dart`, `tool/schema_check/*`.
- BE `origin/develop` (`3df1b37`): `src/schema.gql`; `.planning/phases/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §0-§11; `08-CONTEXT.md` D-01..D-32; `.planning/phases/07-quest-lanes-quest-04/BACKEND-NOTES.md` §5; `src/roads/road-route.ts`, `src/roads/roads.service.ts`, `src/travel/travel-timing.ts`, `src/travel/travel-planner.service.ts`, `src/time/server-time.resolver.ts`.
- Package sources: `flutter_map-8.2.1/lib/src/layer/polyline_layer/*`, `layer/shared/line_patterns/stroke_pattern.dart`, `map/camera/camera_fit.dart`, `map/controller/map_controller{,_impl}.dart`, `map/options/options.dart` (`onMapReady`), `layer/marker_layer/marker.dart`; `latlong2-0.9.1/lib/latlong/Distance.dart`, `LatLng.dart`; `intl-0.20.2/lib/src/date_format_internal.dart`; Flutter SDK `widgets/drag_target.dart`.
- Measured: `flutter test` (1350 passed, ~40 s), `flutter analyze` (54, 0 errors), per-file `dart format --set-exit-if-changed`, `tool/schema_check` (29/29 + 5/5 probes).

### Secondary (MEDIUM)
- C1 coordinate-order inference (BE + FE source; to be confirmed by the device probe).

### Tertiary (LOW)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — lockfile + package sources.
- Architecture: HIGH — mirrors Phase 6 slices read in code; clock/progress design is new but fully unit-testable.
- Pitfalls: HIGH for FE-side (read/measured); MEDIUM for C1 until probed.

**Research date:** 2026-10-24
**Valid until:** 2026-11-07 (BE contract merged and stable; re-run the schema check before the last plan)
