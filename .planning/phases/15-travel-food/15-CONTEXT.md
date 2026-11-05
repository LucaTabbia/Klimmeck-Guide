# Phase 15: Travel Food - Context

**Gathered:** 2026-11-05 (joint interactive discuss with the BE Phase 14, from this repo; branch `feat/15-travel-food` from `develop` `08bd1a1`, the merge of PR #40)
**Amended:** 2026-11-05 after the research (`15-RESEARCH.md`, C1–C5, Open Questions 1–8): D-03, D-04, D-05, D-08 revised; D-10..D-13 added. This CONTEXT is authoritative over the RESEARCH where they differ.
**Status:** Ready for planning — no UI phase, no UI-SPEC (every visual is provisional, user-reviewed on the device); the plans that select the new contract names and the device E2E are **gated by the BE Phase 14 merge** on BE `develop` (pattern 13-10 / 14-10); every other plan runs before it on mocks and fixtures with the names fixed in the BE CONTEXT (`../Klimmeck-Guide-BE/.planning/phases/14-viaggio-e-cibo/14-CONTEXT.md`) and its `14-REPO-RULES.md`.

<domain>
## Phase Boundary

Travelling costs food, and the player sees the cost before committing. The travel confirmation sheet (Phase 7) shows, from `travelPreview`, the food the backend will eat and the life lost on the uncovered kilometres; the combat and service quest sheets show the same cost for the automatic travel to the marker, from a new owner-only acceptance preview; when the backend says the character would not arrive alive, «Parti» and the accept swipe are disabled and the sheet explains «Non hai cibo a sufficienza per il viaggio»; a starvation refusal at departure (`TRAVEL_STARVING`) keeps the confirmation sheet open with a refreshed preview, or recomposes the torn quest sheet, and the in-app banner explains it. Inventory and HP change only through `characterUpdated` (Journal «Oggetti» and «Punti vita»); the frontend computes nothing (1 power = 3 minutes of march, minimum-waste selection, the n-th uncovered km costs n HP, departure refused under 1 HP: all server rules).

Out of scope: any client-side food or HP arithmetic, choosing which food to eat, feedback after the departure, HP on the Map, teleport and instant jump (unchanged, no cost), the ambush report (Phase 16), the narrative sheets (story/worldMission have no travel).

</domain>

<decisions>
## Implementation Decisions

### Contract consumed (FOOD-01, FOOD-02, FOOD-04)
- **D-01 (BE Phase 14 CONTEXT D-08/D-09, names final in the BE REPO-RULES and handoff):** `TravelPreview` gains, additively, `food: List<TravelFoodItem>` (`TravelFoodItem { item, quantity }` with `item` a `LootItem` carrying at least `id` and `name`), `hpLost: int` and `arrivesAlive: bool`; `GetTravelPreview` selects them. New document `GetQuestTravelPreview` for the owner-only query (e.g. `questTravelPreview(request: { id, questId })`) returning the **same `TravelPreview` type, nullable**: `null` means the acceptance involves no travel (marker = position, or an instant jump) and no line is shown. The registry grows to 45 documents and the schema check runs after the BE merge. Parsing stays tolerant (Phase 13 rule): a malformed `food` entry is dropped, a missing `food`/`hpLost`/`arrivesAlive` reads as empty / 0 / true so an older BE still renders the sheet. Models stay Flutter-free Equatable in `lib/models/travel/`.

### Travel confirmation sheet (FOOD-01, FOOD-03)
- **D-02 (user decision):** **two rows under «Arrivo»** in the parchment sheet (`TravelConfirmationSheet`, same `_numberRow` language): «Cibo» = the BE list in BE order in the «Nx nome» format («1x Razione da viaggio, 1x Mela selvatica», wrapping) or «nessuno»; «Vita» = «−136 HP» or «nessuna perdita». Placeholders («…») until the preview answers, exactly as Distanza/Durata/Arrivo today. When `arrivesAlive == false` the «Vita» row turns **red** with the user's phrase **«Non hai cibo a sufficienza per il viaggio»** and **«Parti» is disabled** («Resta» stays). Nothing is computed on the client.
- **D-03 (user decision — «foglio aperto con anteprima rinfrescata», confirmed «solo per la fame»):** when `startTravel` is refused with `TRAVEL_STARVING` the sheet **stays open and the cubit re-requests the preview** (new quote: rows updated, «Parti» disabled if still starving); the banner is published as for every refusal. **Every other start refusal keeps the Phase 7 D-14 behaviour** (sheet closed, banner). The route preview on the map stays while the sheet is open. **Revised after the research (C1, OQ3, OQ6):** the re-preview runs through a new state **`TravelRequoting`** (a `TravelQuote` subclass that keeps the last quote): Starting → Requoting → Confirming under the existing `_previewToken`; the outcome listener announces the banner on entering Requoting (`previous is! TravelRequoting`, so the clock-sync re-emit does not repeat it) and does **not** `reset()`; the route layer and the pawn layer treat Requoting like any quote (otherwise the route would vanish and the pawn would snap back); the sheet keeps the old numbers with «Parti» disabled until the new quote arrives (no placeholder flash); the camera refit in `world_map.dart` is narrowed to `previous is! TravelQuote && current is TravelConfirming`.

### Quest sheet, combat and service families (FOOD-02, FOOD-03)
- **D-04 (user decision):** **one compact line in the costs block** (where the narrative family shows «Punti canale»): «Viaggio: 1x Razione da viaggio · nessuna perdita», «Viaggio: nessun cibo · −136 HP», or red «Viaggio: Non hai cibo a sufficienza per il viaggio» with the **accept swipe disabled** — **revised after the research (C2):** through `canTear: false` (the paper resists with the haptic, as every other non-acceptable quest since Phase 6 D-11), not `isEnabled: false` (which means «request in flight») — **confirmed by the user on 2026-11-05 («Resiste con vibrazione»)**. The line is **absent** while the preview is pending (no spinner), when the preview is `null` (no travel), when the preview fails (any failure: no banner, the swipe stays as today and the BE refusal remains the defence) and on read-only sheets (map overlay, busy lane, during a travel). The preview is requested when the sheet opens from the Board and the swipe would be available — **revised after the research:** `canAccept` **and** the quest on the standard lane (an eligible story is acceptable too but never travels). Narrative sheets unchanged.
- **D-05 (user decision):** a `TRAVEL_STARVING` refusal of `acceptQuest` **recomposes the torn sheet** with today's mechanism (`TearablePaperState.recompose()`, Phase 6 D-03) and publishes the banner; no board reread. **Revised after the research (OQ2):** the recompose and the banner need no new Board code (already in place for every `QuestAcceptanceFailed`); on the starving refusal the per-sheet preview cubit **refreshes the preview** (line and swipe follow the new answer), the mirror of D-03 — not a board reread — **confirmed by the user on 2026-11-05 («Sì, rinfresca l'anteprima»)**.

