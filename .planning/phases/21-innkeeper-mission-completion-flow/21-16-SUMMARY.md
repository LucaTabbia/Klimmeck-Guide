---
phase: 21-innkeeper-mission-completion-flow
plan: 16
subsystem: graphql, innkeeper
tags: [schema-gate, gated-selection, mission-wizard, D-16, D-17, D-23, D-25, D-28]
requires:
  - BE Phase 22 merged on BE develop (origin/develop f82ab278)
  - 21-15 (wizard complete, unreachable)
provides:
  - CharacterFragment.statusFields selects missionInProgress and guidedMissionInProgress
  - PendingRequestFragment selects missionDraftStartedAt
  - «Completa» and the resume after the Map open the mission wizard
affects: [21-17, 21-18]
tech-stack:
  added: []
  patterns: [block-anchored SDL gate, panel notice gated on ModalRoute.isCurrent]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/fragments/pending_request_fragment.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/pending_request_documents_test.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
decisions:
  - "Gate passed on BE origin/develop f82ab278: every name, type and nullability of the final wire confirmed, no deviation"
  - "The panel's teleport-failed notice is silent while a route sits above the panel: the wizard gives the only notice (double notice reproduced and fixed, D-28)"
metrics:
  duration: ~40 min
  completed: 2026-11-14
---

# Phase 21 Plan 16: Schema gate, gated selections, «Completa» wired to the wizard Summary

Schema gate passed on the merged BE Phase 22 SDL (`f82ab278`). The character fragment now selects `missionInProgress` and `guidedMissionInProgress`, and the queue entry selects `missionDraftStartedAt`. «Completa», «Riprendi» and the resume after the Map open `MissionCompletionScreen` through `openMissionCompletion`. A second, queued teleport-failed SnackBar under the wizard was reproduced and fixed.

**The branch now needs a BE with Phase 22**: against an older BE the selected fields lose the character and the queue.

## Task 1: Gate, contract proof, handoff, selections

- BE `git status --short` before: empty. After: empty (nothing written in the BE repo; only `show` / `log` / `ls-tree` on `origin/develop`).
- Gate block of the plan: `GATE_OK`. BE `origin/develop` log:
  ```
  f82ab278 Merge pull request #39 from LucaTabbia/feat/22-completamento-guidato-missioni
  ba45a3b0 docs(phase-22): add verification and security audit reports
  1d6751c7 docs(phase-22): record plan 18 progress
  32a827bf docs(phase-22): sign the validation and close the requirements
  1bc4be64 docs(phase-22): write the FE handoff and the device UAT plan
  ```
- Extra check (normally done in 21-17, run here to make sure the new selections are valid): `dump_documents.dart` + `validate_documents.js` against the merged SDL → **55/55 documents OK**, exit 0.

### Contract proof (merged SDL, `f82ab278`)

```graphql
type CharacterStatus {
  activeTravel: ActiveTravel
  awaitingAid: AwaitingAid
  coins: Coins!
  currentLifePoints: Int!
  guidedMissionInProgress: Boolean!
  imprisonedUntil: DateTime
  injuries: [InjuryType!]!
  level: Int!
  location: PointOfInterest!
  maxActiveSpells: Int!
  maxLifePoints: Int!
  missionInProgress: Boolean!
  potionRecoveryUntil: DateTime
  spellStates: [SpellState!]!
  title: String!
  unlockedLore: [ID!]!
  xp: Int!
}
type PendingRequest {
  character: PendingRequestCharacter!
  id: ID!
  missionDraftStartedAt: DateTime
  pointsSpent: Int!
  quest: PendingRequestQuest!
  startDate: DateTime
  user: PendingRequestUser!
}
type MissionDraft {
  fights: [MissionFight!]!
  id: ID!
  participants: [MissionParticipant!]!
  place: ID
  prizes: [MissionPrize!]!
  quest: ID!
  questType: String!
  startedAt: DateTime!
  step: MissionDraftStep!
  updatedAt: DateTime!
}
type MissionFight {
  enemies: [MissionFightEnemy!]!
  outcomes: [MissionFightOutcome!]!
  verdict: MissionFightVerdict
}
type MissionFightOutcome {
  character: ID!
  consumablesAvailable: [MissionItemUsage!]!
  corrected: MissionFightEffects
  hpBefore: Int!
  injuriesBefore: [InjuryType!]!
  simulated: MissionFightEffects
  spellsAvailable: [MissionSpellUsage!]!
}
type MissionFightEffects {
  consumablesUsed: [MissionItemUsage!]!
  hpAfter: Int!
  injuriesAdded: [InjuryType!]!
  spellsUsed: [MissionSpellUsage!]!
}
type MissionPrize {
  character: ID!
  coins: Coins!
  cure: QuestCure
  items: [MissionPrizeItem!]!
  pet: ID
  spell: ID
  xp: Int!
}
type MissionPrizeOptions {
  block: QuestPrizes!
  character: ID!
  equipment: [EquipmentItem!]!
  loot: [LootItem!]!
  maxRarity: RarityType!
  pets: [Pet!]!
  spells: [Spell!]!
  title: String!
}
input SaveMissionDraftInput {
  fights: [MissionFightInput!]
  pendingQuestId: ID!
  place: ID
  prizes: [MissionPrizeInput!]
  step: MissionDraftStep
}
input SimulateMissionFightInput {
  enemies: [MissionEnemyInput!]!
  fightIndex: Int!
  pendingQuestId: ID!
}
input MissionPrizeInput {
  characterId: ID!
  coins: CoinsInput!
  cure: Boolean!
  items: [MissionPrizeItemInput!]!
  pet: ID
  spell: ID
  xp: Int!
}
# Query
  missionDraft(pendingQuestId: ID!): MissionDraft
  missionEnemies(pendingQuestId: ID!, showAll: Boolean = false): [Enemy!]!
  missionPrizeOptions(characterId: ID!, pendingQuestId: ID!): MissionPrizeOptions!
  pointOfInterests: [PointOfInterest!]!
# Mutation
  completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!
  discardMissionDraft(pendingQuestId: ID!): CommonResponse!
  saveMissionDraft(input: SaveMissionDraftInput!): MissionDraft!
  simulateMissionFight(input: SimulateMissionFightInput!): MissionDraft!
  startMissionDraft(pendingQuestId: ID!): MissionDraft!
```

