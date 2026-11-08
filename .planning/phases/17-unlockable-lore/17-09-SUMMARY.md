---
phase: 17-unlockable-lore
plan: 09
subsystem: graphql
tags: [graphql, schema-gate, validation, flutter, gate]

requires:
  - phase: 17-01..17-08
    provides: "fragments, models, Library, Map written on the agreed contract names"
  - phase: BE 16 (lore sbloccabili)
    provides: "merged on BE develop as 6be50d2 (PR #25): unlockedLore, known, loreUnlocked in src/schema.gql"
provides:
  - "Contract names proven on the merged BE SDL (no alignment needed, no code change)"
  - "Schema check: 45 documents dumped, 45 x OK against origin/develop 6be50d2"
  - "Full suite 3420 green, analyzer 0 error / 0 warning / 50 info, format gate clean on the 17 new Dart files, trailers 0, sanity greps empty"
  - "17-VALIDATION.md approved: rows 17-01-01..17-09-02 green, 17-10 device rows pending"
  - "UAT handoff names for 17-10 (env variable NAMES, DB field names, DB tricks, backfill outcome)"
affects: [17-10]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/17-unlockable-lore/17-09-SUMMARY.md
  modified:
    - .planning/phases/17-unlockable-lore/17-VALIDATION.md

key-decisions:
  - "Every agreed name matches the merged SDL, so Task 1 step 1 ends with «names confirmed» and no test/fix alignment commit exists (D-13)"
  - "The checklist literal `nyquist_compliant: true` of the VALIDATION template is left as is: the frontmatter is proven by the anchored grep (count 1), the plan's unanchored grep counts 2"

requirements-completed: []

duration: ~6min
completed: 2026-11-08
---

# Phase 17 Plan 09: Schema gate against the merged BE Phase 16 Summary

**The 45 FE GraphQL documents validate 45/45 against the merged BE `origin/develop` `6be50d2`, every agreed contract name (`unlockedLore: [ID!]!`, `known: Boolean!`, `loreUnlocked: [Lore!]!`, nullable `City.relatedLore`, `Lore.type: String!`, no `knownEnemies`) is confirmed on the SDL without any code change, the full suite (3420), analyzer, format, trailer and sanity gates are green, and `17-VALIDATION.md` is approved except the 17-10 device rows.**

## Performance

- **Duration:** ~6 min (started 2026-11-08T15:38:35Z)
- **Tasks:** 2/2
- **Files modified:** 1 (`17-VALIDATION.md`) + this SUMMARY + bookkeeping (`ROADMAP.md`, `STATE.md`); 0 lib/test files
- **Code commits:** 0 (names confirmed, nothing to align)

## Task 1 — BE gate, contract proof, handoff, schema check

### Step 0 — gate (BE repo read-only, `git -C <BE> show origin/develop:src/schema.gql`)

```
GATE loreUnlocked count:
1
--- BE log origin/develop:
6be50d2 Merge pull request #25 from LucaTabbia/feat/16-lore-sbloccabili
d4d7be1 docs(phase-16): record the real boot and the backfill removal
0125058 refactor(migrations): drop the 16 one-off lore backfill after its run
80c3bf7 test(migrations): expect the real boot without the one-off lore backfill
a2c10cd docs(phase-16): record the CI fix of the backfill boot spec
```