### Copy and banners (FOOD-03)
- **D-06 (user decision, verbatim):** the phrase **«Non hai cibo a sufficienza per il viaggio»** is used everywhere: the red «Vita» row, the red «Viaggio» line and the body of both banners («Viaggio non partito» / «Missione non accettata»). `TravelFailure.starving` and `QuestAcceptanceFailure.starving` map `TRAVEL_STARVING`; dedup keys as today.

### After the departure (FOOD-04)
- **D-07 (user decision):** **no feedback after the departure**: the pawn leaves as today; the Journal shows the reduced food («Oggetti») and HP («Punti vita») through `characterUpdated`. The ROADMAP's «the Map the reduced HP» is read as the Journal: the Map renders no HP (research fact).

### Technical defaults (for the veto)
- **D-08:** a dedicated repository method (`TravelRepository.previewQuest(characterId, questId)` or equivalent, 15 s timeout, same `_guard`) and a small per-sheet cubit (e.g. `QuestTravelPreviewCubit`: idle → loading → loaded(preview?) / failed) provided by the Board when it opens an interactive sheet; `QuestSheetDetails` gains a pure travel-line model (text, isStarving) built from the preview; `TravelCubit` gains `TravelRequoting` (D-03 revised). **Revised after the research (C3, OQ8):** `AuthenticatedShell` provides a `RepositoryProvider<TravelRepository>` (today the repository is built inline in the `TravelCubit` provider and the Board cannot reach it); `TravelCubit` reads it too (one instance); the per-sheet `QuestTravelPreviewCubit` lives in the keyed sheet subtree of the Board (`board.dart:260`) and a listener inside that subtree calls `refresh()` on the starving refusal (D-05).
- **D-09:** gating (pattern 13-10 / 14-10): plans before the BE merge build models, documents, sheets, cubits and classifiers on mocks with the names of the BE CONTEXT/REPO-RULES; after the merge the schema gate (`origin/develop:src/schema.gql`, dump + validate of every document, full suite, analyzer) and the device E2E (`15-HUMAN-UAT.md`, human checkpoint: trip fully covered, partially covered, refused; quest automatic travel line and refusal; teleport unaffected; food seeded at the DB for the test character) run; handoff `BACKEND-NOTES.md` closes the phase. TDD red → green → refactor for every change; `dart format` only on touched files; analyzer compared with the `develop` baseline (error/warning only); no `Co-Authored-By` trailer.