**Names confirmed**: identical to the plan's `<interfaces>` and REPO-RULES §Final wire. No deviation.

### BE handoff (`.planning/phases/22-completamento-guidato-missioni/BACKEND-NOTES.md` on BE `origin/develop`): names and answers only

- **Refusal codes per operation:** `startMissionDraft` → NOT_FOUND, QUEST_IN_PROGRESS, FORBIDDEN; `missionDraft` → NOT_FOUND, FORBIDDEN; `saveMissionDraft` → NOT_FOUND (request, draft, POI, enemy), OUTCOME_OVERRIDE_INVALID, OUTCOME_NOT_PARTICIPANT, BAD_USER_INPUT, FORBIDDEN; `simulateMissionFight` → NOT_FOUND, OUTCOME_OVERRIDE_INVALID (order, range, caps), BAD_USER_INPUT, FORBIDDEN; `missionEnemies` → NOT_FOUND, FORBIDDEN; `missionPrizeOptions` → NOT_FOUND, OUTCOME_NOT_PARTICIPANT, FORBIDDEN; `discardMissionDraft` → NOT_FOUND, FORBIDDEN; `completeGuidedMission` → NOT_FOUND, QUEST_IN_PROGRESS, OUTCOME_OVERRIDE_INVALID, FORBIDDEN.
- **New innkeeper-side code:** none. Every code above is already mapped by `innkeeperFailureFrom` (`lib/repository/innkeeper_failure.dart`). The only new code is the players' `MISSION_IN_PROGRESS` (extensions = `{ code }` only), already mapped in 21-01..21-05.
- **Lock precedence (players):** existing codes win where they already fire (QUEST_IN_PROGRESS, QUEST_SLOT_BUSY, AWAITING_AID, CHARACTER_IMPRISONED, TRAVEL_IN_PROGRESS). Partial precedence accepted by BE ruling A-02: PET_NOT_OWNED and SHOP_NOT_IN_CITY come AFTER MISSION_IN_PROGRESS. A worldMission registration with an open draft gets QUEST_NOT_ACCEPTABLE. `teleportCharacter`, `deleteCharacter`, `abandonQuest`, `acknowledgeQuestResult` are not locked.
- **WS emissions:** `characterUpdated` carries both flags at solo start on arrival, at party start, **at draft start and discard** (`MissionDraftLockPublisher`), and at the outcome. `pendingRequestsUpdated` re-emits the queue at draft start and discard, with `missionDraftStartedAt` set or null.
- **Completion read/retry:** a save that lands between the completion's read and its delete gives `OUTCOME_OVERRIDE_INVALID` with no write: the FE reads the draft again and retries. Two concurrent completions: one wins, the other gets NOT_FOUND.
- **BE caps:** `MAX_MISSION_FIGHTS` 10, `MAX_FIGHT_ENEMIES` 10, `MAX_ENEMY_QUANTITY` 20 (1..20), `MAX_PRIZE_ITEM_QUANTITY` 99 (1..99), `MAX_PRIZE_AMOUNT` 9 999 999 (FE: 7 digits), `MAX_OVERRIDE_ENTRIES` 50, `MAX_PRIZE_ITEMS` 500. They match `mission_limits.dart` (10 / 10 / 1..20 / 1..99 / 7 digits). No deviation. Every saved or simulated fight needs at least one enemy (empty → OUTCOME_OVERRIDE_INVALID). A mission may have zero fights.
- **UAT data field NAMES for 21-18 (BE §6):** worldMission in `quests`: `infos { title, type: 'worldMission', markerLocation, enemies, timeToComplete, relatedLore, description }`, `requirements { minTitle, requiredAdventurers [{ title, count }], requiredPoints, recommendedLoot }`, `prizes { prizeCoins { gold, silver, copper }, xpPrize, prizeItem { itemType, item, quantity }, randomLoot, spell, pet, cure }` and `rankPrizes` [{ title, prizeCoins, xpPrize, prizeItem, randomLoot, spell, pet, cure { lifePointsShare, canHeal } }], `registeredAdventurers`, `concludedAt`, `startedAt`, `generated`. Story: `infos.type: 'story'`, `requirements.minTitle` = the exact title of the test character, single `prizes`. Legendary enemy: `legendary: true` with concrete `locations` that match the inner POI types (or `city`). For diagnosis: collection `missiondrafts`, field `missionDraftStartedAt` on the PendingQuests, `QuestResult` (`gmCompleted`, merged `enemies`). BE UAT steps 1..11 are in BE §6.
- `completePendingRequest` stays alive on the BE until the FE Phase 21 merge and deletes the request's draft inside its own transaction.

