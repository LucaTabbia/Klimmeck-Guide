# Phase 7: Travel - Context

**Gathered:** 2026-10-24
**Status:** Ready for planning (**no UI phase**, same rule as Phase 6: every visual Claude builds is provisional and will be reworked by the user)

<domain>
## Phase Boundary

Users start a free travel from the Map by dragging their pawn onto a city, confirm it on a parchment sheet that shows the backend-provided distance, duration and ETA (`travelPreview` → `startTravel`), then watch the pawn move along the backend polyline with a floating remaining-time label; the Map snaps to the new location only when the backend clears `activeTravel`; a kill mid-travel is reconstructed from the Character snapshot. Automatic travel to a quest marker (standard lane) is rendered the same way. During a travel (and off a city marker) the Board and the Shop are disabled. The backend contract is BE Phase 8 (`activeTravel`, `travelPreview`, `startTravel`, `serverTime`, push `travelEnd`), **merged on BE `develop`** (PR #11, PR #12 timeout fix): no lockstep wait.

Requirements: TRAVEL-01 (backend prerequisite, shipped), TRAVEL-02, TRAVEL-03, TRAVEL-04. Also wires the Phase 5 call sites left for this phase: the permission prompt (D-05) and the `travelEnd` popup registry entry (D-15).

Out of scope: cancelling or re-routing a travel (excluded by backend design, BE Phase 8 D-05), travel costs (none in the BE), the pet bonus in the dialog, quest outcomes and the return-to-city after a quest (Phase 9), the admin teleport (Phase 10), the quest countdown on screen (Phase 6 D-15 stands), iOS.

</domain>

<decisions>
## Implementation Decisions

### Trigger and confirmation sheet (TRAVEL-02)
- **D-01 (user decision):** **The trigger is the pawn drag** (the existing `Draggable` in `CharacterMarkerLayer`), not a button in the city sheet. On release the destination is the **city nearest to the release point** (existing behaviour: city whose area contains the point, otherwise `MapUtils.findNearestCity`) and the confirmation sheet opens; the legacy `CharacterCubit.changeCharacterLocation` no-op and the "drag = teleport" behaviour are removed. The pawn is **not draggable** while `status.activeTravel` is set or `quests.pendingQuest` is set (client pre-check; the backend stays the judge: an unexpected rejection goes to the banner, D-14). Tapping a city marker keeps opening the lore sheet only.
- **D-02 (user decision):** Release on the city the character already stands on (`status.location.id == City.markerLocation.id`): the pawn springs back **silently** — no `travelPreview` call, no banner.
- **D-03 (user decision):** The confirmation is a **parchment bottom sheet** (not full screen; the `PaperSheetModal` language, no `AlertDialog`) with: destination name and image (from the city lore), **distance in km**, **duration** in readable form ("2 h 40 min"; days when ≥ 24 h), **ETA** = estimated server now + duration (clock time; add the date when the arrival is not today — format at Claude's discretion), and two game-style actions **"Parti" / "Resta"**. **No cost**: BE Phase 8 has none; the "ETA + costo" wording of PROJECT.md/REQUIREMENTS is superseded and amended by the first plan. The numbers come only from `travelPreview` (owner-only, same rules and codes as `startTravel`). While the preview is in flight the sheet already shows the destination and fills the numbers when they arrive (explicit user action: a subtle in-sheet loading is allowed, never a blocking overlay — technical default). A preview rejection closes the sheet, springs the pawn back and publishes the banner (D-14).
- **D-04 (user decision):** While the sheet is open the map **draws the preview polyline** (dashed) behind it and the camera fits start and destination. "Resta", a rejection or a dismissal removes the route and springs the pawn back to the real location.
- **D-05 (user decision):** **Permission prompt:** right after `startTravel` answers `successful: true`, call `NotificationPermissionGate.ensureRequested()` once (it prompts only when the OS status is not determined). Never before the mutation, never on sheet open (Phase 5 D-10 call site). `startTravel` itself never builds state from its `CommonResponse`: the travel arrives on `characterUpdated` (Phase 6 D-03 pattern).

### Travel in progress on the Map (TRAVEL-03, TRAVEL-04)
- **D-06 (user decision):** The **whole route stays visible** for the duration of the travel, with the **travelled part in a different tone**. The polyline is parsed/measured once per `startTime` (it travels on every `characterUpdated`; BE handoff §5) and reused by the preview and the live renderer.
- **D-07:** The pawn position is interpolated along the polyline **by cumulative segment length** at `progress = clamp((now + offset − startTime) / duration, 0, 1)`, where `offset = serverTime − device now` is read from the `serverTime` query at **bootstrap and on resume** (BE handoff §5); the device clock never drives it. Smooth animation (ticker) at Claude's discretion. No client-side ETA math anywhere (TRAVEL-02/03).
- **D-08 (user decision):** A **floating label above the pawn** shows only the **remaining time** ("1 h 12 min"), then **"In arrivo…"** at progress 1. No travel paper in the corner, **no tap on the pawn** during travel, no details sheet.
- **D-09 (user decision):** **Camera:** when the Map tab is shown while a travel is active the camera frames the pawn **once**; no continuous follow and **no recenter control** (the player pans freely).
- **D-10 (user decision):** At progress 1 the pawn stays on the **last point of the route** with "In arrivo…" until the backend event (`activeTravel: null` + new `location`): the snap happens only then (TRAVEL-03). A silent character refetch a few seconds after `endTime` is at Claude's discretion and is not completion logic.
- **D-11:** **Reconstruction after a kill:** the Character snapshot of `characterUpdated` carries `activeTravel`; the same renderer resumes at the interpolated position (TRAVEL-04). Nothing about the travel is persisted on the device.

### Blocks, rejections and automatic quest travel
- **D-12 (user decision):** During a travel everything stays **readable** (city lore sheet, quest markers' read-only sheet, journal/equipment/settings). Disabled: the pawn drag, the **Board** and the **Shop**. New rule: **Board and Shop are available only while the character stands on a city marker** — on a quest POI and during any travel both satchel cells use the dark-scrim disabled visual of Phase 6 D-11/D-13 (`disabledSatchelPages` grows with the shop page index and the `activeTravel` case). The backend will enforce the shop rule too (BE Phase 9, code `SHOP_NOT_IN_CITY`; the FE stays the first filter).
- **D-13 (user decision):** **Automatic quest travel** (standard lane accepted with marker ≠ position, `pendingQuest.startDate == null`) is rendered **exactly like a free travel**: route, moving pawn, floating label. The quest paper keeps "In viaggio" (Phase 6 D-15) until `startDate` arrives; at arrival the pawn snaps and the paper label switches to the per-type label; **no banner** generated by the FE and no push from the BE (handoff §6).
- **D-14 (user decision, revised during the discussion):** Rejections of `travelPreview`/`startTravel` surface in the **Phase 5 in-app banner** with an **FE catalogue chosen by `extensions.code`** (same pattern as Phase 6 D-04; the user first picked "show the BE message verbatim", then reverted to the catalogue): `TRAVEL_IN_PROGRESS`, `TRAVEL_SAME_LOCATION`, `TRAVEL_DESTINATION_NOT_ALLOWED`, `TRAVEL_NO_PATH`, `QUEST_IN_PROGRESS`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`; connection/timeout/unknown → a generic domain line. Italian copy at Claude's discretion, starting from the BE messages (handoff §2). `TRAVEL_NO_PATH` and `TRAVEL_DESTINATION_NOT_ALLOWED` are data defects: **banner only**, the BE already logs a WARN for the GM.

### Arrival, popup and notifications
- **D-15 (user decision):** Tap on the "Viaggio completato" push (killed/background): the app lands on the Map tab (Phase 5 D-15) and the `travelEnd` entry of `defaultNotificationPopups` only **centres the camera on the pawn** — no sheet, no popup.
- **D-16 (user decision):** Arrival with the app in foreground: snap of the pawn + the Phase 5 banner ("Viaggio completato", tappable → Map). Nothing more.
- **D-17 (user decision):** Arrival of an automatic quest travel: nothing beyond the snap and the quest paper label change (D-13).

### Documents, models and contract (technical defaults)
- **D-18:** `CharacterFragment.statusFields` gains `activeTravel { road { coordinates distance } startTime endTime duration to }` (fragment-only change, Phase 3 D-05); new documents for `travelPreview(request: TravelRequest!)`, `startTravel(request: TravelRequest!)` and `serverTime`; Flutter-free Equatable models `ActiveTravel`, `TravelPath`, `TravelPreview` in `lib/models/`; `to` (POI id, not populated) is resolved against the cities already loaded by `MainScreenCubit`; `road.coordinates` is `[lon, lat]` per point (BE handoff §1) → map to `LatLng(lat, lon)`. `assets.pet` is **never selected** (handoff §11 b). The final plan verifies every document with `tool/schema_check` against `Klimmeck-Guide-BE/src/schema.gql` at `origin/develop` (`git -C <BE> fetch origin develop`, never a checkout of the BE working tree) and runs the manual E2E on the Android device with the UAT data of the BE handoff §11.
- **D-19:** Repository/Cubit shape follows the acceptance pattern of Phase 6 (`QuestAcceptanceRepository` → domain failure by code, `QuestAcceptanceCubit` + `QuestAcceptanceOutcomeListener` publishing the banner): e.g. a `TravelRepository` (preview/start, `TravelFailure` enum), a `TravelCubit` (idle → previewing → confirming → starting, rejection state) and a travel renderer fed by `CharacterCubit` (`activeTravel`) plus a clock-offset service for `serverTime`; names and files at Claude's discretion (`docs/rules/naming.md`, `architecture.md`, `state-management.md`). Cubits never call Cubits; the UI never sees exceptions.
- **D-20:** Branch **`feat/07-travel`** off `develop`, PR to `develop`, no BE lockstep. Planning docs travel with the code. Tests first (TDD): pure interpolation/offset/formatting units, bloc_test for the cubit, widget tests with fakes and recorded `QueryResult`s (patterns of Phases 3–6), never `dart format` on directories (Phase 11 D-38).

### Claude's Discretion
- Route styling (colours, dash, travelled tone), label styling, duration/ETA formatting for multi-day travels, pawn animation, the in-sheet loading while the preview is in flight, the optional refetch at progress 1, the clock-offset service shape, exact file/class names, drag threshold details, the quest-marker read-only sheet during travel (unchanged from Phase 6).

</decisions>

<specifics>
## Specific Ideas

- User (2026-10-24): the destination is chosen by **dragging the pawn** onto a city ("Drag della pedina sulla città (gesto esistente)"), nearest city to the release point, always.
- User: confirmation = parchment sheet with city, distance, duration, ETA, "Parti"/"Resta"; the route is drawn behind it; the permission prompt comes **after** a successful "Parti".
- User: route visible for the whole travel with the travelled part in a different tone; **remaining time floats above the pawn**; no follow, no recenter control, no tap on the pawn, no details sheet; "In arrivo…" while waiting for the backend event.
- User: "Disabilitare anche il negozio durante il viaggio" and then "Sì: negozio solo in città, come la Bacheca".
- User: automatic quest travel rendered exactly like a free travel.
- User on the rejection copy: first "Mostrare il messaggio del BE così com'è", then "Ho cambiato idea, fai un catalogo anche in questo caso".
- User on the arrival: "Solo camera sulla pedina, nessun popup"; foreground: snap + banner only; quest arrival: nothing more.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contract (consumed verbatim, merged on BE `develop`)
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` — §0 TL;DR, §1 SDL (`ActiveTravel`, `TravelPath`, `TravelPreview`, `TravelRequest`, `serverTime`), §2 rejection codes and evaluation order, §3 semantics (city-only destinations, automatic quest travel), §4 preview and dialog (ETA = server now + duration), §5 interpolation and reconstruction, §6 completion/sweep/push, §8 duration scale, §11 UAT data (quests, pet, roads) and checklist (d).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/08-travel-lifecycle-travel-01/08-CONTEXT.md` — D-01..D-15 (destinations, speed, polyline, completion, push), D-18/D-19 (owner-only, codes), D-26..D-32 (Phase 7 amendments already consumed by FE Phase 6).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/07-quest-lanes-quest-04/BACKEND-NOTES.md` — §5 `serverTime` and the device↔server offset.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` — the schema wins over every document (read at `origin/develop`).

### Roadmap, requirements, project
- `.planning/ROADMAP.md` §"Phase 7: Travel" — goal, success criteria 1–4, dependencies (Phases 3, 5, 6).
- `.planning/REQUIREMENTS.md` — TRAVEL-01..TRAVEL-04 (TRAVEL-02 "Open Questions" resolved here: D-01..D-05; "cost" absent by BE design), Out of Scope rows on travel (no client ETA/completion/multi-hop logic).
- `.planning/PROJECT.md` — core value, "Viaggio con conferma (ETA + costo)" target feature to amend (no cost), UX principles (immersive, no chrome, no blocking loading).
- `.planning/STATE.md` — Open Questions (TRAVEL-02 dialog resolved by this discussion).

### Prior FE phases (binding decisions)
- `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` — D-04 (push payload, `id` = characterId for `travelEnd`), D-10 (permission gate: the only call site is the first travel confirmation), D-15 (tap → Map tab, popup registry left empty), D-17/D-18 (in-app banner).
- `.planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md` — §"Popup di contesto" (registry entry for `travelEnd`), banner dedup rules.
- `.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` — D-03 (navigation only on `successful: true`, state only from subscriptions), D-04 (banner by `extensions.code`), D-07/D-15 (quest paper on the Map and the "In viaggio" label), D-11/D-13 (Board only on a city marker, disabled visual reused by the travel case), D-14 (fragment conventions), D-16 (schema check and E2E pattern), D-20 (G2: "on a city marker" = `status.location.id == City.markerLocation.id`).
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — D-05 (`activeTravel` deferred to this phase; fragment-only changes), subscription/reconnect contract.

### Rules
- `docs/rules/ui-ux.md` — immersive gameplay, "Travel conferma: modal con ETA" (cost no longer applies), no blocking loading, error-state rules.
- `docs/rules/graphql.md`, `docs/rules/state-management.md`, `docs/rules/architecture.md`, `docs/rules/naming.md`, `docs/rules/testing.md`, `docs/rules/assets.md`, `docs/rules/workflow.md`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart` — the `Draggable` pawn with `_handleDragUpdate`/`_handleDragEnd` (city containment → nearest city) and the map auto-pan while dragging (`world_map.dart` `_handleCharacterDragUpdate`/`_animateMapTo`): the trigger of D-01 lives here; `onDragEnd` today calls the no-op `changeCharacterLocation` (to remove).
- `lib/screens/mainScreen/tabs/map/utils/map_utils.dart` — `findCityContainingPoint`, `findNearestCity`, `clampToBounds`, `LatLngTween` (reusable for the pawn animation).
- `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart` + `lib/models/quest/quest_state_label.dart` — the "In viaggio" label (`startDate == null`) already in place for D-13.
- `lib/screens/mainScreen/tabs/map/components/city_modal.dart` + `lib/shared/components/modal/paper_sheet_modal.dart` — the parchment bottom sheet language for the confirmation (D-03); `lib/shared/components/modal/destructive_confirmation_dialog.dart` is a utility-surface dialog, **not** for gameplay.
- `lib/repository/quest_acceptance_repository.dart`, `lib/repository/quest_acceptance_failure.dart`, `lib/screens/mainScreen/questAcceptanceCubit/*`, `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart` — the mutation → failure-by-code → banner pattern to mirror (D-14, D-19); `travelInProgressCode` already exists there.
- `lib/repository/services/push/notification_permission_gate.dart` (`ensureRequested()`) — D-05 call site; `lib/screens/mainScreen/components/notification_popup_registry.dart` (`defaultNotificationPopups`, empty) + `notification_intent_landing.dart` — D-15 entry.
- `lib/screens/mainScreen/components/satchel_availability.dart` (`disabledSatchelPages`), `satchel_layout.dart` (`boardPageIndex = 4`; the shop entry index to add), `lib/models/quest/board_policy.dart` (`isOnCityMarker`, `currentCityOf`) — D-12.
- `lib/graphql/fragments/character_fragment.dart` (`statusFields`), `lib/graphql/queries/*.dart`, `lib/graphql/mutations/quest_mutations.dart` — document conventions; `lib/repository/services/graphql/graphql.dart` (`performQuery`/`performMutation`, `subscribeToCharacter`).
- `lib/screens/mainScreen/characterCubit/character_cubit.dart` — `CharacterLoaded(character)` stream consumed by every layer; `lib/models/character/character_status.dart` (add `activeTravel`), `lib/models/point_of_interest.dart` (`LatLng` parsing: note the `[lat, lon]` order there vs `[lon, lat]` of the BE polyline).
- `lib/screens/mainScreen/tabs/map/utils/map_constants.dart` — zoom thresholds, animation durations, pawn size.
- `tool/schema_check` — document verification against the BE schema (Phase 6 D-16).
- `pubspec.yaml` — `flutter_map ^8.2.1` (`PolylineLayer`, `MarkerLayer`, `MapController.fitCamera`), `latlong2 ^0.9.1` (`Distance` for segment lengths), `intl` (time formatting), `bloc_test`, `mocktail`, `fake_async`.

### Established Patterns
- State only from subscriptions: mutations return `CommonResponse`, the UI reacts to `characterUpdated` (Phase 3/6).
- Rejections mapped by `extensions.code` into a domain failure in the Repository, surfaced by a `BlocListener` through `InAppNotificationsCubit.publishNotice` (Phase 6 D-20 C1).
- Gameplay screens without chrome; parchment/ink theme in `lib/theme/kg_theme.dart`; `CachedSvg` for Cloudinary assets; `auto_size_text` for variable strings.
- Satchel availability computed in `MainScreen` from `CharacterCubit` location + cities (`BlocSelector`), passed to `MenuBackground`/`SatchelMenu` as `disabledPages`.
- Tests with fakes/recorded `QueryResult`s, `bloc_test`, widget tests per layer; `flutter analyze` clean; `dart format` only on touched files.

### Integration Points
- `WorldMap` (`world_map.dart`): new route layer (preview + live), the confirmation sheet presentation, the pawn renderer switch (draggable idle vs interpolated travelling), camera framing on tab show (D-09).
- `MainScreen`: `disabledSatchelPages` with the shop index and the travel case (D-12); `NotificationIntentLanding` popups map with the `travelEnd` recenter entry (D-15).
- `AuthenticatedShell`/bootstrap + resume hooks (Phase 3 `AppLifecycleEvents`, `UserRefreshRequests`): `serverTime` offset refresh (D-07).
- `CharacterStatus.fromJson` + `CharacterFragment.statusFields`: `activeTravel` (D-18).
- Settings: no change (the permission hint row of Phase 5 already exists).

</code_context>

<deferred>
## Deferred Ideas

- **Backend shop guard** — `doTransaction` rejected off a city marker or during a travel (`SHOP_NOT_IN_CITY`): agreed for **BE Phase 9** (BE 09-CONTEXT D-18). The FE rule of D-12 ships first.
- **Travel details sheet on pawn tap / recenter control / arrival popup with the city lore / "Segnalalo al locandiere" copy / pet bonus line in the dialog** — all declined by the user for this phase; may return later.
- **Travel cost** — none by BE design (Phase 8); not planned.
- **Cancel or re-route a travel** — excluded by backend design (BE Phase 8 D-05).
- **Push for automatic quest travel** — excluded (BE Phase 8 D-14).
- **Return to the city after a quest** (free travel chosen by the player from the quest marker) and the "awaiting aid" state that blocks travel — BE/FE Phase 9.
- **Admin teleport UI** — FE Phase 10 (backend already shipped).
- **Quest countdown on screen** — stays dropped (Phase 6 D-15).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 07-travel*
*Context gathered: 2026-10-24*