### Added after the research (2026-11-05)
- **D-10 (research, OQ4/OQ5/OQ7):** the red «Vita» row shows the phrase only (no number: «−20910 HP» is meaningless when refused) — **confirmed by the user on 2026-11-05 («Solo la frase»)** — the «Cibo» row still lists what would be eaten; «Cibo» wraps with `maxLines: 3`, the quest line wraps freely (scrollable columns), no truncation logic; no cubit-side guard on `start()` when `arrivesAlive` is false (the UI gate and the BE refusal suffice).
- **D-11 (research):** the «Nx nome» format is inlined twice today (`quest_sheet_details.dart:98`, `quest_enemy.dart:99`): extract one shared `quantityLine` helper under `lib/models/` (Boy Scout) before adding the food lines; HP are rendered as `'−$hpLost HP'` with U+2212, pinned in tests.
- **D-12 (research, pinned tests to update RED first):** `test/graphql/travel_documents_test.dart:38-46` (exact `GetTravelPreview` selection), `test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart:139` (3 placeholders become 5), the registry count test (44 → 45); Wave 0: `board_test.dart` and `board_acceptance_test.dart` get the `RepositoryProvider<TravelRepository>` and a default `previewQuest` stub returning `null`; the shell test needs no change (lazy provider).
- **D-13 (research):** stale docs updated in the phase: `docs/rules/ui-ux.md` and the sheet doc comment (`travel_confirmation_sheet.dart:18`) still say «nessun costo»; ROADMAP criterion 2 («next to the channel-points line») reworded by the orchestrator on 2026-11-05 (combat and service sheets have no such line: the «Viaggio» line sits in the costs block).

