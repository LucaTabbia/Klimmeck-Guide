# Phase 16: Travel Ambushes - Context

**Gathered:** 2026-11-06 (joint interactive discuss with the BE Phase 15, from this repo; branch `feat/16-travel-ambushes` from `develop` `f560d1d`, the merge of PR #41)
**Amended:** 2026-11-06 after the research (`16-RESEARCH.md`, C1–C3, Pitfalls 1–10, Open Questions 1–7): D-02, D-05, D-08 revised; D-10..D-18 added. This CONTEXT is authoritative over the RESEARCH where they differ.
**Amended again:** 2026-11-09 during the device E2E (16-08 Task 2): D-19 added, plan 16-09 inserted while the E2E continues (carousel affordance).
**Status:** Ready for planning — no UI phase, no UI-SPEC (every visual is provisional, user-reviewed on the device); the plans that select the new contract names (`QuestResult.kind`, nullable `quest`, `ambush`, the defeat push category) and the device E2E are **gated by the BE Phase 15 merge** on BE `develop` (pattern 13-10 / 14-10 / 15-08); every other plan runs before it on mocks and fixtures with the names fixed in the BE CONTEXT (`../Klimmeck-Guide-BE/.planning/phases/15-imboscate-in-viaggio/15-CONTEXT.md`) and its `15-REPO-RULES.md`.

<domain>
## Phase Boundary

A journey can be ambushed, more than once. The frontend renders the server's decisions and computes nothing: after a lost ambush the backend rewrites `activeTravel` from the ambush point towards the nearest city and the pawn, the dashed route and the remaining time follow the new polyline live (the existing `TravelProgressCubit` rebuild), a new push category and its in-app banner announce the defeat and lead to the Map; after a victory nothing changes on the Map (HP move in the Journal through `characterUpdated`). The reports are held by the backend until the arrival (or the GM teleport) and come as `QuestResult` documents of a new kind through the never-lost pipeline (subscription, `unacknowledgedQuestResults`, ack); the app shows the reports of one travel in a carousel of result sheets, one parchment per ambush, acknowledged together on «Continua». The travel confirmation sheet and the quest «Viaggio» line never reveal an ambush.

Out of scope: any client-side ambush logic (probability, enemies, nearest city), a banner derived from the reroute itself, loot or lore from ambushes (Phase 17 handles unknown enemies), HP on the Map, GM visibility, changes to the quest result sheet for quest results, changes to the confirmation sheet beyond proving it stays mute.

</domain>

<decisions>
## Implementation Decisions

### Contract consumed (AMBUSH-01, AMBUSH-02)
- **D-01 (BE Phase 15 CONTEXT D-12/D-14, names final in the BE REPO-RULES and handoff):** `QuestResult` gains, additively, `kind: QuestResultKind!` (`quest` | `ambush`; a missing or unknown `kind` reads as `quest`, Phase 13 tolerant rule) and `ambush: AmbushReport` (`{ at, nearCity { id name }, reachedCity { id name } }`, `reachedCity` null on a victory); **`quest` becomes nullable** (null for ambushes: the FE parser requires it only when `kind == quest`; an ambush result without an `ambush` block is malformed and dropped item by item, as today). `outcome` reuses `success`/`failure`; `enemies` (with `quantity`), `hpBefore/hpAfter/maxLifePoints/injuriesAdded/rewards/xp*/level*/title*/consumablesUsed/spellsUsed` are the fields of today. `QuestResultFragment` selects the new fields; no new document (the registry stays at 45 unless the planner needs one); the schema check runs after the BE merge. Models stay Flutter-free Equatable in `lib/models/quest_result/`.
- **D-02 (user decision, «Sì, ma anche quando la città più vicina è la meta»):** **every lost ambush sends a push of a new category** (e.g. `ambushDefeat`, wire name from the BE REPO-RULES) carrying the name of the city the pawn is now heading to. `NotificationCategory` gains the value (personal, own `storageKey`/`wireType`, settings toggle «Imboscate» in the preferences section, exhaustive switch), the popup registry maps it to `focusCharacterOnMap` (Map tab, camera on the pawn, as `travelEnd`), and the foreground path publishes the **in-app banner** with the BE's `title` («Imboscata!») and `body` («Sei stato sconfitto: la via torna verso <città>») exactly as every category today. **Revised after the research (C1):** the FE parses nothing beyond `type`/`id`/`title`/`body`/`sentAt`, holds no copy of its own for this push and adds no field to `PushEvent`; the copy lives in the BE (`push-events.ts`). Unknown wire types are still dropped. **No banner or push on a victory.**

### Pawn and route during the detour (AMBUSH-01)
- **D-03 (research fact, no client guessing):** the BE rewrites `activeTravel` **from the ambush point** (`startTime` = the ambush instant, new `road`, `to`, `endTime`, `duration`); `TravelProgressCubit.follow` already rebuilds the route on any change (Equatable over all fields) and interpolates from `startTime` + `duration`, so the pawn restarts from the point towards the city with the new dashed route and remaining time; the arrival-reread ledger resets on the new identity. The phase **proves** this with a cubit/widget test on a mid-travel reroute (and fixes whatever the research finds) rather than adding a second mechanism; the abandoned quest leaves the lane through `quests.pendingQuest` → null as today.

### Report carousel (AMBUSH-02)
- **D-04 (user decision):** **the ambush report is the result sheet with an ambush header:** outcome ink and label («Vittoria» / «Sconfitta»), **«Imboscata presso <nearCity.name>»** with the date in place of the quest title and type, the existing enemies block (its doc comment already names the ambushes), the HP bar before → after, «Ferite»; **won:** «Ricompense» (coins) and «Esperienza» / «Livello» / title lines as today; **lost:** a new line **«Portato a <reachedCity.name>»** and no rewards; «Consumabili usati» / «Magie usate» when present; «Continua» confirms.
- **D-05 (user decision, verbatim «invece di mettere tutto sullo stesso foglio, fai un carosello con un foglio per ogni imboscata, così è più pulito e chiaro»):** at arrival **the ambush reports of the same travel open in one carousel** (horizontal `PageView`, one parchment per ambush, page indicator, chronological order), **«Continua» closes the carousel and acknowledges all its reports** (best effort per id, as `closed` does today); **one ambush = a one-page carousel without indicator**; **quest results stay one at a time**, after the carousel. Grouping rule (technical default): the consecutive `kind == ambush` results at the head of the FIFO queue (ordered by `resolvedAt` = the ambush instant, so they precede any quest result of the same arrival); the group is re-evaluated at every presentation. **User veto on 2026-11-06 («Chiude e conferma tutti da qualsiasi pagina»):** «Continua» closes the carousel and acknowledges every report of the group **from any page** (the research's «advance to the next page» default was rejected; the pages are browsed by swiping); the page indicator is the existing «k di N» counter (user: «Contatore «k di N» esistente»); the merge of two travels' reports in one carousel is accepted by the user (D-16).
- **D-06:** presentation rules unchanged (free Map beneath the routes, `TravelCubit` idle, death opens anywhere); since the BE holds the reports until the arrival they never open mid-travel. **No «Missione conclusa» live banner for ambush results** (the `questEnd|<id>` banner stays for quest results only): the arrival is announced by `travelEnd` (ROADMAP criterion 3) and the carousel opens by itself on the free Map.

### Confirmation sheet and arrival (AMBUSH-03)
- **D-07 (user decision, «Solo `travelEnd` come oggi»):** nothing new on the travel confirmation sheet, the quest «Viaggio» line or the previews (the BE sends nothing); the `travelEnd` push/banner tap leads to the Map (existing `focusCharacterOnMap`) where the carousel appears; after a won ambush towards a quest marker there is no push (BE) and the carousel waits in the app; the phase pins with tests that the sheet renders exactly the Phase 15 rows.

### Technical defaults (for the veto)
- **D-08:** models `QuestResultKind`, `AmbushReport`, `AmbushCity` (or equivalent) in `lib/models/quest_result/`, fixtures `ambushWonResultJson` / `ambushLostResultJson` beside the Phase 9 ones; `QuestResultsCubit` exposes the presentable group (head result or the ambush group) and acknowledges a list; `AmbushReportCarousel` (or equivalent) in `lib/shared/components/popup/` reusing the result sheet body; `QuestResultPresenter` branches on the head kind; `NotificationCategory.ambushDefeat` + settings label + popup entry + notice copy; `PushEvent` unchanged (C1); state `showingGroup` with a `showing` getter, `presentable` and `isSettlingAmbushes` on `QuestResultsCubit` (D-11/D-12); tests mirror the Phase 9/15 conventions (`quest_results_queue_test.dart`, `quest_result_presenter_test.dart`, `quest_result_sheet_test.dart`, `travel_progress_cubit_test.dart` with `fakeAsync`); `dart format` only on touched files; analyzer compared with the `develop` baseline; no `Co-Authored-By` trailer.
- **D-09:** gating (pattern 13-10 / 14-10 / 15-08): plans before the BE merge build models, parsing, carousel, category and cubit changes on mocks and fixtures with the names of the BE CONTEXT/REPO-RULES; after the merge the schema gate (`origin/develop:src/schema.gql`, dump + validate of every document, full suite, analyzer) and the device E2E (`16-HUMAN-UAT.md`, human checkpoint: won ambush → carousel at arrival with coins and XP; lost ambush → push + banner, pawn restarting towards the nearest city, quest lane freed, carousel with «Portato a»; two ambushes → two pages; confirmation sheet unchanged; DB tricks from the BE handoff: `activeTravel.ambush.at` moved back + sweep, HP seeded low) run; handoff `BACKEND-NOTES.md` closes the phase.

### Added after the research (2026-11-06)
- **D-10 (research C1):** the defeat banner and system notification render the BE's `title`/`body`; no FE copy, no `PushEvent` change, no city field. The settings toggle gates only the push/banner of the new category, never the carousel nor the reroute (Pitfall 9); the «Fine quest» toggle does not apply to ambush results.
- **D-11 (research F2, Pitfalls 1 and 8):** `QuestResultsState.showing` becomes `showingGroup: List<QuestResult>` with a `QuestResult? get showing => showingGroup.firstOrNull` getter (death path and existing tests untouched); `presentable` = the head alone, or the consecutive `isAmbush` results from the head (D-05); `presented(headId)` moves the whole group and advances `position` by the group length; `closed(headId)` closes and acknowledges every id of the group (serialised tail, best effort per id); `dismissedExternally(headId)` requeues the whole group; `_isKnown` checks every id of `showingGroup` (a refetched page 2 never re-enters the queue).
- **D-12 (research Pitfall 3, OQ2):** live batch settling: when a live `kind == ambush` result arrives, the cubit emits the merged queue with the refetch marked in flight in the same emit and runs `refetchPending()` (the BE commits all the reports of the arrival before the change stream emits, A1); the presenter never opens an ambush head while `isSettlingAmbushes` is true; a live ambush arriving during an in-flight read chains exactly one more read.
- **D-13 (research OQ4, F4):** the ambush page is `QuestResultSheet` with an ambush header («Vittoria»/«Sconfitta» ink, «Imboscata presso <nearCity.name>» + date, no quest type line) and the «Portato a <reachedCity.name>» line right after «Ferite» on a defeat; rewards/XP lines render only what the BE sends (on a defeat coins and XP are zero, A2, so no extra branch); the carousel is a `PageView` of sheets inside the existing `showGeneralDialog`, one `pop(true)` for the whole group (probe passed in landscape).
- **D-14 (research Pitfall 2):** making `quest` nullable breaks the build in `quest_result_sheet.dart` (header, two reads) and eight test lines (`quest_result_test.dart` :24-26, :65, :74, :83, :220-221, counted by the planner): the model commit fixes them in the SAME commit so the analyzer gate stays green at every commit.
- **D-15 (research Pitfall 7):** once `QuestResultFragment` selects `kind`/`ambush`, every result document (including the innkeeper `CompletePendingRequest`) fails validation on a BE without Phase 15: the branch is never run against the old BE; the device E2E runs only after the BE merge (D-09); BACKEND-NOTES says so.
- **D-16 (research C2, accepted):** reports of two different travels that are both unacknowledged merge into one carousel (there is no travel id on the wire); rare, chronological order holds; noted in BACKEND-NOTES, no BE change requested.
- **D-17 (research F7):** D-07 is pinned by tests: the confirmation sheet labels are exactly «Distanza, Durata, Arrivo, Cibo, Vita» in order with no text containing «Imbosc», and `QuestTravelLine.of` output is unchanged; the registry count test stays at 45 (proof that no document was added); the pinned tests listed in RESEARCH F7 go RED first.
- **D-19 (device E2E 2026-11-09, user):** the carousel must read as a carousel. With more than one report the pages are narrower than the viewport so the neighbours peek in from the edges (the next one on the right on page 1, the previous one on the left on any later page); on opening the carousel makes one short horizontal nudge (forward, then back on page 1) to hint the swipe. A single report keeps the full width and does not move. Still swipe-only (D-05: no buttons, no programmatic page turn — the nudge never changes page; a `PageController` is now allowed on the widget). Verbatim: «Non si campisce che sia un carosello. Metterei le pagine fuori dalla schermata parzialmente al suo interno (sia a destra sia a sinistra nel caso in cui tu sia non sulla prima) e farei un leggero movimento del carosello per far capire che si può scrollare». Plan 16-09.
- **D-18 (research Pitfalls 5–6, F7/F9):** carousel and sheet tests seed every Cloudinary SVG they render (`useSvgHttpOverrides()` + seed) or `pumpAndSettle` hangs; reroute fixtures use `[lat, lng]` like `travel_fixtures.dart`; analyzer baseline 50 info-level issues (0 error / 0 warning); the 28 files the phase touches are format-clean; full suite ≈ 3310 tests in ≈ 76 s.

### Claude's Discretion
- Copy of the non-user strings (header, «Portato a», banner title, settings label), the page indicator style, the carousel transition, whether the carousel reuses `QuestResultSheet` as a page or extracts a shared body, the group API of the cubit, fixture names, how the city name travels in the push data, the test harness shape for the reroute proof.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### BE contract (companion phase)
- `../Klimmeck-Guide-BE/.planning/phases/15-imboscate-in-viaggio/15-CONTEXT.md` — D-01..D-03 (probability model, for the UAT), D-10/D-11 (effects, nearest city, `activeTravel` rewritten from the point), D-12 (defeat push), D-13 (reports held until arrival, `resolvedAt`), D-14 (`kind`, nullable `quest`, `ambush`)
- `../Klimmeck-Guide-BE/.planning/phases/15-imboscate-in-viaggio/BACKEND-NOTES.md` — written by the BE phase: final SDL, push payload, UAT data (read before the gated plans)
- `../Klimmeck-Guide-BE/.planning/phases/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §3, §5, §6 — travel semantics, interpolation by length, completion and `travelEnd`
- `../Klimmeck-Guide-BE/.planning/phases/09.2-quest-result-delivery-contract/BACKEND-NOTES.md` — delivery and ack contract consumed today

### Prior FE decisions carried forward
- `.planning/phases/07-travel/07-CONTEXT.md` D-06..D-10 (pawn interpolation, dashed route, arrival snap), `07-HUMAN-UAT.md` (DB tricks for travels)
- `.planning/phases/09-combat-result-sheet/09-CONTEXT.md` (sheet sections, FIFO queue, ack on close, presentation on the free Map, banner gating), `09-HUMAN-UAT.md`
- `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` (push categories, settings toggles, tap routing)
- `.planning/phases/15-travel-food/15-CONTEXT.md` D-09 (gating), `15-REPO-RULES.md` (model for `16-REPO-RULES.md`), `15-09-PLAN.md` (device E2E + handoff shape), `15-08-PLAN.md` (schema gate)

### Rules
- `docs/rules/graphql.md`, `docs/rules/state-management.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/naming.md`, `docs/rules/architecture.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Travel: `lib/models/travel/active_travel.dart` (`road`, `startTime`, `endTime`, `duration`, `to`; `tryFromJson`), `lib/models/travel/travel_route.dart` (`pointAt`, `travelProgress` :93-101 from `startTime` + `duration`), `lib/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart` (`follow` :50-56 rebuilds on any change, 1 s ticker, `arrivalRefetchDelays`), `arrival_reread_ledger.dart` (identity `startTime`+`endTime`+`to`), `layers/travel_route_layer.dart` (solid travelled + dashed remaining), `layers/character_marker_layer.dart` :117-153 (remaining-time label), `world_map.dart` :100-106, :190-201, :387-391, :421-427
- Results: `lib/models/quest_result/quest_result.dart` (:44-81 fields, `quest` cast :99, injuries dropped when unknown :149-154, `tryFromJson` :129-136), `quest_outcome.dart` (`fromWire` strict), `quest_result_quest.dart`, `lib/shared/components/popup/quest_result_sheet.dart` (`_content` :149-169, header :171-198, `_enemies` :228-253 «Stesso blocco per le imboscate (Phase 16)», `HpDeltaBar` :256-288, «Ferite» :290-296, counter and «Continua» :447-457), `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart` (FIFO by `resolvedAt`, `presented` :122, `closed` :136-147, `requestFromTap` :102), `lib/screens/mainScreen/components/quest_result_presenter.dart` (`_canPresent` :145-163, `showGeneralDialog` :171-200, `questEnd|<id>` banner `_announceArrival` :111-123; `_announceNotice` :130-140 untouched), `lib/graphql/fragments/quest_result_fragment.dart`, `quest_result_queries.dart`, `quest_result_mutations.dart`, `quest_result_subscriptions.dart`, `lib/repository/services/graphql/graphql.dart` :145-185 (per-item parsing), `lib/repository/quest_result_repository.dart`
- Push: `lib/models/notification_category.dart` :3-29 (`fromWireType` drops unknown), `lib/models/push_event.dart` :27-45 (dedup `type|id`), `lib/models/notification_intent.dart`, `lib/repository/services/push/notification_tap_router.dart` :21-29, `notification_intent_landing.dart`, `lib/screens/mainScreen/components/notification_popup_registry.dart` :15-22, `lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart` :45-48 (exhaustive switch), `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart` :51
- Confirmation sheet and quest line (to pin unchanged): `lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart` :104-116, `lib/models/quest/quest_travel_line.dart`, `lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/`
- Journal: `lib/screens/mainScreen/tabs/journal/journal.dart` («Punti vita» :86-104, «Ferite» :141-160), `lib/models/enums/injury_type.dart`
- Registry and tests: `tool/schema_check/schema_check_documents.dart` (45 documents, changelog comment :30-40), `test/tool/schema_check_documents_test.dart` :32-33, `test/helpers/fixtures/quest_result_fixtures.dart` (`questResultJson` :51, `questResult(json)` :243), `test/helpers/fixtures/travel_fixtures.dart` (`activeTravelJson` :17, `travellingCharacterJson` :67), `test/helpers/mocks.dart` (`MockQuestResultRepository`, `MockQuestResultsCubit`, `MockTravelProgressCubit`), `test/helpers/fakes/fake_pending_quest_results.dart`, `recording_quest_result_acknowledger.dart`, `fake_server_clock_service.dart`, `test/screens/mainScreen/questResultsCubit/quest_results_queue_test.dart`, `test/screens/mainScreen/components/quest_result_presenter_test.dart`, `test/shared/components/popup/quest_result_sheet_test.dart`, `test/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit_test.dart`

### Established Patterns
- Tolerant parsing per item (Phase 13): malformed entries dropped, unknown enum values map to a safe default or drop the item; `QuestOutcome.fromWire` is strict today (a new outcome would drop the result): the phase keeps `success`/`failure` and adds `kind`
- Push categories are an enum with `storageKey`/`wireType`, a settings toggle and a popup entry; unknown wire types dropped (Phase 5)
- Result sheets are presented one at a time on the free Map, acked on `pop(true)` (Phase 9); live arrivals publish a banner gated by the «Fine quest» toggle
- Gated plans with mocks first, schema gate after the BE merge (13-10 / 14-10 / 15-08); no UI phase, provisional visuals from the CONTEXT, token-based (`kg_theme.dart`)
- The pawn interpolates by length from `startTime` + `duration` on server time; a new `ActiveTravel` is taken as-is (Phase 7)

### Integration Points
- `QuestResult` model + fragment: `kind`, nullable `quest`, `ambush` serve the carousel, the presenter and the queue
- `QuestResultsCubit` → `QuestResultPresenter`: the group (ambush carousel) is the new unit of presentation and of acknowledgement
- `NotificationCategory` → settings section, popup registry, tap router, in-app banner: one new value threads through all four
- `TravelProgressCubit.follow` is the reroute entry point: a test proves the restart from the ambush point
- `schemaCheckDocuments` registry and the `QuestResultFragment` selection tests pin the new fields

</code_context>

<specifics>
## Specific Ideas

- User 2026-11-06 (verbatim): «Nel caso in cui tu venga sconfitto (e quindi deviato verso un paese diverso da quello della metà) vorrei una notifica e un banner nuovo» — then widened to every defeat («Sì, ma anche quando la città più vicina è la meta»).
- User 2026-11-06 (verbatim): «invece di mettere tutto sullo stesso foglio, fai un carosello con un foglio per ogni imboscata, così è più pulito e chiaro».
- User 2026-11-06 kept «Tutto all'arrivo (decisione del 29/10)» over the recommended «Ogni report subito» and chose «Solo `travelEnd` come oggi» for the arrival push.
- Facts behind the choices (research 2026-11-06): `QuestResult.quest` is non-null and parsed with a cast; `QuestOutcome.fromWire` returns null on unknown values and the result is dropped; the pawn interpolates from `startTime` + `duration`, so the BE rewrites the travel from the ambush point; all 642 POIs belong to a city («presso <città>» as the quest titles).

</specifics>

<deferred>
## Deferred Ideas

- **Banner derived from the reroute on the client** (when the push does not arrive) — not in this phase; the push category is the channel.
- **Unknown-enemy darkened portraits on the ambush sheet** — Phase 17 (Unlockable Lore).
- **HP on the Map** — still the Journal.
- **Loot from ambushes** — none by BE decision.
- **Dedicated darker sheet for ambushes** — offered, not chosen (D-04).
- **Per-page acknowledgement in the carousel** — offered, not chosen (D-05).

</deferred>

---

*Phase: 16-travel-ambushes*
*Context gathered: 2026-11-06*
