# Phase 21 (FE) — Backend notes

Written by plan 21-18 (Task 1) after the BE Phase 22 merge; §3 is completed by plan 21-18 (Task 3) after the device E2E.

Frontend companion of the BE Phase 22 («Completamento guidato delle missioni»). Branch `feat/21-innkeeper-mission-completion`. English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file. BE ref read by the gate: `origin/develop` `4aed73bb` (PR #40 on top of the Phase 22 merge `f82ab278`, no SDL change between them).

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

## 3. UAT outcome (FE Phase 21, <date>)

Filled by plan 21-18.

## 4. Questions and notes for the BE

1. `characterUpdated` must be emitted at draft start and at discard even though no character document is written (`MissionDraftLockPublisher`, per the BE handoff), and at the outcome: the FE has no other trigger to show or lift the lock live.
2. `pendingRequestsUpdated` must re-emit the queue at draft start and discard with `missionDraftStartedAt` set / null: it drives «Riprendi» on the card.
3. `completePendingRequest` can now be removed (D-25): no FE document uses it since plan 21-17.
4. Lock precedence accepted (BE A-02): `PET_NOT_OWNED` and `SHOP_NOT_IN_CITY` arrive after `MISSION_IN_PROGRESS`; a worldMission registration with an open draft gets `QUEST_NOT_ACCEPTABLE` (already mapped).
5. Completion read/retry: a save between the completion's read and its delete gives `OUTCOME_OVERRIDE_INVALID` with no write; the FE shows the refusal and the innkeeper retries after the reread.
6. Copy or labels the user changes at the UAT: listed here by plan 21-18 (Task 3).