### TDD

- RED `121ff7f8`: 3 failures as expected (the names were not selected): «statusFields selects the two mission flags after imprisonedUntil (D-16, Pitfall 2)», «characterUpdated and character carry the mission flags (D-23)», «the queue entry selects missionDraftStartedAt after startDate (D-17)».
- GREEN `8cbbcdf3`: `flutter test test/graphql test/models test/screens/mainScreen test/screens/innkeeper` → +2896 all passed.

## Task 2: «Completa» opens the mission wizard

- RED `209f77de`: 4 failing cases: «tapping «Completa» opens the mission wizard (D-25, D-28)» (the old form opened), «a card with a started draft reads «Riprendi» and opens the wizard at the served step (D-17, D-28)», «the resume after the Map opens the mission wizard (D-28)», «a failed teleport read under the wizard shows its notice once (D-28)». `pumpPanel` / `pumpQueue` now take an optional opener: with none, the panel's own default runs. The test imports `completion_exit.dart` instead of `request_completion_route.dart` / `request_completion_screen.dart`.
- GREEN `309eaa7a`: `openCompletion = openMissionCompletion`; the panel imports `completion_exit.dart` and `missionCompletion/mission_completion_route.dart`, and no longer imports `request_completion_route.dart` (the old form files are untouched until 21-17). `flutter test test/screens/innkeeper test/screens/mainScreen/components` → +552 all passed.
- **Open item from the orchestrator: double notice, reproduced and fixed.** With the wizard open, a `TeleportPreparationFailed` triggered both the panel listener (the panel stays mounted under the wizard) and the wizard listener. Two SnackBars were queued on the root messenger: the notice stayed visible about 11 s instead of about 6 s (measured second by second in the test). Fix: the panel's `_onTeleportPreparationFailed` returns when `ModalRoute.of(context)?.isCurrent == false`, so the wizard on top gives the only notice. The panel's own card-level teleport keeps its notice (existing test «a failed read shows the SnackBar and keeps the panel» is still green). Known limit: a teleport read started from the panel that fails while a dialog is open over the panel shows no notice (corner case).
- Grep checks: `openCompletion = openMissionCompletion` = 1; `request_completion_route` in the panel = 0; `D-28` in the panel test = 9.

## Task 3: Targeted regression

`flutter test test/graphql test/models test/repository test/screens/innkeeper test/screens/mainScreen test/tool` → `01:23 +3854: All tests passed!`. Analyzer: 47 info / 0 warning / 0 error (`ANALYZE_GATE_OK`) after every code commit. Full suite: plan 21-17.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Double teleport-failed notice under the wizard**
- **Found during:** Task 2 (open item flagged by the orchestrator)
- **Issue:** the panel and the wizard both showed `teleportUnavailableMessage` for one failure (two queued SnackBars).
- **Fix:** the panel listener is silent while it is not the current route.
- **Files modified:** `lib/screens/innkeeper/innkeeper_panel_screen.dart`
- **Commit:** `309eaa7a`

**2. [Rule 1 - Bug in the RED tests] Step header match and SnackBar timing**
- **Found during:** Task 2 GREEN
- **Issue:** the header text is «Passo k di 5 · <title>», so `find.text(title)` never matched. A single `pump(5 s)` + `pumpAndSettle` does not let a 4 s SnackBar leave, because `pumpAndSettle` does not advance pending timers.
- **Fix:** match `MissionStepHeader.title` with a predicate; wait 8 × 1 s before checking that no second notice is queued (a single notice is gone by about 6.75 s; a doubled one is still visible until about 11 s).
- **Files modified:** `test/screens/innkeeper/innkeeper_panel_screen_test.dart`
- **Commit:** `309eaa7a`

**3. [Boy Scout] Doc comments**: `PendingRequestFragment` names `missionDraftStartedAt`; the panel's `openCompletion` and `_complete` docs say wizard instead of form.

Other notes: the 55-document schema check was run early (Task 1, read-only, outside the repo); the formal registry and schema check remain 21-17's job.

## Known Stubs

None.

## Self-Check: PASSED

- Commits found: 121ff7f8, 8cbbcdf3, 209f77de, 309eaa7a.
- Files modified exist: the six key files above.