BE ref: `origin/develop` = `6be50d2` (merge of BE PR #25). Gate ≥ 1 → the plan continues.

### Step 1 — contract proof on the merged SDL (awk blocks, verbatim)

```
### CharacterStatus
type CharacterStatus {
  activeTravel: ActiveTravel
  awaitingAid: AwaitingAid
  coins: Coins!
  currentLifePoints: Int!
  injuries: [InjuryType!]!
  level: Int!
  location: PointOfInterest!
  maxActiveSpells: Int!
  maxLifePoints: Int!
  spellStates: [SpellState!]!
  spells: [Spell!]!
  title: String!
  unlockedLore: [ID!]!
  xp: Int!
}
### QuestEnemy
type QuestEnemy {
  enemy: Enemy!
  known: Boolean!
  quantity: Int!
}
### QuestResult
type QuestResult {
  acknowledgedAt: DateTime
  ambush: AmbushReport
  character: ID!
  consumablesUsed: [AssetQuantity!]!
  enemies: [QuestEnemy!]!
  hpAfter: Int!
  hpBefore: Int!
  id: ID!
  injuriesAdded: [InjuryType!]!
  kind: QuestResultKind!
  levelAfter: Int!
  levelBefore: Int!
  loreUnlocked: [Lore!]!
  maxLifePoints: Int!
  outcome: QuestOutcome!
  quest: QuestResultQuest
  rescuedCharacters: [ID!]!
  resolvedAt: DateTime!
  rewards: QuestRewards!
  spellLearned: Spell
  spellsUsed: [SpellUsage!]!
  stagesCleared: Int
  stagesTotal: Int
  titleAfter: String!
  titleBefore: String!
  user: ID!
  xpAfter: Int!
  xpBefore: Int!
  xpGained: Int!
}
### City
type City {
  area: [[Float!]!]!
  hasShop: Boolean!
  id: ID!
  markerLocation: PointOfInterest!
  name: String!
  pointsOfInterest: [PointOfInterest!]
  relatedLore: Lore
  size: CitySize!
  type: CityType!
}
### Lore
type Lore {
  description: String!
  id: ID!
  image: String
  name: String!
  relatedLore: [Lore!]!
  type: String!
}
### knownEnemies count:
0
```

Comparison with the FE names (17-01..17-03):

| Agreed name | Merged SDL | FE document | Verdict |
|-------------|------------|-------------|---------|
| `CharacterStatus.unlockedLore: [ID!]!` | present | `CharacterFragment.statusFields` `… spellStates { … } unlockedLore` | confirmed |
| `QuestEnemy` = `enemy`, `known: Boolean!`, `quantity` | exactly those three | `QuestFragment` / `QuestResultFragment` `enemies { quantity known enemy { id name imagePath xp } }` | confirmed |
| `QuestResult.loreUnlocked: [Lore!]!` | present | `QuestResultFragment` `spellLearned { id name } loreUnlocked { id name type }` | confirmed |
| `City.relatedLore: Lore` (nullable) | `relatedLore: Lore` (no `!`) | `CityQueries.getAllCities` `relatedLore { id description image }` unchanged | confirmed |
| `Lore` fields `description id image name relatedLore type`, `type: String!` | identical | `LoreQueries` unchanged (no `unlocked*`) | confirmed |
| `knownEnemies` never on the wire (D-01) | count 0 | not selected anywhere (`grep -rn knownEnemies lib test` empty) | confirmed |

**Names confirmed — no code commit.** No `test(graphql): expect the merged …` / `fix(graphql): align …` pair was needed, so the `<behavior>` of Task 1 (RED only if a name differs) never applied.

Informational, outside this phase's contract: the merged `QuestResult` also carries `ambush: AmbushReport` and `kind: QuestResultKind!` (BE Phase 15, consumed by the parked FE Phase 16 branch); this branch does not select them and they do not affect validation (additive).

### Step 2 — schema check (cross-repo, `NODE_PATH=<BE>/node_modules`, scratch outside the repo)

```
dumped 45 documents
```

`validate_documents.js` output: 45 lines, all `OK` (`AbandonQuest`, `AcceptQuest`, `AcknowledgeQuestResult`, `CompletePendingRequest`, `CreateCharacter`, `DeleteCharacter`, `EquipPet`, `EquipSpell`, `ExchangeLoginTicket`, `GenerateQuests`, `GetCity`, `GetCityShop`, `GetMe`, `GetPendingRequests`, `GetQuestResult`, `GetQuestTravelPreview`, `GetRaceTraits`, `GetServerTime`, `GetTravelPreview`, `ListUnacknowledgedQuestResults`, `Logout`, `OnPendingRequestsUpdated`, `OnQuestResultReceived`, `OnQuestUpdated`, `OnUserChanged`, `RefreshSession`, `RegisterPushDevice`, `StartTravel`, `TeleportCharacter`, `UnequipPet`, `UnequipSpell`, `UnregisterPushDevice`, `character`, `characterUpdated`, `cities`, `doTransaction`, `equipItem`, `equipment`, `equipmentItems`, `equipmentItemsByIds`, `lootItems`, `lootItemsByIds`, `lore`, `lores`, `quests`).

```
--- OK count:
45
--- grep -vc OK:
0
```

### Step 3 — BE Phase 16 handoff (`origin/develop:.planning/phases/16-lore-sbloccabili/BACKEND-NOTES.md`), names only for 17-10

Section titles of the UAT part: `## 3. Identità di prova per la UAT`, `## 4. Trucchi a DB per la UAT` (items (a)–(g) with a cases table), `## 5. Boot reale col backfill e rimozione` (`### Esito del boot reale`), `## 6. Deploy`, `## 7. Deviazioni e punti aperti` («Osservazioni per la FE e la UAT» (a)–(d)).

- **Player identity (§3)** — environment variables of the BE *process* (never the `.env` file), names only: `DEV_AUTH_ROLE=adventurer`, `DEV_AUTH_TWITCH_ID` (the twitchId of the owner of the test character), `DEV_AUTH_ENABLED` and `DEV_AUTH_ACCESS_TOKEN` as in the existing dev configuration. The dev bypass with `DEV_AUTH_ROLE=innkeeper` sees everything (every enemy `known: true`, every lore and city visible) and proves nothing of Phase 17. With the player identity `teleportCharacter` answers `FORBIDDEN`: arrivals go through a real travel with `status.activeTravel.endTime` moved into the past (the sweep completes it), or a temporary innkeeper restart only for the teleport.
- **Study roll (§3/§4 b)** — `LORE_STUDY_CHANCE=1` on the same BE process makes every won `study` without a spell teach one lore; default 0.5.
- **DB tricks (§4, field names only):** (a) empty the knowledge: `status.unlockedLore` and `status.knownEnemies` set to `[]` on the character (Library empties live, portraits turn to silhouettes at the next read); (c) arrival: moving `status.location` at DB unlocks nothing (not an arrival) — use the GM teleport (innkeeper bearer) or a real travel to the city marker with `status.activeTravel.endTime` in the past; (d) unknown city on the Map: `$pull` the city lore id from `status.unlockedLore` → `City.relatedLore` back to `null`; (e) darkened portrait: `$pull` the enemy id from `status.knownEnemies`; (g) checks at DB: `characters.status.unlockedLore` / `status.knownEnemies`, `questresults.loreUnlocked` of the last result; GraphQL probe with the player bearer `{ lores { id name type } cities { id name relatedLore { id } } }`.
- **Backfill outcome (§5, counts only):** first boot `Backfill delle lore: personaggi 3, aggiornati 2, lore aggiunte 8, nemici aggiunti 1, senza città 1`; second boot `personaggi 3, aggiornati 0, lore aggiunte 0, nemici aggiunti 0, senza città 1` (idempotent); the one-off was removed in TDD (`80c3bf7` → `0125058`) and the BE now runs the final build on port 3001 without the backfill module. The existing characters received their knowledge without a sheet: at the first opening of a book the FE has no baseline and marks nothing (D-07), as expected.
- **Observations for the UAT (§7):** an arrival that teaches emits TWO `characterUpdated` (movement, then geography) — the FE compares sets and refetches once per change; geography has no sheet (the «Nuovo» bookmark is the only signal); board staleness accepted (`known` resolved per read).

No id, token or URI copied from the handoff.

### Step 4 — tests

`flutter test test/graphql test/tool test/models test/repository` → `00:33 +1561: All tests passed!`

## Task 2 — full gates and the completed validation strategy

1. Full suite (foreground): `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'` → `01:20 +3420: All tests passed!` (baseline at 17-08: 3420; no new test in this plan).
2. Analyzer gate:
   ```
   50 issues found. (ran in 3.9s)
   ANALYZE_GATE_OK
   error/warning count: 0
   ```
3. Format gate on the 17 new Dart files of `develop...HEAD` (`lib/models/enums/library_book.dart`, `lib/repository/storage/library_bookmarks_store.dart`, `lib/screens/mainScreen/tabs/library/components/library_book_art.dart`, `lib/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart`, `lib/screens/mainScreen/tabs/map/components/unknown_city_modal.dart`, `test/helpers/fakes/in_memory_library_bookmarks_store.dart`, `test/helpers/fixtures/lore_fixtures.dart`, `test/models/enums/library_book_test.dart`, `test/models/enums/lore_type_test.dart`, `test/repository/storage/library_bookmarks_store_test.dart`, `test/screens/mainScreen/cubit/main_screen_cubit_test.dart`, `test/screens/mainScreen/tabs/library/components/lore_card_test.dart`, `test/screens/mainScreen/tabs/library/cubit/library_cubit_test.dart`, `test/screens/mainScreen/tabs/library/library_data_page_test.dart`, `test/screens/mainScreen/tabs/library/library_error_page_test.dart`, `test/screens/mainScreen/tabs/library/library_test.dart`, `test/screens/mainScreen/tabs/map/components/unknown_city_modal_test.dart`): no `UNFORMATTED` line.
4. Trailers: `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` → `0` (`develop` = `f560d1d`).
5. Sanity greps (each printed nothing):
   ```
   [1] grep -rn "package:flutter/" lib/models                                  → (empty)
   [2] grep -rn "unlocked" lib/graphql/queries/lore_queries.dart               → (empty)
   [3] grep -rn "knownEnemies" lib test                                        → (empty)
   [4] grep -rn "relatedLore!" lib/screens/mainScreen/tabs/map                 → (empty)
   [5] grep -rnF ".stream.listen" lib/screens/mainScreen/tabs/library lib/screens/mainScreen/cubit → (empty)
   [6] grep -rn "Placeholder()" lib/screens/mainScreen/tabs/library/library.dart → (empty)
   [7] grep -rn "outcome" lib/shared/components/enemy_portrait.dart            → (empty)
   [8] git diff develop --stat -- lib/graphql/queries/lore_queries.dart lib/graphql/queries/city_queries.dart tool/schema_check/schema_check_documents.dart lib/shared/components/dropdown.dart lib/shared/components/cached_svg.dart → (empty)
   [9] grep -c "LibraryLoading()" lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart → 1
   ```
6. `17-VALIDATION.md`: rows `17-09-01` and `17-09-02` → `✅ green` (rows 17-01-01..17-08-02 were already green; `grep -cE "^\| 17-0[1-9]-0[1-2] .*✅ green"` = 18); rows `17-10-01..03` stay `⬜ pending`; Wave 0 Requirements already all `[x]`; frontmatter `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true` (`grep -c "wave_0_complete: true"` = 1; `grep -c "^nyquist_compliant: true"` = 1); sign-off checklist ticked; approval line and «Gate passed on BE `6be50d2`: 45/45 OK, full suite 3420 green, analyzer 50 info (0 error / 0 warning); …» added. Commit `256218b`.

## Task Commits

1. **Task 1** — no commit (gate passed, names confirmed, nothing to align).
2. **Task 2** — `256218b` docs(phase-17): validate the lore documents and gates
3. **Bookkeeping** — `docs(phase-17): record plan 09 progress` (this SUMMARY, `ROADMAP.md` 9/10 + `[x] 17-09-PLAN.md`, `STATE.md` `Plan: 9 of 10`)

## Deviations from Plan

### Code

None — no lib/test file was touched; the plan's conditional alignment path was not needed.

### Acceptance discrepancies (noted, not fixed)

1. `grep -c "nyquist_compliant: true" 17-VALIDATION.md` prints **2**, the plan expects 1: the sign-off checklist of the VALIDATION template already carried the literal «`nyquist_compliant: true` set in frontmatter» at planning time, so with the frontmatter flipped the unanchored count is 2 (REPO-RULES «skeleton literal» trap, same class as the 17-03 note). The anchored `grep -c "^nyquist_compliant: true"` = 1 proves the frontmatter; the template line was not reworded to satisfy the grep.
2. Bookkeeping uses the orchestrator's `9/10` / `Plan: 9 of 10` instead of the plan's `09/10` / `09 of 10` (REPO-RULES: the orchestrator's k/N wins).

## Shared result files with the parked FE Phase 16 (CONTEXT D-18)

Not touched by this plan (no code change).

## D-14 / Pitfall 9

The BE on port 3001 now runs the merged Phase 16 code (`6be50d2` build): the branch's documents validate against it (45/45). Nothing in this plan talked to that process; the device run is 17-10 with the player identity (§3 names above).

## Known Stubs

None.

## Threat Flags

None. T-17-25 (read-only `show`/`log`/`ls-tree` on `origin/develop`, no fetch/checkout), T-17-26 (no `.env` read, `NODE_PATH` to `node_modules` only, scratch outside the repo, names only from the handoff), T-17-27 (45/45 OK before the device run) and T-17-28 (sanity greps empty) mitigated as planned.

## Self-Check: PASSED

- `17-VALIDATION.md` carries `wave_0_complete: true`, `status: approved`, 18 green rows and 3 pending device rows; commit `256218b` in `git log`.