### Claude's Discretion
- Copy of the non-user strings («nessuno», «nessuna perdita», row labels), the food list formatting (separator, truncation of long lists), the exact position of the «Viaggio» line inside the combat/service bodies, whether the red rows also show the numbers, cubit/model/fixture names, how the Board hands the preview to the sheet.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### BE contract (companion phase)
- `../Klimmeck-Guide-BE/.planning/phases/14-viaggio-e-cibo/14-CONTEXT.md` — D-01..D-05 (rules, for the UAT numbers), D-08 (quest preview query, nullable), D-09 (`food`, `hpLost`, `arrivesAlive`), D-10 (departure recomputes), D-11 (`TRAVEL_STARVING`)
- `../Klimmeck-Guide-BE/.planning/phases/14-viaggio-e-cibo/BACKEND-NOTES.md` — written by the BE phase: final SDL, codes, UAT data (read before the gated plans)
- `../Klimmeck-Guide-BE/.planning/phases/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §1–§4, §8 — today's `travelPreview`/`startTravel` contract and the duration scale

### Prior FE decisions carried forward
- `.planning/phases/07-travel/07-CONTEXT.md` D-01..D-05 (drag, same-city no-op, parchment sheet rows, route preview, permission prompt), D-13 (automatic quest travel rendered like a free travel), D-14 (banner catalogue by `extensions.code`), D-18/D-19 (documents, models, repository/cubit shape); `07-HUMAN-UAT.md` (UAT shape and DB tricks)
- `.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` D-03 (swipe is the confirmation, recompose on refusal), D-09 (three families), D-10 (eligibility lines)
- `.planning/phases/13-city-shops/13-CONTEXT.md` D-16 (no device run before the gated plans), `13-10-SUMMARY.md` (schema gate procedure); `.planning/phases/14-quest-generation/14-CONTEXT.md` D-13 (gating), `14-REPO-RULES.md` (model for `15-REPO-RULES.md`), `14-11-PLAN.md` (device E2E + handoff shape)

### Rules
- `docs/rules/graphql.md`, `docs/rules/state-management.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/naming.md`, `docs/rules/architecture.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart` (`_content` :76-99, `_numberRow` rows :92-94, `_numbersOf` :101-110, `_actions` :145-166, listener closing on `TravelStarted`/`TravelFailed` :57-74, «Nessun costo» comment :19)
- `lib/models/travel/travel_preview.dart` (`distance`, `duration`, `road`), `lib/graphql/queries/travel_queries.dart` (`GetTravelPreview`), `lib/graphql/mutations/travel_mutations.dart`, `lib/repository/services/graphql/graphql.dart` (`previewTravel` :640, `startTravel` :653), `lib/repository/travel_repository.dart` (`preview` :31, `start` :38, `_guard` :58-68), `lib/repository/travel_failure.dart` (enum :15-41, `travelFailureFrom` :53-70)
- `lib/screens/mainScreen/travelCubit/travel_cubit.dart` (`preview` :46-68 with `_previewToken`, `start` :70-90, `cancel`, `reset`), `travel_state.dart` (`TravelQuote` → `TravelConfirming`/`TravelStarting`, `TravelFailed(stage)`), `travel_notice.dart` (`travelNoticeFor`), `lib/screens/mainScreen/components/travel_outcome_listener.dart` (banner publish + `reset()`), `lib/screens/mainScreen/tabs/map/world_map.dart` (`_handleCharacterDragEnd` :483-500, `_showTravelConfirmation` :512-530)
- `lib/shared/components/popup/quest_info_sheet.dart` (family switch :123-126, `_combatBody` :175-197, `_serviceBody` :254-267, `_costLine` :307-319 only in `_narrativeBody` :247), `lib/models/quest/quest_sheet_details.dart` (`of` :67, `costLine` :87/:114, `questSheetFamilyOf` :21-29), `lib/models/quest/quest_cost_line.dart`, `lib/screens/mainScreen/tabs/board/board.dart` (`_onAcceptanceOutcome` :195-201, `_tearKey`, `TearablePaper(isEnabled:)` :270-295), `lib/shared/components/tear/tearable_paper.dart` (`recompose()` :74)
- `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart`, `lib/repository/quest_acceptance_repository.dart`, `lib/repository/quest_acceptance_failure.dart` (`questAcceptanceFailureFrom` :52-74), `quest_acceptance_notice.dart`, `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart`
- Items and HP: `lib/models/character/character_assets.dart` (`ownedItems`), `lib/models/loot_item.dart` (`effect`, `power`), `lib/models/enums/effect_type.dart` (`hunger` «Sazietà»), `lib/graphql/fragments/loot_fragment.dart`, `lib/screens/mainScreen/tabs/journal/journal.dart` (`_buildLifePointsSection` :86-122, `_buildOwnedItemsSection` :240-275), `character_status.dart` (`currentLifePoints`/`maxLifePoints` :36-37)
- Registry and tests: `tool/schema_check/schema_check_documents.dart` (44 documents), `test/tool/schema_check_documents_test.dart` (count at :32-33), `test/helpers/fixtures/travel_fixtures.dart` (`travelPreviewJson`), `test/helpers/mocks.dart` (`MockTravelRepository`, `MockTravelCubit`), `test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart`, `test/repository/services/graphql/graphql_travel_test.dart` (`Link.function` handler pattern)

### Established Patterns
- Failure classifier per repository reading `extensions.code`; unknown codes → `unknown` («Qualcosa è andato storto, riprova»); gameplay surfaces use the parchment banner (`InAppNotificationsCubit.publishNotice` with dedup keys)
- Preview on sheet open with placeholders, numbers only from the BE (Phase 7 D-03); the sheet never builds state from `CommonResponse`
- Gated plans with mocks first, schema gate after the BE merge (13-10 / 14-10); tolerant parsing per item (Phase 13)
- Swipe is the confirmation; `recompose()` is the rollback (Phase 6 D-03); `TearablePaper(isEnabled:)` already gates the swipe
- No UI phase: provisional visuals from the CONTEXT, token-based (`kg_theme.dart`)

### Integration Points
- `TravelPreview` is shared by the confirmation sheet and the new quest line: one model change serves both
- `TravelConfirmationSheet`'s listener closes on every `TravelFailed`: D-03 needs a starving-specific branch there and in `TravelCubit`
- `QuestInfoSheet` is used by the Board (interactive) and by the map overlay (read-only): the line and the preview request belong to the Board path only
- `schemaCheckDocuments` registry and its count test; `MockKlimmeckGraphQl`/`MockTravelRepository` stubs for the new query
- `travel_fixtures.dart` gains `food`/`hpLost`/`arrivesAlive`

</code_context>

<specifics>
## Specific Ideas

- User 2026-11-05 (verbatim): «al posto di "Non arriveresti vivo" mettiamo "Non hai cibo a sufficienza per il viaggio"» — the only user copy of the phase; everything else is provisional.
- User 2026-11-05 chose «Foglio aperto con anteprima rinfrescata» over the recommended «foglio chiuso + banner», then confirmed it applies only to the starvation refusal.
- Numbers shown to the user (BE handoff Phase 8 §8, DB of 2026-11-05): nearest city median 2.7 h ≈ 55 power / 16 km, quest marker 2.6 h ≈ 52, any city median 35 h ≈ 700 / 204 km, max 82 h ≈ 1646 / 506 km; food items 5–200 power; test characters hold 0–2 food units (the UAT seeds food at the DB).
- Facts behind the choices: the confirmation sheet closes on any failure today; the combat/service bodies have no cost line; the Map renders no HP; the registry test pins the document count.

</specifics>

<deferred>
## Deferred Ideas

- **HP on the Map** (pawn label or corner) — not in this phase; the Journal is the HP surface.
- **Food icons / item rows in the sheets** — text lines first; images later with the loot art.
- **Departure banner «Hai mangiato…»** — rejected for now (D-07).
- **Choosing the food manually** — the server chooses (BE D-05/D-06).
- **Ambush report** — Phase 16 (same result sheet pipeline).

</deferred>
