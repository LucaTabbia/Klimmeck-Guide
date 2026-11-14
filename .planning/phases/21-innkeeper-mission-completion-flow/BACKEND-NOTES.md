# Phase 21 (FE) — Backend notes

Written by plan 21-18 (Task 1) after the BE Phase 22 merge; §3 is completed by plan 21-18 (Task 3) after the device E2E.

Frontend companion of the BE Phase 22 («Completamento guidato delle missioni»). Branch `feat/21-innkeeper-mission-completion`. English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file. BE ref read by the gate: `origin/develop` `4aed73bb` (PR #40 on top of the Phase 22 merge `f82ab278`, no SDL change between them). The device UAT ran on `feat/mission-start-push` (BE PR #41 on top of `4aed73bb`): see §3 and the merge order in §4.

## 1. Contract consumed by the FE

Names, types and nullability confirmed on the merged SDL by plan 21-16 (gate `GATE_OK`, no deviation from `21-REPO-RULES.md` §Final wire). Schema check (plan 21-17): registry of **54** documents (`tool/schema_check/schema_check_documents.dart`), 54 × OK on `f82ab278`; the Phase 10 `CompletePendingRequest` document is removed (D-25).

Selection points:

- `CharacterFragment.statusFields` (`lib/graphql/fragments/character_fragment.dart`): `… imprisonedUntil missionInProgress guidedMissionInProgress spellStates { … }` — used by `character`, `characterUpdated` and every document that embeds the character.
- `PendingRequestFragment.fields` (`lib/graphql/fragments/pending_request_fragment.dart`): `id startDate missionDraftStartedAt quest { … }` — `pendingRequests` and `pendingRequestsUpdated`.
- `MissionDraftFragment.fields` and `MissionEnemyFragment.fields` (`lib/graphql/fragments/mission_draft_fragment.dart`): the whole `MissionDraft` (step, place, participants, fights with enemies / outcomes / verdict, `consumablesAvailable`, `injuriesBefore`, `spellsAvailable`, `simulated`, `corrected`, prizes).

| Operation (document) | Field | FE file |
|----------------------|-------|---------|
| query `GetMissionDraft` | `missionDraft(pendingQuestId)` → `MissionDraft` (nullable) | `lib/graphql/queries/mission_queries.dart` |
| query `ListMissionEnemies` | `missionEnemies(pendingQuestId, showAll)` → `[Enemy!]!` (always sends `showAll`) | `lib/graphql/queries/mission_queries.dart` |
| query `GetMissionPrizeOptions` | `missionPrizeOptions(characterId, pendingQuestId)` → `MissionPrizeOptions!` (`block { prizeItem randomLoot pet spell cure }`, catalogue `equipment`, `loot`, `pets`, `spells`, `maxRarity`, `title`) | `lib/graphql/queries/mission_queries.dart` |
| query `ListPointsOfInterest` | `pointOfInterests` (inner places for the teleport, D-29) | `lib/graphql/queries/point_of_interest_queries.dart` |
| mutation `StartMissionDraft` | `startMissionDraft(pendingQuestId)` → `MissionDraft!` | `lib/graphql/mutations/mission_mutations.dart` |
| mutation `SaveMissionDraft` | `saveMissionDraft(input: SaveMissionDraftInput!)` → `MissionDraft!` | `lib/graphql/mutations/mission_mutations.dart` |
| mutation `SimulateMissionFight` | `simulateMissionFight(input: SimulateMissionFightInput!)` → `MissionDraft!` | `lib/graphql/mutations/mission_mutations.dart` |
| mutation `DiscardMissionDraft` | `discardMissionDraft(pendingQuestId)` → `CommonResponse!` | `lib/graphql/mutations/mission_mutations.dart` |
| mutation `CompleteGuidedMission` | `completeGuidedMission(pendingQuestId)` → `[QuestResult!]!` | `lib/graphql/mutations/mission_mutations.dart` |
| mutation (existing) | `teleportCharacter(request)` with an inner POI id (no contract change, D-01) | `lib/graphql/mutations/travel_mutations.dart` |

- Network calls: `lib/graphql/graphql.dart` (`KlimmeckGraphQl`), repository `lib/repository/innkeeper_repository.dart` (innkeeper side, existing failure mapping only) and `lib/repository/equipment_repository.dart` (new, players' `equipItem` refusal made visible).
- Players' refusal: `extensions.code` = `MISSION_IN_PROGRESS` (`lib/repository/mission_in_progress.dart`, the only place of the literal).
- Saves send `corrections` only for the fight being corrected; every other fight goes with `corrections` absent, and «Cambia nemici» sends no corrections at all (the BE keeps the unchanged prefix and voids the later fights itself) — review fixes B-01, B-02.

## 2. FE behaviours proved by tests

- **Two booleans (D-16):** pawn label «Missione in corso» ← `guidedMissionInProgress` only (`character_marker_layer.dart`, also blocks the drag); Journal / Board / satchel lock ← `missionInProgress` (one reader `Character.isOnMission`). Never derived from lanes or quests; absent or malformed → `false`.
- **Lock gates per surface:** Board line «Missione in corso: aspetta l'esito» on every quest, stories included (`QuestAvailability.missionInProgress`, torn sheet); satchel shop page closed (`disabledSatchelPages`); Journal armour, companion, spells and heal potions show «Missione in corso» and do nothing (`items_section.dart`, `companion_section.dart`, `spells_section.dart`, shared `MissionLockedSection`); own pawn not draggable during the guided flow.
- **`MISSION_IN_PROGRESS` in seven classifiers**, each with the banner description «Sei impegnato in una missione: aspetta l'esito» and the title of its action: `travel_failure.dart`, `transaction_failure.dart`, `quest_acceptance_failure.dart`, `spell_equip_failure.dart`, `pet_equip_failure.dart`, `item_use_failure.dart`, and the new `equipment_failure.dart` (title «Equipaggiamento non cambiato»; before this phase an `equipItem` refusal was silent).
- **Lenient parsing (21-10):** every mission model is `tryFromJson`; unknown enums give `null` / a fallback (never `byName`); a malformed entry drops the entry, never the draft; ints and instants read leniently.
- **Served bounds (rule 4):** HP slider `1..maxLifePoints`, consumable / spell steppers up to `consumablesAvailable` / `spellsAvailable`, `injuriesBefore` shown selected and not removable (D-14, per fight); caps 10 fights, 10 entries per fight, quantity 1..20, prize item 1..99, coins / xp digits only, at most 7 (BE ceiling 9 999 999). Enemy and prize lists are never filtered by rank, habitat or rarity in the app.
- **Invalidation shown from `verdict`:** a fight with a null `verdict` reads «Da simulare»; «Avanti» of «Premi» and «Completa» stay disabled until every served fight is simulated (`MissionDraft.allFightsSimulated`, true with zero fights); `_saveFights` sends `step: fights` so a resume never lands past «Scontri» with fights to simulate (B-07).
- **Explicit start:** opening the wizard reads the draft; with none it offers «Inizia la missione» — the draft is never created on open.
- **Resume:** the card reads «Riprendi» when any entry of the request has `missionDraftStartedAt`; the wizard opens at the served step. After the Map, the Locanda is reopened from `resumeCardKey` and the wizard is rebuilt from the served draft (no wizard state kept in memory across the Map).
- **Inner-POI drop rule (D-29, 21-08):** only the teleport pawn accepts inner places: nearest place within 32 px at or above `MapConstants.cityVisibleZoom`, else the city as in Phase 10; a place without a known type is not a destination. The players' travel drop is unchanged.
- **Completion:** recap + explicit confirmation «Completa la missione», then the results recap of the Locanda; `OUTCOME_OVERRIDE_INVALID` in the wizard reads «Operazione rifiutata: controlla scontri, correzioni e premi».

## 3. UAT outcome (FE Phase 21, 2026-11-14)

**Approved.** Mandatory steps 1–10 passed, optional step 11 passed, optional step 12 not run (user's choice). Record: `21-HUMAN-UAT.md`.

BE under test: branch `feat/mission-start-push` (BE PR #41, not merged at the time of recording; local tip `6dbfd9df`) = `develop` `4aed73bb` + the `missionStart` push + the POI city fix + the lane quest type — NOT `origin/develop`. Booted by the orchestrator on port 3001; a second instance on 3002 with the second account's dev bearer (never printed) served the probes. Characters: the innkeeper's own (legend) and a second account's (rookie); worldMission with `rookie` / `legend` seats and rank blocks, a story with `minTitle` legend, a normal hunt with a 3 min wait.

Outcomes relevant to the BE:

- **Start and lock (step 1):** `startMissionDraft` wrote a draft for 2 participants (DB). Probes of the second character: `travelPreview`, `startTravel`, `acceptQuest`, `doTransaction`, `equipItem`, `useItem` → all `MISSION_IN_PROGRESS`. The lock showed on the innkeeper's own character after leaving the Locanda (pawn label, Journal, shop, Board). The `missionStart` push (PR #41) reached the participants.
- **Teleport onto an inner POI (step 2):** BE defect found — `pointOfInterests { city { id name } }` failed (city not populated), so no «tipo presso città» and no place dots; fixed in PR #41 («serve the city of each place in the place list»). After the fix `teleportCharacter` with an inner POI id moved both pawns and the wizard came back on the same request.
- **Encounters (step 4):** `missionEnemies` listed the legendary on the graveyard place for the worldMission; two fights saved with `saveMissionDraft`.
- **Simulation from the corrected state (step 5):** DB confirmed that fight 2 starts from fight 1's corrected state. «Rilancia» returns the same numbers (placeholder engine, accepted by the user; the real engine comes later); the draft `rev` grows at every rerun. Invalidation after «Cambia nemici» read from the served `verdict`.
- **Resume (step 6):** after closing the app the wizard reopened on the served step (`missionDraft` + `missionDraftStartedAt`).
- **Prizes (step 7):** `missionPrizeOptions` served different blocks per rank; the rookie's spell catalogue is empty (correct for the user); coins / xp above the block, a removed entry and an added pet went through to the summary.
- **Completion (step 8):** `completeGuidedMission` wrote two `gmCompleted` results with the 3 enemies of the two fights; draft and requests gone, mission concluded, cure applied; result sheets on both players; lock lifted live. FE race fixed on the branch: `pendingRequestsUpdated` can arrive before the completion answer (the FE no longer reads it as «request gone» while its own call is in flight).
- **Discard (step 9):** `discardMissionDraft` cleared the marker; the request came back to the queue; lock lifted live — `characterUpdated` and `pendingRequestsUpdated` at discard work.
- **Normal mission lock (step 10):** a hunt with a 3 min wait set `missionInProgress` without `guidedMissionInProgress`; Journal / Board locked, no guided pawn label; released at the result. The activity label over the pawn reads the quest type on the lanes (PR #41).
- **Zero fights (step 11):** a narrative story completes with no fight.

## 4. Questions and notes for the BE

1. `characterUpdated` must be emitted at draft start and at discard even though no character document is written (`MissionDraftLockPublisher`, per the BE handoff), and at the outcome: the FE has no other trigger to show or lift the lock live.
2. `pendingRequestsUpdated` must re-emit the queue at draft start and discard with `missionDraftStartedAt` set / null: it drives «Riprendi» on the card.
3. `completePendingRequest` can now be removed (D-25): no FE document uses it since plan 21-17.
4. Lock precedence accepted (BE A-02): `PET_NOT_OWNED` and `SHOP_NOT_IN_CITY` arrive after `MISSION_IN_PROGRESS`; a worldMission registration with an open draft gets `QUEST_NOT_ACCEPTABLE` (already mapped).
5. Completion read/retry: a save between the completion's read and its delete gives `OUTCOME_OVERRIDE_INVALID` with no write; the FE shows the refusal and the innkeeper retries after the reread.
6. Copy or labels the user changed at the UAT: none of the proposed strings was amended. Copy written by the orchestrator during the UAT and still open to review: the push «La missione comincia» / «L'oste ha dato inizio a «titolo»» (category «Inizio missione»), «Missione accettata» / «L'oste è stato avvisato: la missione comincerà quando la avvia», «In preparazione…», the activity labels (Cacciando…, Esplorando…, Combattendo…, Soccorrendo…, Studiando…, In cura…, Lavorando…, Tramando…, Di guardia…).
7. **Merge order: BE PR #41 (`feat/mission-start-push`) must be merged BEFORE the FE PR** `feat/21-innkeeper-mission-completion` → `develop`. What the FE branch now needs from PR #41:
   - `PushEventType.missionStart` — the push sent to the participants when the innkeeper starts the mission (FE category «Inizio missione», tap = own pawn on the Map);
   - `pointOfInterests.city` populated (`city { id name }`) — the «<tipo> presso <città>» labels and the inner-place dots of the teleport;
   - `pendingQuest.quest.infos.type` served on the lanes of a character — the activity label over the pawn; a BE without it serves the lane type as null.
8. The placeholder simulation engine returns the same numbers on «Rilancia» (accepted for now); the FE reads whatever the real engine will serve, no FE change expected.
