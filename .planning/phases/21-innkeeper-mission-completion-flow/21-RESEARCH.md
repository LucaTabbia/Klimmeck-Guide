# Phase 21: Innkeeper Mission Completion Flow - Research

**Researched:** 2026-11-13
**Domain:** Flutter utility wizard over a backend-owned mission draft (BE Phase 22 «Completamento guidato delle missioni»), Map teleport widened to inner POIs, players' «Missione in corso» lock across every gameplay entry point
**Confidence:** HIGH for code facts (file:line read this session on `feat/21-innkeeper-mission-completion` at `eacdf70b`; analyzer run: `47 issues found`, 0 error / 0 warning; 89 candidate files checked formatter-clean one by one; two probes run and deleted); MEDIUM for the wire shape (BE research in progress, `22-RESEARCH.md` not yet written when this file was produced: every new name below is the orchestrator's DRAFT from `21-REPO-RULES.md`, **BE to confirm**; BE SDL read on the BE working tree `feat/22-completamento-guidato-missioni` `bf3e39c8`, identical in `src/` to BE `develop` `c6079ca3`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `21-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **D-01** Step 1 — the group is moved with the Phase 10 Map drag (pawn «Gruppo · N», «Modalità Locanda»), the drop accepts **city markers and inner POIs** (supersedes Phase 10 D-16); skippable when the group is already at the chosen place; the place sets the POI types of step 2.
- **D-02** One fight or several in sequence, each with one or several enemies (kind + quantity with a stepper); each fight starts from the state left by the previous one after its corrections.
- **D-03** Enemy list filtered by default on the place's POI types (+ habitat `city`) and on the XP band of the mission's rank; the 22 legendaries available for worldMission; toggle «Mostra tutti».
- **D-04** Simulation on the BE combat engine with the characters' real state, writes nothing; returns per character verdict, HP after, injuries added, consumables and spells used.
- **D-05** On a simulated defeat: re-run or change the enemies, then correct by hand; the mission always ends completed (no reject, no failure, no aid).
- **D-06** Corrections per character after each simulated fight: remove injuries in excess, life by slider, correct consumables and spells used; adding an injury stays possible.
- **D-07** Prizes per character prefilled with the rank block of the character's title; remove entries or add from the catalogue filtered by the rank (rarity ceiling, pets same ceiling, spells only ≥ mage with the required xp); enemy xp, companion xp and victory lore from the chosen enemies.
- **D-08** «Completa» sends the final corrected state, the fights and the prizes; one BE transaction; players get the usual result sheet with the enemies faced; explicit confirmation with a recap (Phase 10 D-11).
- **D-09** Draft saved on the BE on the request (step, place, fights and enemies, simulation results, corrections, prizes); reopening the Locanda, also from another device, resumes it; the teleport is real as soon as it is done.
- **D-10** Players see the teleport, a «Missione in corso» notice and the final result; simulations, corrections and the draft stay invisible to them.
- **D-11** From draft created to result arrived the participants are locked: no travel start, no quest acceptance (BE refusal with its own code; FE shows the notice and hides/disables the actions); released at completion or discard; shop buy/sell, equipment and companion changes, spell equip and potions locked too.
- **D-12** The same lock for every normal mission from the effective start (standard lane: arrival at the quest; boss/registered: party started) until the result; one BE rule, one FE notice.

### Claude's Discretion
- Wizard layout (stepper, pages, back navigation between steps), copy, loaders (explicit actions: allowed), how the fights list is edited, recap content.
- Whether a corrected fight must be re-simulated after changing the enemies (recommended: changing the enemies of a fight invalidates its simulation and the following ones).
- Wire shape of the draft and of the mutations (decided with the BE companion).

### Deferred Ideas (OUT OF SCOPE)
- None beyond the user's own turn-based engine (it plugs into the same `CombatResolver`).
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs exist yet (`.planning/REQUIREMENTS.md:73` coverage stops at RANKP; ROADMAP §Phase 21 has none). Proposed IDs (to be added to `REQUIREMENTS.md` + traceability by the orchestrator or in the first plan, before any plan references them — `gsd-tools requirements mark-complete` fails on unknown IDs, Phase 20 Pitfall 11):

| ID (proposed) | Description | Decisions | Research Support |
|----|-------------|-----------|------------------|
| GMFLOW-01 | Step 1: the group pawn drops on city markers **and inner POIs** (POI layer in teleport mode, drop rule, no call on the current place); skip when the whole group already stands on one place; after the Map round trip the Locanda reopens **the wizard** of that request | D-01 | F-2, F-3 |
| GMFLOW-02 | Wizard shell over the **served draft**: explicit start, resume at the served step from any device, back navigation between steps, discard with confirmation, exits on `NOT_FOUND`/`FORBIDDEN`/request gone; no local persistence | D-09, D-11 | F-1, F-4 |
| GMFLOW-03 | Encounters: one or several fights, each with enemies × quantity picked from the served `missionEnemies` list (search by name, «Mostra tutti»); the FE never filters by rank, habitat or POI type | D-02, D-03 | F-5 |
| GMFLOW-04 | Per fight: «Simula» / «Rilancia» on the BE engine, per-character outcome read as served, corrections (life slider `1..max`, injuries removable/addable, consumables and spells steppers within served bounds); invalidation after an enemy change shown from the served draft | D-02, D-04, D-05, D-06 | F-6 |
| GMFLOW-05 | Prizes per character: prefilled served rank block, remove entries, add from the served catalogue (items, pets, spells; long lists), the FE never filters by rank | D-07 | F-7 |
| GMFLOW-06 | Completion: recap + explicit confirmation, `completeGuidedMission`, results recap (Phase 10 D-13 dialog reused), failure mapping per code; the Phase 10 override form is retired | D-05, D-08 | F-8 |
| GMFLOW-07 | Players: `CharacterStatus.missionInProgress` read live; one in-world «Missione in corso» notice; travel start, quest acceptance, shop, equipment, companion, spell equip and potions hidden/disabled; `MISSION_IN_PROGRESS` mapped to one Italian line in every classifier of the locked actions | D-10, D-11, D-12 | F-9, F-10 |
| GMFLOW-08 | Schema gate on the merged BE Phase 22 SDL (names, types, nullability), schema check N × OK, full suite, device E2E with an innkeeper and a participant | all | F-11, Validation |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Clean Code, SoC (models Flutter-free, UI no networking, Cubit no `BuildContext`, Repository no `BuildContext`), **TDD red → green → refactor**, Boy Scout rule within scope.
- Rule 1 — no app chrome outside utility screens: the Locanda and the wizard are utility (Phase 10 D-01/D-22: `Scaffold`/`AppBar`/Material controls allowed); the Map in teleport mode and every player screen are **gameplay** (no Material dialog, no AppBar; notice in-world).
- Rule 2 — no blocking loading in session: the players' lock arrives silently with the character stream; loaders only on the innkeeper's explicit actions (open, start, simulate, save, complete).
- Rule 3 — branch `feat/21-innkeeper-mission-completion`, PR → `develop`, never push to `develop`/`main`.
- Rule 4 — **backend is the source of truth**: the FE never simulates, never filters enemies or prizes by rank/habitat/POI, never computes HP, injuries, bounds, prizes or invalidation, never decides that a character is locked from local state.
- Rule 5 — no secrets in repo.
- `docs/rules/graphql.md`: documents only in `lib/graphql/{queries,mutations,subscriptions,fragments}`, named operations (`GetXxx`/`ListXxx`, imperative mutations), one fragment per reused entity, `OperationException` never reaches the UI (repository classifier). `docs/rules/state-management.md`: one responsibility per Cubit, `Equatable` states with full `props`, a Cubit never calls a Cubit (orchestration in the UI via `BlocListener`), `bloc_test` for every non-trivial Cubit. `docs/rules/naming.md`: `snake_case.dart`, lowerCamelCase state folders (`missionDraftCubit/`), `Screen` suffix, booleans `isX/hasX/canX`. `docs/rules/ui-ux.md`: theme tokens only, long lists `ListView.builder`, tap targets ≥ 44, domain SVG through `CachedSvg`. `docs/rules/testing.md`: new model → `fromJson`/`Equatable` tests first; fixtures under `test/helpers/fixtures/`.
- Repo practice (`21-REPO-RULES.md`): sequential plans on the main tree, `dart format` per touched file only, analyzer gate 47 info / 0 warning / 0 error, full suite only in the gate plan (baseline 4339), no commit trailers, scope `phase-21`, BE read-only, `pubspec.lock` never staged, registry 46 today and every new document registered in the plan that adds it.

## Summary

**(1) The Phase 10 form is one Cubit over locally-built drafts; the wizard is a different animal and should be new files, not an in-place rewrite.** Today «Completa» (`request_card_view.dart:84-91`) → `InnkeeperPanelScreen._complete` (`innkeeper_panel_screen.dart:160-181`) → `openRequestCompletion` pushes a `MaterialPageRoute` with `RequestCompletionCubit` (`request_completion_route.dart:45-66`) → `load()` reads every participant with `character(id)` and builds `ParticipantDraft`s locally (`request_completion_cubit.dart:31-50, :95-109`, `participant_draft.dart:66-107`) → `submit()` sends `CompletePendingRequestInput` with only changed participants (`:72-93`) → the route pops a `CompletionExit` and the panel shows `showResultsRecap` (`results_recap_dialog.dart:8-40`). The wizard's state is the **served `MissionDraft`** (D-09, REPO-RULES), so the model, the Cubit and the screen change shape completely; the pre-gate plans must also keep the old form working against today's BE. Recommended: new `lib/screens/innkeeper/missionCompletion/**` + `lib/models/mission/**`, wired to «Completa» only in the gated plan, where the old form, its Cubit, `ParticipantDraft`/`ParticipantOverride`/`CompletePendingRequestInput` and the `CompletePendingRequest` document are deleted RED-first. Reusable as they are: `QuantityStepper`, the results recap dialog and `resultRecapLinesOf`, `showDestructiveConfirmation`, `InnkeeperRepository._guard`, the panel/route plumbing. To split or extend: `InjuryChips` (removal, C-2), `ParticipantOverrideSection` (served bounds instead of a local draft).

**(2) The Map round trip destroys every root route.** `TeleportModeLanding._landOnMap` pops every root route (`teleport_mode_landing.dart:54-61`) and on success/cancel reopens **only the panel** (`:63-67`). PROBE (below) confirmed a wizard route stacked on the panel is disposed when teleport mode starts and is not restored. So «resume after the teleport» = reopen panel + wizard for the same card and rebuild from the served draft — which D-09 requires anyway. `TeleportModeCubit` needs a return target (`resumeCardKey`) and the panel an auto-open of the wizard after its first snapshot.

**(3) Inner POIs do not exist in the app today.** The teleport layers are the map image, `CityMarkersLayer` and `TeleportPawnLayer` (`world_map.dart:298-312`); the drop rule is `MapUtils.dropTargetCity` inside the shared `PawnDragging` mixin (`pawn_dragging.dart:37-47`, `map_utils.dart:77-78`); `cities` selects only `markerLocation { id location }` (`city_queries.dart:4-23`) and `GetCity` only `pointsOfInterest { id }` (`:26-38`). The BE already serves `pointOfInterests: [PointOfInterest!]!` with no role guard (`point-of-interest.resolver.ts:10-13`, SDL `PointOfInterest { city id location type }`) — so D-01 needs one new FE document, a POI marker layer and a POI-aware drop rule, **no contract change**, and can ship (and be tested on the device) before the BE merge. POIs have **no name** on the wire and the FE `PoiType` has **no Italian labels** and lacks `demonicPortal` (PROBE).

**(4) The players' lock has one exact precedent: the prison (quick 261110-cgd).** A served status field (`imprisonedUntil`) flows through `CharacterCubit` (`character_cubit.dart:109-120`, `characterUpdated` = `CharacterFragment.fullFields`), into `QuestViewer.imprisonedFor` → `QuestAvailability.imprisoned` → `questImprisonedLine` (`quest_viewer.dart:41-43`, `quest_availability.dart:105`, `quest_blocked_reason.dart:15, :39`), `disabledSatchelPages(isImprisoned)` (`satchel_availability.dart:21-33`), the pawn label (`character_marker_layer.dart:125-131`), the drag gate (`:111-112`), and one shared code file (`character_imprisoned.dart`) mapped in the travel, acceptance and transaction classifiers. `missionInProgress` follows the same path, plus the Journal (equipment, companion, spells, potions) where `awaitingAid` is the precedent (`items_section.dart:165-167`). Because the lock lives **on the character**, it is live through `characterUpdated` (unlike the Phase 20 `awaitingRescue` lock, which lives on the quest list) — provided the BE **emits** `characterUpdated` when the flag flips without a character write (draft start/discard, party start): the publisher already has `requestPublish(characterId)` (BE `character-updates.publisher.ts:43-45`).

**(5) Three latent gaps on the players' side and one in the contract.** `equipItem` has **no failure classifier**: `JournalCubit` calls `KlimmeckGraphQl` directly and turns any refusal into a `JournalError` that no widget renders (`journal_cubit.dart:29-36`; `grep BlocBuilder<JournalCubit` → nothing) — a `MISSION_IN_PROGRESS` on equip would be silent. D-12's «quest acceptance already blocked by the occupied lane» holds only for the **standard** lane: story and worldMission are separate lanes (`quest_lane.dart:5-11`), so during a hunt's waiting time a player can still accept a story today (C-3). D-06 «remove injuries» cannot be expressed with today's override wire, which carries only injuries **added** (`participant_override.dart:17`, `injury_chips.dart:28-31`, BE `ParticipantOverrideInput.injuries`) (C-2). The queue entry id that keys a worldMission draft must be any entry of the shared quest (BE `gm-completion.service.ts:180-211` already resolves all holders from any entry).

**Primary recommendation:** ten sequential plans — eight pre-gate (lock plumbing; players' UI lock ×2; inner-POI teleport + return to the wizard; mission models/documents/repository; wizard Cubits; wizard UI ×2, not wired) and two gated (schema gate + selection of `missionInProgress` + wiring «Completa» + retiring the Phase 10 form; device E2E). Design the wire layer so a BE rename costs one fragment constant and one parser per type.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `flutter_bloc` / `bloc_test ^10.0.0` / `mocktail ^1.0.5` | `MissionDraftCubit`, `MissionEnemiesCubit`, `MissionPrizeOptionsCubit`, `PointsOfInterestCubit` (or POIs inside `TeleportModeCubit`); `MockInnkeeperRepository` exists (`test/helpers/mocks.dart`) | [VERIFIED: codebase] |
| `equatable` | every new model/state with full `props` | [VERIFIED: codebase] |
| `graphql_flutter 5.2.1` (`FetchPolicy.noCache` via `KlimmeckGraphQl.performQuery`) | new innkeeper documents; draft reads must never come from the normalised cache | [VERIFIED: codebase, Phase 20 F2] |
| `flutter_map` + `latlong2` | POI `MarkerLayer` in teleport mode, `camera.latLngToScreenOffset` for the drop radius | [VERIFIED: codebase `pawn_dragging.dart:31-32` uses the inverse] |
| `cached_network_image` / `CachedSvg` via `EnemyPortrait` | enemy thumbnails in a lazily built list (`enemy_portrait.dart:46-62`) | [VERIFIED: codebase] |
| Material `Slider`, `FilterChip`, `Switch`, `TextField`, `IconButton` | utility surface controls (Phase 10 D-01/D-22) | [VERIFIED: codebase `participant_override_section.dart:39-47`] |
| Node + BE `node_modules/graphql` | `tool/schema_check/validate_documents.js` (manual gate) | [VERIFIED: codebase] |

## Architecture Patterns

### Recommended files
```
lib/models/mission/                          # NEW aggregate, Flutter-free, lenient per entry
  mission_draft.dart                         # MissionDraft { pendingQuestId, step, place?, fights, participants, prizes }
  mission_step.dart                          # enum MissionStep (asNameMap, unknown → null)
  mission_fight.dart                         # MissionFight { index, enemies [MissionEnemyPick], simulation? , corrections }
  mission_enemy_pick.dart                    # { enemy (slim Enemy), quantity }
  mission_participant_outcome.dart           # served per character: verdict, hpAfter, maxLifePoints, injuries (before/added/final), consumables & spells with bounds
  mission_correction.dart                    # the innkeeper's edit for one character in one fight (input + toJson)
  mission_prize_options.dart                 # served block + catalogue for one character
  mission_prize_entry.dart                   # one prize line (coins | xp | item×qty | pet | spell | cure)
lib/models/request/
  simulate_mission_fight_input.dart, save_mission_draft_input.dart   # inputs (names follow the BE)
lib/models/travel/teleport_destination.dart  # NEW: poiId + point + label + isCityMarker (replaces City in teleportTo)
lib/models/enums/poi_type.dart               # + demonicPortal, + Italian labels (GMFLOW-01)
lib/graphql/fragments/mission_draft_fragment.dart       # ONE fragment: rename cost = this file + the parsers
lib/graphql/fragments/mission_enemy_fragment.dart       # id name imagePath xp lifePoints legendary locations
lib/graphql/queries/mission_queries.dart                # GetMissionDraft, ListMissionEnemies, GetMissionPrizeOptions
lib/graphql/queries/point_of_interest_queries.dart      # ListPointsOfInterest (live today)
lib/graphql/mutations/mission_mutations.dart            # StartMissionDraft, SaveMissionDraft, DiscardMissionDraft, SimulateMissionFight, CompleteGuidedMission
lib/repository/innkeeper_repository.dart                # + mission methods through the existing _guard (innkeeper-only ops stay isolated here)
lib/repository/innkeeper_failure.dart                   # + missionInProgress, + draft-specific codes the BE defines
lib/repository/mission_in_progress.dart                 # NEW: const missionInProgressCode = 'MISSION_IN_PROGRESS' (pattern character_imprisoned.dart)
lib/repository/equipment_repository.dart + equipment_failure.dart   # NEW (fixes LB-1): equipItem through a repository + classifier
lib/screens/innkeeper/missionCompletion/
  mission_completion_route.dart              # openMissionCompletion(panelContext, card) — root Navigator, .value like request_completion_route.dart:45-66
  mission_completion_screen.dart             # Scaffold + AppBar «Completa la missione», step header, body per step, bottom bar
  missionDraftCubit/mission_draft_cubit.dart + _state.dart          # load/start/save/simulate/discard/complete over the served draft
  missionEnemiesCubit/mission_enemies_cubit.dart + _state.dart      # served list, showAll, local name query
  missionPrizeOptionsCubit/mission_prize_options_cubit.dart + _state.dart  # per character catalogue
  steps/place_step.dart, encounters_step.dart, fight_step.dart, prizes_step.dart, recap_step.dart
  components/enemy_picker.dart, fight_card.dart, simulated_outcome_view.dart, correction_section.dart, prize_list.dart, prize_catalogue_sheet.dart, mission_step_header.dart
lib/screens/innkeeper/components/injury_chips.dart       # + removable set (C-2)
lib/screens/mainScreen/tabs/map/layers/teleport_poi_layer.dart    # NEW: inner POI markers, teleport mode only
lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart         # drop rule becomes an overridable hook
lib/utils/mission_lines.dart                 # «Missione in corso» lines (pattern prison_lines.dart)
```
Names are proposals following `docs/rules/naming.md` (lowerCamelCase state folders, `Screen` suffix); the GraphQL operation names mirror the BE draft names and change with them.

### F-1. Today's Locanda flow end to end [VERIFIED: codebase]

| Stage | File:line | Note for the wizard |
|-------|-----------|---------------------|
| Entry | `innkeeper_panel_route.dart:17-46` `openInnkeeperPanel` reads `InnkeeperRepository`, `ServerClockService`, `TeleportModeCubit` from the shell and hands them with `.value`; creates `PendingRequestsCubit..start()` and `QuestGenerationCubit` | add an optional `resumeCardKey` (F-3) |
| Queue | `pending_requests_cubit.dart:68-120` subscription `pendingRequestsUpdated` + refetch; `pending_requests_state.dart:30-35` `cards` = actionable only | the wizard listens to `state.requests` (raw), never `cards` (a card can hide for a transient reason) |
| Grouping | `request_card.dart:67-70` `cardKeyOf` = quest id for worldMission, request id otherwise; `:95-104` `pendingQuestId` = **first entry** id | the draft must resolve from any entry id of a shared worldMission (Need N-3) |
| Card | `request_card_view.dart:79-93` «Teletrasporta» + «Completa» (enabled by `canComplete`) | «Completa» opens the wizard; optional «Riprendi» label from a served flag (N-4) |
| Form | `request_completion_route.dart:45-66`, `request_completion_screen.dart:18-216`, `request_completion_cubit.dart:18-130` | retired in the gated plan |
| Exits | `CompletionExit` sealed (`request_completion_route.dart:12-42`), `_complete` (`innkeeper_panel_screen.dart:160-181`): Completed → `markCompleted` + recap; Gone → hide + refetch + SnackBar; Busy → refetch + SnackBar; Forbidden → close panel | reuse the same sealed exits for the wizard (rename the file or move them to `missionCompletion/`) |
| Recap | `results_recap_dialog.dart:8-40`, `completion_recap.dart:46-67` (`resultRecapLinesOf`, `recapNameOf`) | reused unchanged for `completeGuidedMission`'s `[QuestResult!]!` |
| Failures | `innkeeper_failure.dart:13-62` (`notFound, questInProgress, overrideInvalid, notParticipant, forbidden, badUserInput, …`), `_guard` (`innkeeper_repository.dart:62-80`) | add the BE's draft codes + `missionInProgress`; keep `_guard` |

GROUP request: one `RequestCard` per worldMission quest with every registered participant (`PendingRequestCharacter { id name location activeTravel awaitingAid pendingQuest }`, `pending_request.dart:41-92`; fragment `pending_request_fragment.dart:6-23`); the BE also serves `PendingRequestCharacter.title` (SDL), **not selected** by the FE today. Presence: `participant_presence.dart:51-63`; only actionable cards are listed (Phase 10 «Amended (UAT 2026-11-01)»).

Reusable as they are: `QuantityStepper` (`quantity_stepper.dart:6-40`, `0..max` with «−»/«+»), `showDestructiveConfirmation` with the neutral style (`request_completion_screen.dart:194-200`), `showResultsRecap`, `KGLoader`, the `CompletionExit` family, `closeInnkeeperPanel`. To split: `ParticipantOverrideSection` (bound to `ParticipantDraft`, `participant_override_section.dart:11-87`) becomes a `CorrectionSection` bound to a served outcome + a local correction; `InjuryChips` gains a removable set (C-2). Not reusable: `ParticipantDraft.from(Character)` (local bounds from `ownedItems`/`Spellbook`, `participant_draft.dart:66-107`) — in a multi-fight draft the bounds of fight k depend on fight k-1's corrections, which only the BE knows (N-7).

### F-2. Step 1 — inner POIs on the Map [VERIFIED: codebase + BE read]

- **Drop targets today:** `PawnDragging.handlePawnDragEnd` → `MapUtils.dropTargetCity(releasePoint, dropCities)` = polygon containing the point, else nearest marker (`pawn_dragging.dart:37-47`, `map_utils.dart:63-78`); `TeleportPawnLayer` reuses the mixin (`teleport_pawn_layer.dart:43-56`) and reports `(LatLng?, City?)`; `WorldMap._handleTeleportDragEnd` → `TeleportModeCubit.teleportTo(City)` (`world_map.dart:520-524`); the cubit skips the current city through `travelDestinationFor` and sends `markerLocation.id` (`teleport_mode_cubit.dart:66-94`).
- **Rendering:** teleport layers = map image + `CityMarkersLayer` (no tap) + `TeleportPawnLayer` (`world_map.dart:298-312`); zoom thresholds `capital 0 / city 2.5 / village 3.2 / quest 4` (`map_constants.dart:5-8`); quest markers hide at zoom ≤ 4 and skip POIs equal to a city marker (`quest_markers_layer.dart:40-63`). There is **no** layer for non-quest POIs.
- **Data:** `cities` = `markerLocation { id location }` only (`city_queries.dart:4-23`); `PointOfInterest` model has `id, type, location, city` and no name (`point_of_interest.dart:8-64`; SDL `type PointOfInterest { city id location type }`). BE `pointOfInterests` returns every POI, no `@Roles` (`point-of-interest.resolver.ts:10-13`, `findAll()` `point-of-interest.service.ts:18-20`). Count at DB unknown (not read: the DB is out of bounds for this research).
- **`TeleportTarget`** (`teleport_target.dart:11-50`) accepts any `PointOfInterest` as the start location (`status.location`): a group already on an inner POI renders correctly; nothing to change there except the label rule.
- **«Skip when already there»:** the served place is each participant's `PendingRequestCharacter.location` (POI id, `pending_request.dart:55-56, :74`). Group together ⇔ every participant has the same `locationId` and no travel (cards with travellers are not listed anyway). The FE may compare ids for display (it is not a game rule); the BE must judge the place for step 2 (N-5).
- **Recommended implementation:**
  1. `ListPointsOfInterest { pointOfInterests { id type location city { id name } } }` in `InnkeeperRepository.listPointsOfInterest()` (read when the mission teleport is prepared; `noCache`; world data, small payload).
  2. `TeleportPoiLayer` in `_teleportLayers` between the city markers and the pawn: one small theme-token dot per inner POI (POI not equal to any `City.markerLocation.id`), visible at zoom ≥ `cityVisibleZoom` (provisional), no tap. No new asset (REPO-RULES).
  3. Drop rule: `PawnDragging` gets an overridable `dropTargetFor(LatLng point)` defaulting to today's city rule (player travel untouched); `TeleportPawnLayer` overrides it: nearest inner POI whose **screen** distance from the release point is ≤ a radius (e.g. 32 px, `camera.latLngToScreenOffset`), else the city rule. Reported as a `TeleportDestination { poiId, point, label, isCityMarker }`.
  4. `TeleportModeCubit.teleportTo(TeleportDestination)`; same-place → no call (mirror of Phase 10 C16 on `poiId`).
  5. Chip copy «Trascina {nome} su una città o un luogo» (pinned today as «Trascina Bea su una città», `teleport_mode_chip_test.dart:76-83`).
- `map_utils.dart` is **not formatter-clean** today: a `style(map): format map_utils.dart` commit first if the plan touches it (prefer adding the POI rule in a new pure file `lib/screens/mainScreen/tabs/map/utils/teleport_drop.dart`).

### F-3. Resuming the wizard after the Map round trip [VERIFIED: codebase + PROBE]

- `TeleportModeLanding` listens for `TeleportActive` → `_landOnMap` = `Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst)` + `jumpToPage(worldMapPageIndex)` (`teleport_mode_landing.dart:29-33, :54-61`); on `TeleportSucceeded`/`TeleportCancelled` → `acknowledgeExit()` + `openInnkeeperPanel(context)` (`:34-44, :63-67`).
- **PROBE** `test/_probes/landing_wizard_probe_test.dart` (harness copied from `teleport_mode_landing_test.dart:85-138`): panel stand-in + a stateful «wizard» route pushed on the root Navigator → emit `TeleportActive` → wizard text gone, `dispose` called; emit `TeleportSucceeded` → `InnkeeperPanelScreen` found, wizard not found. Command `flutter test test/_probes/landing_wizard_probe_test.dart` → `+1: All tests passed!`. Deleted.
- **Consequence:** no in-memory wizard state survives the teleport; the draft must be served (D-09) and the return must re-open the wizard. Recommended: `TeleportModeCubit.prepare(..., resumeCardKey: String?)` stored in the target/state; `TeleportSucceeded`/`TeleportCancelled` carry it; the landing calls `openInnkeeperPanel(context, resumeCardKey: key)`; `InnkeeperPanelScreen(resumeCardKey)` opens `openMissionCompletion` once, after the first loaded snapshot that contains the card (a `BlocListener` with a one-shot flag; no card → SnackBar «Richiesta non più disponibile»). The wizard reloads the draft (`GetMissionDraft`), then `pendingRequests` refetch shows the new locations.
- After the teleport the queue does **not** re-emit (insert/delete only, Phase 10 D-18): the panel's new subscription snapshot carries the new `location`s; the wizard must read the place from the draft/participants after reopening, never from the pre-teleport card object.

### F-4. Wizard architecture [VERIFIED: codebase patterns; recommendation]

- **One route, one host screen, one Cubit owning the served draft + list Cubits per responsibility.** `MissionDraftCubit` (draft lifecycle: `load`, `start`, `saveFights`, `simulate(fightIndex)`, `saveCorrections`, `savePrizes`, `discard`, `complete`; every mutation returns `MissionDraft` and replaces the state — no local merge, no optimistic edit of served fields); `MissionEnemiesCubit` (served enemy list for the draft, `showAll` toggle → refetch, local name query); `MissionPrizeOptionsCubit` (catalogue per character). Unsaved edits of the current page (picks before «Salva», slider position) live in the page widget state or a small `Equatable` edit object held by the page, and are sent on «Avanti»/«Simula»/«Salva». This satisfies «the BE owns the draft; no local persistence».
- **Step host:** a header «Passo k di N · <titolo>» (`MissionStepHeader`) + one body widget per served `MissionStep` + a bottom bar «Indietro» / primary action. Material `Stepper` is cramped on the landscape phone (`test/helpers/landscape.dart` is the standard harness) — use pages. Back = previous page without a call (the served draft already holds earlier steps); system back during a call is blocked (`PopScope(canPop: !isSubmitting)`, pattern `request_completion_screen.dart:32-39`); system back otherwise leaves the wizard (draft stays on the BE, participants stay locked until completion or discard — say it in the leave copy).
- **Resume:** on open `load()` = `GetMissionDraft(pendingQuestId)`; `null` → «Inizia la missione» page (explicit start = the moment the lock begins, D-11; avoids locking players on an accidental «Completa»); non-null → the page of `draft.step`.
- **Queue changes while open:** `BlocListener<PendingRequestsCubit>` on `state.requests`: when no request with the card's `pendingQuestId` (or, for a worldMission, any entry of `card.questId`) remains → pop with `CompletionGone`. `NOT_FOUND` from any draft operation → same exit. `FORBIDDEN` → `CompletionForbidden` (panel closes, Phase 10 D-04). The panel route provides `PendingRequestsCubit` by `.value` exactly as today (`request_completion_route.dart:55`).
- **Two devices:** last write wins unless the BE versions the draft (N-9). The FE reloads the draft on resume and on `app resume` (pattern: `PendingRequestsCubit` lifecycle refetch).

### F-5. Step 2 — fights and enemies [VERIFIED: codebase + PROBE]

- **Model:** `Enemy` (`enemy.dart:9-103`) parses `id name locations weaknesses relatedLore xp spells lifePoints imagePath damages`; no `legendary`. **PROBE** `test/_probes/enemy_slim_probe_test.dart`: `Enemy.fromJson` of the slim selection `{id name imagePath xp lifePoints legendary locations:['vulcano','demonicPortal']}` → parses, `damages == null`, `locations == [vulcano]` (`demonicPortal` dropped); `PoiType.values.asNameMap()['demonicPortal'] == null`. Command `flutter test test/_probes/enemy_slim_probe_test.dart` → `+2: All tests passed!`. Deleted. Recommendation: a `MissionEnemy` model (or `Enemy` + `isLegendary`) parsed from `MissionEnemyFragment` `{ id name imagePath xp lifePoints legendary }` — `locations` not needed (the FE never filters).
- **Existing slim pattern:** `QuestEnemy.fromJson` passes only `id name imagePath xp` to `Enemy.fromJson` (`quest_enemy.dart:19-40`; fragment `quest_fragment.dart:23-31`).
- **List UI (utility):** `ListView.builder` (ui-ux rule) rows: `EnemyPortrait(height: 48)` (`enemy_portrait.dart:15-62`: SVG through `CachedSvg`, raster through `CachedNetworkImage`, no placeholder from the bundle; built lazily → only visible rows download), name, «PE N», «PV N», a «Leggendario» tag, a «+» to add to the current fight. A `TextField` «Cerca» filters the served list by name (display filtering on the client is allowed — like the Phase 18 injury intersection; never by rank/type). A `Switch` «Mostra tutti» refetches with `showAll: true`. The current fight shows its picks with `QuantityStepper` (max: provisional 20, or a BE cap N-6) and a remove action.
- **Several fights:** `FightCard` per served fight in order («Scontro 1», «Scontro 2», «Aggiungi scontro», «Rimuovi scontro»), each with its picks; one `SaveMissionDraft` with the whole fights list on «Avanti» (simplest wire, one validation point).
- **Cost:** bestiary size not read (DB out of bounds); `CachedSvg` caches memory+disk; with `ListView.builder` the cost is the visible rows. No grouping needed; sort order = served order (BE: by xp?) (N-6).

### F-6. Steps 3–4 — simulation and corrections [VERIFIED: codebase]

- **Today's controls:** `ParticipantOverrideSection` (`participant_override_section.dart:36-84`): name, «Punti vita» slider `1..maxLifePoints` with `divisions: max-1` and «N / max», hidden when max = 1; «Ferite» `InjuryChips` (existing selected+disabled, added toggleable, `injury_chips.dart:24-32`; 37 `InjuryType`); «Consumabili» steppers `0..owned`; «Magie» steppers `0..remaining`. Pinned by `test/screens/innkeeper/components/completion_form_test.dart:82-319`.
- **Missing for D-04..D-06:** (a) the simulated verdict per character («Vittoria»/«Sconfitta») and the engine's numbers shown read-only above the corrections; (b) the slider's **initial value = simulated `hpAfter`**, bounds `1..maxLifePoints` served; (c) injuries in three groups — before the mission (locked), added by the engine (removable), added by hand (removable) — `InjuryChips` needs a `removable` set (C-2); (d) consumable and spell bounds **served per fight** (fight k after fight k-1's corrections) (N-7); (e) «Rilancia» (re-run = same call again; D-05) and «Cambia nemici» (back to step 2 for that fight).
- **Rendering:** utility surface → plain Material rows; do **not** reuse the gameplay result parchment (`quest_result_sheet.dart`), which needs `QuestResult` and gameplay chrome rules. A compact `SimulatedOutcomeView`: «Esito: Sconfitta · PV 812 → 120 · Ferite: …· Usati: 2 Radice Curativa, 1 Palla di fuoco».
- **Invalidation (Claude's discretion → recommended):** changing the enemies of fight k invalidates the simulation and corrections of k and of every following fight; **the BE applies it** in `SaveMissionDraft` and serves `simulation: null` for those fights; the FE shows «Da simulare» and disables «Avanti» until each fight has a simulation (served). The FE never decides what is stale.
- **Order:** «Simula» for fight k enabled only when fight k-1 has a simulation (served); the BE refuses otherwise (N-8).

### F-7. Step 5 — prizes [VERIFIED: codebase + SDL]

- **The quest sheet's prize row is not reusable:** it is the private `_prizeRow` of `quest_info_sheet.dart:427-471` (bound to `quest!.prizes`, sized by a `LayoutBuilder` for the parchment, coins share constants); `quest_sheet_details.dart` holds only `petPrizeLine` (`:120, :178-179`) (C-1). `xpPrize` and `randomLoot` are parsed but never shown; `prizes.spell` is **not selected** (Phase 20 F6).
- **Reuse the building blocks instead:** `CoinsDisplay` (`coins_display.dart`), `ItemRow` (`item_row.dart:11-60`: equipment/loot card + name + optional quantity, `onSelect`, `isDisabled`, `statusLine`), `LootItemCard`/`EquipmentItemCard`, `CompanionRow` (`companion_row.dart`) for pets, `SpellRow`/`SpellCard` for spells; all render on a parchment background (`KlimmeckGuideTheme.getParchmentBackground()`), no gameplay chrome dependency.
- **Models:** `QuestRankPrizes { title: String!, prizes: QuestPrizes! }` exists on the SDL but the FE neither selects nor parses it (20-REPO-RULES); `QuestPrizes` parsing exists (`quest_prizes.dart:30-43`, strict per `randomLoot` entry). For the draft, a flat `MissionPrizeEntry` list per character (kind + payload) is easier to edit and to send than a `QuestPrizes` object; the served catalogue lists items (`AssetQuantity` with `ItemUnion` → existing `LootFragment`/`EquipmentFragment`), pets (`PetFragment`), spells (`SpellFragment`).
- **Long catalogue:** a bottom sheet (utility) with a `ListView.builder`, a «Cerca» field and tabs «Oggetti / Compagni / Magie»; spells tab empty below mage (served).
- **Coins/xp:** PRODUCT question PQ5 (amount editable or entry only removable).

### F-8. Step 6 — completion [VERIFIED: codebase]

- Recap text built purely from the served draft (`missionRecapOf(card, draft)` in `missionCompletion/components/`, pattern `confirmationRecapOf` `completion_recap.dart:15-42`): quest title, participants, fights («Scontro 1: 3 Lupo, 1 Orco»), per character final life, injuries, consumables/spells used, prizes.
- Confirmation: `showDestructiveConfirmation(title: 'Completa la missione', confirmButtonStyle: primaryButtonStyle)` (Phase 10 D-11 neutral style).
- `CompleteGuidedMission` returns `[QuestResult!]!` → `QuestResultFragment.fields` (as `pending_request_mutations.dart:6-13`) → exit `CompletionCompleted(results)` → existing `showResultsRecap`.
- Classifier additions: draft codes defined by the BE (e.g. draft missing → `NOT_FOUND`; fight not simulated; prize not allowed → revalidation refusal); `OUTCOME_OVERRIDE_INVALID` kept for corrections; `MISSION_IN_PROGRESS` only if the BE uses it on innkeeper operations (e.g. `startMissionDraft` when a participant is in a normal mission).

### F-9. Players' side — where the status lives and how a new boolean flows [VERIFIED: codebase + BE read]

- **Source:** `CharacterCubit.subscribeToCharacter` (`character_cubit.dart:109-120`) → `characterUpdated(id)` with `CharacterFragment.fullFields` (`character_subscriptions.dart:4-10`; `fullFields` = infos + status + assets + quests, `character_fragment.dart:140-147`); `status` selection `:24-60`; model `CharacterStatus.fromJson` (`character_status.dart:62-81`).
- **New field path:** `CharacterStatus.missionInProgress` parsed `json['missionInProgress'] == true` (lenient, pattern `Quest.awaitingRescue` `quest.dart:47`), `toJson`, `copyWith`, `props` — **pre-gate**. The **selection** in `statusFields` is **gated**: `statusFields` is used by `character` and `characterUpdated` (`character_queries.dart:18`, `character_subscriptions.dart:7`) — an unknown field fails both documents against today's BE (the whole app would lose its character).
- **Liveness:** `characterUpdated` is published from the characters change stream (`character-updates.publisher.ts:47-50`) or on demand (`requestPublish`, `:43-45`). A resolved, non-persisted `missionInProgress` flips without a character write at draft start/discard and possibly at party start → the BE must call `requestPublish` for each affected participant (N-11). Then the Board, the Map and the Journal update live (all read `CharacterCubit`), unlike the Phase 20 `awaitingRescue` limitation (quest-list field, 20-HUMAN-UAT:103).

### F-10. Players' side — every locked entry point today [VERIFIED: codebase]

| Action | Entry point (file:line) | Similar gate today | Recommended for `missionInProgress` | Refusal classifier → notice |
|--------|-------------------------|--------------------|-------------------------------------|-----------------------------|
| Travel start | pawn drag `character_marker_layer.dart:108-112` `canDrag: prisonRemaining == null && _canStartTravel(...)`; `_canStartTravel` `:176-182` (no travel, no standard lane, no aid, `TravelIdle`) | prison, aid, lane | add `!missionInProgress` | `TravelFailure` `travel_failure.dart:76-87` → `travel_notice.dart:15-36` |
| Quest acceptance / registration | Board tear `board.dart:325-334` (`canTear: standingOf(...).canAccept`, `isEnabled`); availability `quest_availability.dart:98-113` (prison `:105`); line `quest_blocked_reason.dart:19-41` | prison (`QuestViewer.imprisonedFor`, `quest_viewer.dart:41-43`; Board builds the viewer live `board.dart:137-157`) | `QuestViewer.isOnMission` → `QuestAvailability.missionInProgress` (after `tornForOwner`, next to `imprisoned`) → blocked line | `QuestAcceptanceFailure` `quest_acceptance_failure.dart:81-96` → `quest_acceptance_notice.dart` |
| Shop buy/sell | satchel page `satchel_availability.dart:21-33` (board+shop closed for travel/aid/prison; shop-only for `hasShop`), defence `main_screen.dart:276-288`, inputs `:291-302`; `TransactionCubit` | aid, prison | `isOnMission` → close **Shop only** (`_shopOnly`), Board stays readable with the blocked line | `TransactionFailure` `transaction_failure.dart:61-76` → `transaction_notice.dart` |
| Equipment change | Journal `journal.dart:204` (row tap), `:243` (info sheet «Equipaggia»), `_equipItem` `:328-357` → `JournalCubit.equipItem` (`journal_cubit.dart:29-36`) | **none** | disable both taps (`ItemRow.isDisabled` + no `onSelect`, `EquipmentInfoSheet` without `onEquip`) | **no classifier today** (LB-1): new `EquipmentRepository` + `EquipmentFailure` + notice |
| Companion | `companion_section.dart:56-75` `_toggle` → `CompanionCubit.toggle` | none («interattiva anche in viaggio», `:30-31`) | no `onToggle` while locked | `PetEquipFailure` `pet_equip_failure.dart:46-50` → `companion_notice.dart` |
| Spell equip | `spells_section.dart:24-38` `toggleSpellWithFeedback` → `SpellsCubit.toggle` | none | no toggle while locked | `SpellEquipFailure` `spell_equip_failure.dart:56-63` → `spell_notice.dart` |
| Potions | `items_section.dart:160-181` `_row`: no `onSelect` when not a potion or awaiting aid (`:165-167`), disabled + countdown while recovering | aid, recovery | treat like aid + `statusLine` «Missione in corso» | `ItemUseFailure` `item_use_failure.dart:58-64` → `potion_notice.dart` |
| `useSpell` outside combat | not in the FE (`grep useSpell lib` → nothing) | — | nothing | — |

**In-world notice (c):** the pawn label is the in-world status pattern («In attesa di soccorso» `character_marker_layer.dart:35-38, :117-124`; prison `:125-131`, both `PawnLabel`). Recommended: one `PawnLabel` «Missione in corso» when `missionInProgress` (product question PQ1 on whether to show it also during normal missions, where the quest paper already says «Cacciando…» `quest_state_label.dart:7-20`); in the Journal the disabled rows carry `statusLine: 'Missione in corso'` (pattern of the potion countdown `items_section.dart:171-177`); on the Board the blocked line. One shared constant in `lib/utils/mission_lines.dart`.

**Refusal banner (d):** six classifiers learn `missionInProgressCode` (travel, quest acceptance, transaction, spell equip, pet equip, item use) + the new equipment classifier; innkeeper only if the BE uses the code there. Shared constant file `lib/repository/mission_in_progress.dart` (pattern `character_imprisoned.dart:4-6`). The 11 classifiers keep the `BAD_USER_INPUT` copy (STATE).

**D-12 visible change (e):** during a normal mission's effective start (standard lane after arrival = «Cacciando…/In combattimento…»; registered quest after party start) the player today can still open the Journal and swap equipment/companion/spells, drink potions, and buy in the shop if the quest marker is a city marker (heal/job/study can sit on a city marker: `quest_markers_layer.dart:44-47` filters such markers out of the quest layer). After the phase: those rows are disabled with «Missione in corso» for the whole waiting time (hours for dungeons/hunts). Travel is already blocked by the lane (`_canStartTravel`). Acceptance in the **other lanes** (story, worldMission) stays possible today → C-3. Risk: the notice appears on every normal mission; recommend the Journal line only (where actions are disabled), not a new pawn label for normal missions (PQ1).

### F-11. GraphQL layer, registry, fakes [VERIFIED: codebase]

- Registry `tool/schema_check/schema_check_documents.dart:43-89` (46 entries; the brief cites `dump_documents.dart`, which is the runner). Count pins: `test/tool/schema_check_documents_test.dart:32-33`, `test/graphql/travel_documents_test.dart:178-179`, `test/graphql/shop_documents_test.dart:132`, `test/graphql/loot_fragment_test.dart:124-125` — **four pins** move with every added/removed document.
- New documents (draft names, BE to confirm): `ListPointsOfInterest` (live today), `GetMissionDraft`, `ListMissionEnemies`, `GetMissionPrizeOptions`, `StartMissionDraft`, `SaveMissionDraft`, `DiscardMissionDraft`, `SimulateMissionFight`, `CompleteGuidedMission` → **55**; minus `CompletePendingRequest` when the form is retired → **54** (if the BE folds start/save into one mutation or serves options inside the draft, the count shrinks: the gate plan fixes the number).
- Fetch policies: every innkeeper read `noCache` through `performQuery` (as `getPendingRequests`); mutations network-only.
- Isolation: innkeeper operations only through `InnkeeperRepository` (`innkeeper_repository.dart:17-81`, `_guard` maps `OperationException`, access-denied, timeout, `FormatException`); the role is enforced by the BE (`@Roles(innkeeper)`).
- Fakes/mocks: `MockInnkeeperRepository`, `MockTeleportModeCubit` (`test/helpers/mocks.dart`), fixtures `test/helpers/fixtures/pending_request_fixtures.dart` (`pendingRequestJson`, `participantCharacterJson`), harness `test_app.dart`, `landscape.dart`, `map_harness.dart`, `svg_cache_seed.dart`.

### Anti-Patterns to Avoid
- Building participant bounds from the local `Character` for fights ≥ 2 (`ParticipantDraft.from` logic): bounds are served per fight.
- Filtering the enemy list by xp, POI type or `legendary` on the FE (rule 4); client name search only.
- Keeping the wizard state in a shell-level Cubit «so it survives the teleport»: the landing pops the route anyway and D-09 wants the BE draft.
- Selecting `missionInProgress` in `CharacterFragment.statusFields` before the BE merge (breaks `character` and `characterUpdated`).
- Reading the place from the card object captured before the teleport (stale after the round trip).
- Popping the wizard when the card leaves `PendingRequestsState.cards` (actionable filter) instead of when the request leaves `requests`.
- A `byName` on a served enum (`MissionStep`, verdict) inside `fromJson`: one unknown value would drop the whole draft — use `asNameMap()`.
- Reusing the gameplay quest/result parchments inside the Locanda.
- `appLog` of draft, simulation, prize or result payloads (REPO-RULES; `tool/hardening_check.sh`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Combat outcome, HP, injuries, consumption | any FE estimate | `simulateMissionFight` served outcome | rule 4, D-04 |
| Invalidation of later fights | FE staleness tracking | served `simulation: null` | one rule on the BE |
| Enemy/prize filtering by rank, habitat, POI | client filters | `missionEnemies`, `missionPrizeOptions` | D-03, D-07, BE revalidates |
| Correction bounds per fight | `ParticipantDraft.from` | served bounds in the draft | depend on previous fights |
| Drop resolution | ad-hoc hit tests in `WorldMap` | `PawnDragging` hook + pure `teleport_drop.dart` | one tested rule |
| Error mapping | inline code strings | `innkeeperFailureFrom` + shared code files | pattern of 11 classifiers |
| Confirmation | custom dialog | `showDestructiveConfirmation` neutral | Phase 10 D-11 |
| Results recap | new sheet | `showResultsRecap` + `resultRecapLinesOf` | Phase 10 D-13 |
| Schema validation | new script | `dump_documents.dart` + `validate_documents.js` | registry |

## Runtime State Inventory

Not a rename phase, but the retirement of the Phase 10 form and a new BE-side draft are state changes:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | BE: new draft documents (or fields on `PendingQuest`) created by this phase; 0 story / 0 worldMission at DB on 2026-11-12 (21-CONTEXT §specifics) | none on the FE; UAT needs a hand-written worldMission + story (orchestrator script, BE D-36) |
| Live service config | none — verified: the FE has no server-side config for the Locanda | none |
| OS-registered state | none — no new push category (players get the usual `questEnd`) | none |
| Secrets/env vars | none — no new key (REPO-RULES) | none |
| Build artifacts | none — no codegen; registry count pins in four test files | update pins in the plans that add/remove documents |

## Conflicts (CONTEXT / REPO-RULES vs code — each with a proposed fix, no decision changed here)

- **C-1 (CONTEXT Reusable Assets, «prize rows of the quest sheet `quest_sheet_details.dart`»):** the rows are the private `_prizeRow` of `quest_info_sheet.dart:427-471`, bound to `quest.prizes` and to the parchment layout; `quest_sheet_details.dart` only builds the pet line. **Fix:** reuse the building blocks (`CoinsDisplay`, `ItemRow`, item cards, `CompanionRow`, `SpellRow`) in a utility `PrizeList`; do not extract from the gameplay sheet.
- **C-2 (D-06 «remove the injuries in excess» vs REPO-RULES «BE validation as today's overrides»):** today's override carries only injuries **added** (`participant_override.dart:17`, `injury_chips.dart:5, :28-31`, BE `ParticipantOverrideInput.injuries`). **Fix:** the draft correction carries the **final** injury list (or `injuriesRemoved` + `injuriesAdded`) per character per fight, validated by the BE (removable = added by the engine or by hand in this mission; PQ3 for pre-existing injuries); `InjuryChips` gains a removable set.
- **C-3 (D-12 «travel and quest acceptance are already blocked by the occupied lane»):** true for travel (`character_marker_layer.dart:178-180`) and for the standard lane only; story and worldMission are separate lanes (`quest_lane.dart:5-11`), so during a normal mission a player can still accept a story or register to a worldMission. **Fix:** BE: `MISSION_IN_PROGRESS` also on `acceptQuest` for every lane while `missionInProgress` (one predicate); FE: `QuestAvailability.missionInProgress` for every quest type. **PRODUCT confirmation needed (PQ2).**
- **C-4 (21-REPO-RULES «Step 1 changes no contract») — holds, but the FE work is larger than «widen the drop targets»:** the app has no inner-POI data or layer (F-2); POIs have no name; `PoiType` lacks labels and `demonicPortal`. **Fix:** one new live document (`ListPointsOfInterest`), a teleport POI layer, a drop hook; labels in `poi_type.dart` (PQ6).
- **C-5 (CONTEXT Integration Points, «`request_completion_route.dart` / `request_completion_screen.dart` become the wizard»):** an in-place rewrite would break the app against today's BE in the pre-gate plans (REPO-RULES: pre-gate plans keep the app working). **Fix:** new `missionCompletion/` files, wired and old files deleted in the gated plan.
- **C-6 (D-11 lock «from the moment the innkeeper starts the flow») vs an accidental «Completa»:** if the draft is created on open, a mis-tap locks the players until a discard. **Fix (discretion, flagged):** explicit «Inizia la missione» page; draft created there.
- **C-7 (21-REPO-RULES «one Italian banner in every classifier of the locked actions»):** `equipItem` has no classifier and its errors are invisible (LB-1). **Fix:** a small repository + classifier + notice in the players' lock plan (Boy Scout, in scope because D-11 needs the refusal to be visible).

## Needs from the BE (hand to the BE research / 22-REPO-RULES)

- **N-1 `CharacterStatus.missionInProgress: Boolean!`** resolved on every `Character` path the player reads (`character`, `characterUpdated` WS payload per subscriber), true from draft start (D-11) or the effective start of a normal mission (D-12) to the result; also correct when the innkeeper reads `character(id)`.
- **N-2 `MISSION_IN_PROGRESS`** on: `startTravel` **and** `travelPreview` (the FE shows the preview sheet before starting), `acceptQuest` (every lane, C-3), `doTransaction`, `equipItem`, `equipPet`/`unequipPet`, `equipSpell`/`unequipSpell`, `useItem`, `useSpell`; extensions `{ code }` only (no extra keys needed). Precedence vs `QUEST_IN_PROGRESS`/`QUEST_SLOT_BUSY`/`AWAITING_AID`/`CHARACTER_IMPRISONED`: state it (the FE maps each independently).
- **N-3 Draft key:** every draft operation accepts the card's `pendingQuestId` = first entry id; for a worldMission any entry id of the shared quest resolves the same draft (as `GmCompletionService.readRequest`, `gm-completion.service.ts:180-211`).
- **N-4 (optional) Queue flag:** `PendingRequest.missionDraftStep: MissionStep` (or `hasMissionDraft: Boolean!`) on `pendingRequests`/`pendingRequestsUpdated`, and a queue emission when a draft is created/discarded, so the card reads «Riprendi». Without it the card keeps «Completa» and the wizard resumes on open (acceptable).
- **N-5 Place:** the place used by `missionEnemies` = the participants' common `status.location` read at query time (or stored in the draft by `saveMissionDraft`); a split group → a defined refusal code. Served in the draft as `place { id type city { id name } }` for the step header.
- **N-6 `missionEnemies`:** return `[Enemy!]!` with `legendary` and `lifePoints` resolvable without heavy sub-objects; a stable order (e.g. xp ascending); a max quantity per pick if any (else the FE caps the stepper at a provisional 20).
- **N-7 Served bounds per fight and character:** life `max`, starting values (HP before the fight, injuries before), consumables with the owned quantity at the start of that fight, active spells with the remaining usages at the start of that fight; the engine's used quantities; the final corrected state after the corrections.
- **N-8 Fight order and invalidation:** `simulateMissionFight` refuses fight k while k-1 has no simulation (code); `saveMissionDraft` that changes the enemies of fight k nulls simulation + corrections of k and following; re-simulating k nulls the following fights' simulations.
- **N-9 (optional) Concurrency:** a `version`/`updatedAt` on `MissionDraft`, echoed on saves, refused with a code when stale (two devices).
- **N-10 Prizes:** `missionPrizeOptions` serves the prefilled entries as **concrete** lines (the block's `randomLoot` resolved to items + quantities, coins, xp, pet, spell, cure if present) and the catalogue (items with rarity, pets, spells only ≥ mage with `minXpToLearn`); the draft stores the chosen entries per character; `completeGuidedMission` revalidates with the same function.
- **N-11 Live emission:** `CharacterUpdatesPublisher.requestPublish` for every participant when `missionInProgress` flips without a character write (draft start, discard, party start; completion writes anyway).
- **N-12 Teleport within the flow:** `teleportCharacter` of a draft's participant stays allowed (not refused by `MISSION_IN_PROGRESS`); a character standing on an inner POI after the mission can start a travel (planner from any POI) — confirm; the shop and the Board are closed there by the FE (`currentCityOf` = city marker only, `board_policy.dart:11-18`), which is today's rule.
- **N-13 Completion:** `completeGuidedMission(pendingQuestId)` returns `[QuestResult!]!` with `enemies` of every fight; deletes the draft; releases the lock; the queue emits the delete as today.
- **N-14 Zero fights:** say whether a draft with **no fight** can be completed (narrative story) — PQ4.
- **N-15 Coexistence:** `completePendingRequest` stays until the FE PR is merged; the FE stops using it in the gated plan.

## Open Questions (RESOLVED — rulings in `21-CONTEXT.md` D-13..D-30, 2026-11-14)

> All closed as recommended, except **PQ5**: the user chose free coins and xp with no ceiling (D-15). PQ1 → D-16 (two served booleans), PQ2 → D-13, PQ3 → D-14, PQ4 → D-24, PQ6/PQ7 → D-29, wizard copy → D-30. The BE side (item 9) is closed by the BE `22-CONTEXT.md` D-17..D-25.

1. **PQ1 — PRODUCT: where the players see «Missione in corso».** «Durante la missione guidata e durante ogni missione normale iniziata, dove compare l'avviso? (a) sopra la pedina nella Mappa (come «In attesa di soccorso») solo per la missione guidata, e come riga sulle azioni bloccate del Diario e del foglio della quest in entrambi i casi; (b) sopra la pedina in entrambi i casi; (c) solo sulle azioni bloccate.» **Recommended: (a)** — in the normal missions the quest paper already says «Cacciando…», the pawn label would repeat it. Copy: pawn «Missione in corso»; Journal row status «Missione in corso»; Board line «Missione in corso: aspetta l'esito»; refusal banner description «Sei impegnato in una missione: aspetta l'esito» (titles per action stay as today, e.g. «Viaggio non partito»).
2. **PQ2 — PRODUCT (C-3): other lanes during a normal mission.** «Mentre un personaggio è in una missione normale già iniziata (es. caccia), può ancora accettare una story o iscriversi a una worldMission? (a) no, il blocco vale per ogni accettazione; (b) sì, come oggi (corsie separate).» **Recommended: (a)** — one predicate, matches the user's wording of D-12.
3. **PQ3 — PRODUCT (D-06): which injuries the innkeeper can remove.** «Nelle correzioni l'oste può togliere (a) solo le ferite aggiunte dalla simulazione o a mano in questa missione; (b) anche quelle che il personaggio aveva prima.» **Recommended: (a)** — «in eccesso» = added by the engine; healing stays with heal quests/potions.
4. **PQ4 — PRODUCT: a mission without fights.** «Una story narrativa senza combattimento si può completare senza scontri (niente simulazione, solo premi)? (a) sì; (b) no, almeno uno scontro.» **Recommended: (a)** — today's form allows a completion with no change (Phase 10 step 6 UAT).
5. **PQ5 — PRODUCT (D-07): coins and xp.** «Monete e PE del blocco del rango: (a) si possono solo togliere o tenere; (b) l'oste può cambiarne la quantità.» **Recommended: (a)** — the BE revalidates against the block, no free amounts.
6. **PQ6 — PRODUCT/copy: names of the inner POIs.** POIs have no name on the wire. «Sulla Mappa della Locanda e nel passo «Luogo» il luogo si chiama (a) col tipo («Rovine», «Foresta»…) più la città vicina («Rovine presso Talmvere»); (b) solo col tipo.» **Recommended: (a)** with 29 Italian type labels proposed in the plan (e.g. `ruins` «Rovine», `forest` «Foresta», `graveyard` «Cimitero», `swamp` «Palude», `dungeon` «Sotterraneo», `vulcano` «Vulcano», `demonicPortal` «Portale demoniaco»; regional names like `minnelyForest` «Foresta di Minnely» — final list by the user).
7. **PQ7 — minor PRODUCT: the card's «Teletrasporta».** With step 1 in the wizard, keep the card-level «Teletrasporta» (Phase 10)? **Recommended: keep** (no decision removes it; it uses the same widened targets; zero churn in `innkeeper_panel_screen_test.dart:575-760`).
8. **Wizard copy (discretion, proposed):** AppBar «Completa la missione»; header «Passo k di 5 · Luogo / Scontri / Scontro k di N / Premi / Riepilogo»; buttons «Inizia la missione», «Teletrasporta il gruppo», «Resta qui», «Indietro», «Avanti», «Aggiungi scontro», «Rimuovi scontro», «Cerca», «Mostra tutti», «Simula», «Rilancia», «Cambia nemici», «Aggiungi premio», «Completa», «Scarta la bozza»; start note «Da ora i partecipanti non possono viaggiare, accettare missioni, comprare o cambiare equipaggiamento fino all'esito»; discard dialog «Scartare la bozza?» / «I partecipanti tornano liberi; il teletrasporto resta.»; leave note «La bozza resta salvata: puoi riprenderla dalla Locanda»; states «Da simulare», «Vittoria», «Sconfitta»; card label «Riprendi» (if N-4); teleport chip «Trascina {nome} su una città o un luogo».
9. **BE-side, not product:** final names/nullability (N-1..N-15); whether options are a query or part of the draft; zero-fight rule; version field.

## Common Pitfalls

### Pitfall 1: the landing kills the wizard
`teleport_mode_landing.dart:54-61` pops every root route (PROBE). Plan the return target (F-3) in the teleport plan, not later.

### Pitfall 2: gated selection on the character fragment
`missionInProgress` in `statusFields` before the merge breaks `character`/`characterUpdated` on today's BE → the app loses its character. Model pre-gate, selection gated.

### Pitfall 3: silent derived flag
A resolved `missionInProgress` that changes without a character write is invisible until another emission (N-11). Device step: start a draft, watch the participant's phone without touching it.

### Pitfall 4: stale card after the teleport
The queue does not re-emit on location change; the wizard reads place from the draft/new snapshot.

### Pitfall 5: actionable filter popping the wizard
`PendingRequestsState.cards` drops cards for transient reasons; listen to `requests`.

### Pitfall 6: drop rule shared with player travel
`PawnDragging` serves the player's pawn too (`character_marker_layer.dart`); the POI rule must be an override for the teleport pawn only; player tests (`world_map_travel_test.dart`) stay green.

### Pitfall 7: registry pins in four files
Each new document moves `schema_check_documents_test.dart:33`, `travel_documents_test.dart:179`, `shop_documents_test.dart:132`, `loot_fragment_test.dart:125`.

### Pitfall 8: strict enums in served models
`asNameMap()` for `MissionStep`, verdict, prize kind; one unknown value must drop at most one entry, never the draft.

### Pitfall 9: Slider divisions with large max
`divisions: max - 1` already works with HP ≈ 14 550 (10-HUMAN-UAT step 7); keep the label + number; with max = 1 hide the slider (`participant_override_section.dart:38`).

### Pitfall 10: `map_utils.dart` not formatter-clean
Style commit first or put the POI rule in a new file.

### Pitfall 11: the innkeeper's own character as a participant
`MapAvailabilityState.isTeleportMode` blocks the GM's own result sheets during teleport mode (Phase 10 D-15); after completion the GM's own result sheet arrives when the mode is off — device check in E2E.

### Pitfall 12: REQUIREMENTS.md scope
Add GMFLOW IDs before plans reference them.

## Code Examples

### Lenient status flag (pattern `Quest.awaitingRescue`)
```dart
// Source: lib/models/quest/quest.dart:47 (pattern)
missionInProgress: json['missionInProgress'] == true,
```

### Shared refusal code (pattern `character_imprisoned.dart:4-6`)
```dart
// lib/repository/mission_in_progress.dart
/// Rifiuto delle azioni bloccate durante una missione (BE Phase 22, D-11/D-12).
const String missionInProgressCode = 'MISSION_IN_PROGRESS';
// in each classifier switch:
missionInProgressCode => TravelFailure.missionInProgress,
```

### Overridable drop rule (sketch)
```dart
// lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart (today :45 calls MapUtils.dropTargetCity)
City? dropTargetFor(LatLng point) => MapUtils.dropTargetCity(point, dropCities);
```

### Wizard exit on a vanished request
```dart
BlocListener<PendingRequestsCubit, PendingRequestsState>(
  listenWhen: (_, current) => current.isLoaded &&
      !current.requests.any((request) => request.id == card.pendingQuestId),
  listener: (context, _) => Navigator.of(context).pop(const CompletionGone()),
)
```
(for a worldMission compare `request.quest.id == card.questId`.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One form, overrides of HP/added injuries/consumables/spells (Phase 10) | Guided wizard over a served draft: teleport → fights → BE simulation → corrections → prizes → completion | this phase | form, cubit and override models retired in the gated plan |
| Teleport drop on city markers only (Phase 10 D-16) | City markers + inner POIs | D-01 | POI document + layer + drop hook |
| Lock states: travel/lane/aid/prison | + `missionInProgress` across Journal and shop | D-11/D-12 | one more input in the existing gates |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Draft wire names of `21-REPO-RULES.md` (`missionEnemies`, `simulateMissionFight`, `MissionDraft`, `start/save/discardMissionDraft`, `missionPrizeOptions`, `completeGuidedMission`, `missionInProgress`, `MISSION_IN_PROGRESS`) | all | renames in the gated plan (one fragment + parsers per type) |
| A2 | A dedicated `GetMissionDraft` query (draft not embedded in the queue entries) | F-4, F-11 | if embedded: the fragment moves into `PendingRequestFragment`, the queue payload grows, the subscription would not stream draft changes |
| A3 | Bestiary «hundreds» of enemies (count not read) | F-5 | none for the design (lazy list) |
| A4 | Number of POIs small enough for one list read (count not read) | F-2 | if thousands: filter by visible bounds / zoom |
| A5 | Wizard pages: Luogo, Scontri, Scontro k (simulate + correct), Premi, Riepilogo | F-4 | discretion; layout only |
| A6 | Full suite 4339 (not re-run per the rules) | Validation | baseline number in the gate SUMMARY only |
| A7 | Italian copy of Open Questions 1, 6, 8 | Open Questions | orchestrator/user fix it in REPO-RULES |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | analyze/test | ✓ | analyzer ran (`47 issues found`) | — |
| BE `pointOfInterests` query | GMFLOW-01 pre-gate | ✓ (SDL `src/schema.gql:602`) | — | — |
| Node + BE `node_modules/graphql` | schema check | ✓ (used in Phase 20) | — | — |
| BE merged SDL with Phase 22 | gated plans | ✗ (BE research in progress) | — | park at N−2/N |
| Device + BE boot + UAT data | E2E | orchestrator/user | — | none (human checkpoint) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test ^10.0.0` + `mocktail ^1.0.5` (+ `fake_async` where timers) |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers `test/helpers/` |
| Quick run command | `flutter test <touched test files>` (foreground) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (gate plan only, timeout ≥ 300 000 ms) |
| Analyzer gate | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| Schema gate | block-anchored `awk` checks on `git -C <BE> show origin/develop:src/schema.gql` + `dump_documents.dart` / `validate_documents.js` → N × OK |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GMFLOW-01 | POI list parsed leniently; drop resolves nearest inner POI within radius else city; same place → no call; return target reopens panel + wizard | unit + bloc + widget | `flutter test test/models/travel test/screens/mainScreen/tabs/map test/screens/mainScreen/components/teleport_mode_landing_test.dart test/screens/innkeeper/innkeeper_panel_screen_test.dart` | ✅ extend; ❌ W0 `teleport_poi_layer_test.dart`, `teleport_drop_test.dart`, `teleport_destination_test.dart` |
| GMFLOW-02 | load/start/resume at served step/discard; exits on NOT_FOUND/FORBIDDEN/request gone; no submit while in flight | bloc + widget | `flutter test test/screens/innkeeper/missionCompletion` | ❌ W0 |
| GMFLOW-03 | enemy list served, name search, «Mostra tutti» refetch, picks × quantity, fights add/remove, one save | bloc + widget | same dir | ❌ W0 |
| GMFLOW-04 | simulate/rerun, outcome rendering, slider from simulated HP within served bounds, injuries removable, steppers within served bounds, «Da simulare» from served null | unit + widget | same dir + `test/screens/innkeeper/components/injury_chips_test.dart` | ❌ W0 |
| GMFLOW-05 | prefilled entries, remove, add from catalogue (tabs, search), spells tab empty when served empty | bloc + widget | same dir | ❌ W0 |
| GMFLOW-06 | recap text, neutral confirm, complete → results recap, failures per code; old form deleted | unit + widget | `flutter test test/screens/innkeeper` | ✅ panel test; ❌ W0 recap |
| GMFLOW-07 | `missionInProgress` parsed; blocked line on Board; shop page closed; pawn label; drag gate; Journal rows disabled with status line; `MISSION_IN_PROGRESS` in 7 classifiers + notices | unit + widget | `flutter test test/models/character test/models/quest test/repository test/screens/mainScreen` (targeted files) | ✅ extend; ❌ W0 `equipment_failure_test.dart`, `equipment_repository_test.dart`, `mission_lines_test.dart` |
| GMFLOW-07 | `statusFields` selects `missionInProgress` (gated) | document pin | `flutter test test/graphql` | ✅ add pin |
| GMFLOW-08 | gate + N × OK + full suite | gate | gate script + schema check + full suite | ✅ |
| GMFLOW-08 | device: wizard end to end, lock and notice on the participant, release at completion and at discard, normal-mission lock | manual | `21-HUMAN-UAT.md` | ❌ (created in the last plan) |

### Pinned assertions that go RED or are retired
| File:line | Pins | Plan / action |
|-----------|------|---------------|
| `test/screens/mainScreen/tabs/map/components/teleport_mode_chip_test.dart:76-83` | «Trascina Bea su una città» | teleport plan: new copy |
| `test/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit_test.dart:180-280` | `teleportTo(City)` | teleport plan: `teleportTo(TeleportDestination)` |
| `test/screens/mainScreen/tabs/map/world_map_teleport_test.dart:242-262, :313-340` | only pawn + cities in teleport mode; `verify(teleportTo(cityB))` | teleport plan: + POI layer, destination type |
| `test/screens/mainScreen/tabs/map/teleport_pawn_layer_test.dart:125-135` | release east → nearest city | stays green (no POI near); add POI cases |
| `test/screens/mainScreen/components/teleport_mode_landing_test.dart:177-200` | success/cancel reopen the panel | stays green; add resume cases |
| `test/screens/innkeeper/innkeeper_panel_screen_test.dart:372-384` («tapping it opens the completion form» → `RequestCompletionScreen`), `:386-560` (exits of the form) | Phase 10 form | gated plan: retarget to the wizard / retire |
| `test/screens/innkeeper/request_completion_screen_test.dart` (466 lines), `test/screens/innkeeper/requestCompletionCubit/request_completion_cubit_test.dart` (364), `test/screens/innkeeper/components/completion_form_test.dart` (319), `test/models/request/participant_draft_test.dart`, `participant_override_test.dart`, `completion_recap_test.dart:48-89` (`confirmationRecapOf`) | Phase 10 form and its models | gated plan: deleted RED-first with the sources (`resultRecapLinesOf`/`recapNameOf` cases `:91-131` stay) |
| `test/screens/innkeeper/components/completion_form_test.dart:134-142` («an existing injury is selected and disabled») | injury chips | C-2: keep for pre-existing, add removable cases (move to `injury_chips_test.dart`) |
| `test/tool/schema_check_documents_test.dart:33`, `test/graphql/travel_documents_test.dart:179`, `shop_documents_test.dart:132`, `loot_fragment_test.dart:125` | registry = 46 | every plan that adds/removes documents |
| `test/repository/*_failure_test.dart` (travel, quest_acceptance, transaction, spell_equip, pet_equip, item_use, innkeeper) | code tables | lock plumbing plan: add `MISSION_IN_PROGRESS` rows |

### Sampling Rate
- **Per task commit:** touched tests + analyzer gate + trailer check
- **Per plan:** the test directories named in the plan
- **Phase gate:** full suite green, schema check N × OK, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/helpers/fixtures/mission_fixtures.dart` — `missionDraftJson({step, fights, …})`, `missionFightJson`, `simulatedOutcomeJson`, `missionEnemyJson`, `prizeOptionsJson`, `pointOfInterestJson`
- [ ] `test/models/mission/*_test.dart` — fromJson/toJson/Equatable/lenient per entry
- [ ] `test/screens/innkeeper/missionCompletion/**` — cubits (bloc_test) and pages (widget)
- [ ] `test/screens/mainScreen/tabs/map/layers/teleport_poi_layer_test.dart`, `utils/teleport_drop_test.dart`
- [ ] `test/repository/equipment_failure_test.dart`, `equipment_repository_test.dart`; `test/utils/mission_lines_test.dart`
- [ ] Mocks: `MockMissionDraftCubit`/`MockMissionEnemiesCubit` in `test/helpers/mocks.dart` (pattern of existing mock cubits)
- No framework install, no golden test (none exist).

### Device E2E outline (last plan, human; one Samsung, innkeeper account)
Accounts/data: the innkeeper's own character (the streamer always has one, Phase 10 D-02) + one second account's character, both on the same worldMission (seats seeded at DB as in 10-HUMAN-UAT); a story for the innkeeper's character; a worldMission with rank blocks (FE/BE Phase 20) written at DB by the orchestrator. One device is enough if the innkeeper's own character participates: the lock and the notice are seen on the same phone after closing the Locanda; the second character's refusals are proved by the orchestrator's GraphQL probes with that bearer (`MISSION_IN_PROGRESS`).
1. «Completa» on the worldMission → «Inizia la missione» → draft created; leave the Locanda: own pawn «Missione in corso», Journal rows disabled, shop page closed, Board line; drag the pawn → nothing. Probe the second character: `startTravel`/`acceptQuest`/`doTransaction`/`equipItem`/`useItem` → `MISSION_IN_PROGRESS`.
2. Reopen the Locanda → card resumes the draft at «Luogo» → «Teletrasporta il gruppo» → drop on an inner POI → back in the wizard at the same request, pawns moved; «Resta qui» skip on a second run.
3. «Scontri»: filtered list, search, «Mostra tutti», two fights with quantities → «Avanti».
4. Fight 1 «Simula» (loader) → outcome; «Rilancia»; corrections (slider, remove an engine injury, add one, consumables/spells); fight 2 simulated from fight 1's corrected state; change fight 1's enemies → fight 1 and 2 «Da simulare».
5. Close the app, reopen from Settings → the wizard resumes at the served step (also from a second device if available).
6. «Premi»: prefilled block per character, remove one, add from catalogue (a pet; a spell only for the mage).
7. «Riepilogo» → «Completa» → confirmation → results recap; players get the result sheet with the enemies faced; lock released live.
8. Discard path on the story: start → «Scarta la bozza» → lock released live; teleport stays.
9. D-12: a normal hunt after arrival → Journal locked with «Missione in corso», released at the result.
Not observable on the device (tests only): every classifier row, lenient parsing, invalidation edge cases, stale-draft code (if N-9), two-device concurrency (optional).

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged |
| V3 Session Management | no | unchanged |
| V4 Access Control | yes | every mission operation `@Roles(innkeeper)` + audit on the BE; FE isolates them in `InnkeeperRepository`; `FORBIDDEN` closes the panel (Phase 10 D-04); `missionInProgress` read only on the owner's character |
| V5 Input Validation | yes | BE validates picks, corrections, prizes (revalidation); FE clamps controls to served bounds; lenient parsing at the model boundary (`asNameMap`, `tryFromJson` per entry) |
| V6 Cryptography | no | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered prize/correction sent by a modified client | Tampering | BE revalidation with the catalogue function (D-07) and override rules |
| Player bypasses the lock with a stale client | Elevation | BE `MISSION_IN_PROGRESS` on every locked mutation (N-2); FE gates are convenience |
| Draft or simulation exposed to players | Information disclosure | innkeeper-only operations; nothing of the draft on player documents; no `appLog` of payloads |
| Malformed draft drops the wizard | DoS | per-entry lenient parsing; `asNameMap()` |

## Sources

### Primary (HIGH confidence)
- Codebase `feat/21-innkeeper-mission-completion` `eacdf70b`: files cited inline; analyzer run; per-file formatter checks (only `lib/screens/mainScreen/tabs/map/utils/map_utils.dart` not clean among 89 candidates); probes `landing_wizard_probe_test.dart`, `enemy_slim_probe_test.dart` (run, deleted).
- BE read-only (`bf3e39c8`): `src/schema.gql` (`CharacterStatus`, `Enemy`, `QuestRankPrizes`, `QuestPrizes`, `CompletePendingRequestInput`, `ParticipantOverrideInput`, `PendingRequest*`, `PointOfInterest`, `City`, `Quest`, `QuestResult`, `enum PoiType`), `src/gameRules/game-rule-error-code.enum.ts`, `src/quests/outcomes/gm-overrides.ts`, `gm-completion.service.ts`, `src/pointsOfInterest/point-of-interest.resolver.ts`/`.service.ts`, `src/models/point-of-interest.model.ts`, `src/travel/travel-admin.resolver.ts`, `travel.service.ts:221-251`, `src/lore/lore-geography.reader.ts`, `src/characters/character-updates.publisher.ts`; `.planning/phases/22-completamento-guidato-missioni/22-CONTEXT.md`, `22-REPO-RULES.md`.
- Planning: `21-CONTEXT.md`, `21-REPO-RULES.md`, `21-DISCUSSION-LOG.md`, `10-CONTEXT.md`, `10-HUMAN-UAT.md`, `20-RESEARCH.md`, `20-HUMAN-UAT.md`, `ROADMAP.md`, `STATE.md`, `PROJECT.md`, `REQUIREMENTS.md`, `docs/rules/*.md`.

### Secondary / Tertiary
- None (no web sources needed: the domain is this codebase and its BE).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — nothing new.
- Architecture: HIGH for the FE map and the landing behaviour (probed); MEDIUM for file counts (depends on the BE shape).
- Pitfalls: HIGH — each tied to a file:line or a probe.

**Research date:** 2026-11-13
**Valid until:** the BE Phase 22 research fixes the SDL (then refresh names in both REPO-RULES).

## Recommended plan cut (sequential, TDD, one concern per plan)

| # | Plan | Gate | Depends on | Req |
|---|------|------|-----------|-----|
| 21-01 | Lock plumbing: `CharacterStatus.missionInProgress` (lenient, not selected), `mission_in_progress.dart`, `mission_lines.dart`, `MISSION_IN_PROGRESS` in travel/acceptance/transaction/spell/pet/item-use classifiers + notices; `EquipmentRepository` + `EquipmentFailure` (LB-1) with `JournalCubit` through it | pre-gate | PQ1/PQ2 copy in REPO-RULES | GMFLOW-07 |
| 21-02 | Players' lock on Board, Map, satchel: `QuestViewer.isOnMission` → `QuestAvailability.missionInProgress` line; shop page closed; drag gate; pawn label (per PQ1) | pre-gate | 21-01 | GMFLOW-07 |
| 21-03 | Players' lock in the Journal: equipment taps, companion toggle, spell toggle, potions disabled with «Missione in corso»; equipment refusal notice | pre-gate | 21-01 | GMFLOW-07 |
| 21-04 | Step 1: `ListPointsOfInterest` (registry +1), `TeleportDestination`, `PoiType` labels + `demonicPortal`, `TeleportPoiLayer`, drop hook, chip copy, `resumeCardKey` through cubit/landing/panel (live against today's BE) | pre-gate | PQ6 | GMFLOW-01 |
| 21-05 | Mission models + `MissionDraftFragment` + documents + `InnkeeperRepository` methods + failure codes + fixtures + document pins (registry +8) | pre-gate | BE draft names | GMFLOW-02..06 |
| 21-06 | `MissionDraftCubit`, `MissionEnemiesCubit`, `MissionPrizeOptionsCubit` (bloc_test on fakes) | pre-gate | 21-05 | GMFLOW-02..05 |
| 21-07 | Wizard UI 1: route/screen/header/bottom bar, start/resume/discard/exits, «Luogo» page (teleport + skip, resume), «Scontri» page (enemy picker); **not wired** to «Completa» | pre-gate | 21-04, 21-06 | GMFLOW-01..03 |
| 21-08 | Wizard UI 2: fight page (simulate/rerun, outcome, corrections, `InjuryChips` removable), «Premi» page (list + catalogue sheet), «Riepilogo» + confirm + results recap | pre-gate | 21-07 | GMFLOW-04..06 |
| 21-09 | Schema gate on the merged BE SDL → renames RED-first if names differ → select `missionInProgress` in `statusFields` → wire «Completa» to the wizard → delete the Phase 10 form, its cubit, override models and `CompletePendingRequest` (RED-first) → registry final → schema check N × OK → full suite | **gated on BE Phase 22 merge** | 21-01..21-08 | GMFLOW-06, -07, -08 |
| 21-10 | Device E2E (`21-HUMAN-UAT.md`), `BACKEND-NOTES.md`, requirements mark-complete, closing docs | **gated, human** | 21-09; BE boot + UAT data | GMFLOW-08 |

21-04 can move before 21-01 (independent, and the only pre-gate change visible on the device). If the BE serves prize options inside the draft or folds start/save, 21-05/21-06 shrink; the cut does not change.

## RESEARCH COMPLETE
