---
phase: 13-city-shops
plan: 10
subsystem: graphql
tags: [schema-gate, cross-repo, validation, cityShop, pets, tdd]
requires:
  - phase: 13-01..13-09
    provides: models, documents, classifiers, shop call, companion cubit and Journal slot written on the agreed names
  - phase: BE 12 (negozi per città)
    provides: merged SDL on BE `develop` `0585b2e` (PR #18) with `cityShop`, `CitySize`, `City.size`/`hasShop`, `ownedPets`, `petAssets`, `equipPet`/`unequipPet`
provides:
  - contract proof of every agreed name on the merged BE SDL (A1/A2/A3 confirmed, no alignment needed)
  - schema check 43/43 OK against the merged BE
  - full-suite, analyzer, format and trailer gates green on `feat/13-city-shops`
  - completed `13-VALIDATION.md` (rows 13-10-01/02 green, 13-11-01..03 pending, Wave 0 and manual-only sections, nyquist/wave-0 flags)
affects: [13-11]
tech-stack:
  added: []
  patterns:
    - "schema gate on `origin/develop:src/schema.gql` of the BE (fetch + show only), documents dumped and validated with the BE graphql-js (pattern 08-12 / 09-12 / 10-11)"
key-files:
  created:
    - .planning/phases/13-city-shops/13-10-SUMMARY.md
  modified:
    - .planning/phases/13-city-shops/13-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "A1/A2/A3 confirmed on the merged SDL: no document or model changed, no code commit in this plan"
  - "the VALIDATION sign-off line names the nyquist flag without repeating the frontmatter literal so the acceptance grep counts exactly 1"
patterns-established: []
requirements-completed: []  # SHOP-02, SHOP-03, SHOP-04 are marked complete only by 13-11 after the device E2E (plan rule)
duration: ~9min
completed: 2026-11-03
---

# Phase 13 Plan 10: Schema gate Summary

**Every agreed name of the BE Phase 12 contract is proven on the merged BE `develop` (`0585b2e`, PR #18): A1 `EquipPetRequest`/`UnequipPetRequest`, A2 `CitySize { capital city village }`, A3 `cityShop(cityId: ID!)`, the three error codes; the 43 FE documents validate 43 × OK, the full suite is 3027 green, the analyzer 50 info / 0 error / 0 warning, format and trailer gates clean; `13-VALIDATION.md` is complete except the device rows of 13-11.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-11-03T17:22:32Z
- **Completed:** 2026-11-03T17:31Z
- **Tasks:** 2
- **Files modified:** 3 (`13-VALIDATION.md`, `ROADMAP.md`, `STATE.md`) + this SUMMARY; no Dart file touched

## Accomplishments

- The gate passed (`grep -c cityShop` = 3 on `origin/develop:src/schema.gql`): the phase is NOT parked; 13-11 can run.
- Contract proof pasted below: no difference between the FE documents/models of 13-01/13-02 and the merged SDL, so no alignment, no RED/GREEN cycle, no code commit (plan: «If nothing differs, record "A1/A2/A3 confirmed" and make no code commit»).
- Schema check: `dumped 43 documents`, 43 × `OK`, `grep -vc OK` = 0.
- Gates: full `flutter test` 3027 passed (baseline 2862 + 165 tests of the phase) in 77 s; `flutter analyze` `50 issues found` → `ANALYZE_GATE_OK`; 36 new Dart files format-clean; trailer count 0 over the 72 commits of the branch; six sanity greps empty / `0`.

## Task Commits

1. **Task 1: BE gate, contract proof, schema check** — no commit (nothing to align; outputs recorded here)
2. **Task 2: Full gates and the completed validation strategy** — `62842a7` (docs: validate the city shop documents and gates), `87d6344` (docs: keep the nyquist flag literal unique in the validation)

**Plan metadata:** `docs(phase-13): record plan 10 progress` (SUMMARY, ROADMAP, STATE)

## Task 1 — Gate and contract proof (BE read-only: `fetch -q origin develop`, `show`, `log`, `ls-tree`)

BE ref (`git -C $BE log --oneline -5 origin/develop`):

```
0585b2e Merge pull request #18 from LucaTabbia/feat/12-negozi-per-citta
b4ccfe3 docs(phase-12): record the one-off seed run and the removed maintenance
40106db refactor(shops): call a city without a pool by its name in the report
a3fd8ac refactor(shops): drop the migrators and the seeder after their one-off run
0b67c65 test(shops): curate the e2e world by hand instead of seeding it
```

Gate: `grep -c "cityShop" "$SCRATCH/schema.gql"` → `3` (≥ 1, continue).

```
--- type CityShop ---
type CityShop {
  city: City!
  equipment: [AssetQuantity!]!
  loot: [AssetQuantity!]!
  pets: [Pet!]!
}
--- enum CitySize (A2) ---
enum CitySize {
  capital
  city
  village
}
--- type City | grep size|hasShop ---
3:  hasShop: Boolean!
9:  size: CitySize!
--- type CharacterAssets | grep ownedPets ---
5:  ownedPets: [Pet!]!
--- input TransactionItems | grep petAssets ---
4:  petAssets: [AssetQuantityInput!]
--- type Pet | grep sellable|speedModifier ---
11:  sellable: Boolean
12:  speedModifier: Float
--- grep -n equipPet|unequipPet ---
357:  equipPet(request: EquipPetRequest!): CommonResponse!
366:  unequipPet(request: UnequipPetRequest!): CommonResponse!
773:input UnequipPetRequest {
--- awk input .*Pet.* (A1) ---
input EquipPetRequest {
  id: String!
  petId: String!
}
input UnequipPetRequest {
  id: String!
}
--- grep -n "cityShop(" (A3) ---
511:  cityShop(cityId: ID!): CityShop!
```

Error codes (`git -C $BE show origin/develop:src/gameRules/game-rule-error-code.enum.ts | grep -n …`, 3 lines):

```
32:    ITEM_NOT_IN_SHOP = 'ITEM_NOT_IN_SHOP',
33:    PET_ALREADY_OWNED = 'PET_ALREADY_OWNED',
34:    PET_NOT_OWNED = 'PET_NOT_OWNED',
```

BE Phase 12 handoff path on `origin/develop`: `.planning/phases/12-negozi-per-citta/BACKEND-NOTES.md`.

Comparison with the FE names (13-01/13-02):

| Assumption | FE today | Merged SDL | Result |
|---|---|---|---|
| A1 input types | `$request: EquipPetRequest!` / `$request: UnequipPetRequest!`; `EquipPetRequest { id, petId }`, `UnequipPetRequest { id }` | `input EquipPetRequest { id: String! petId: String! }`, `input UnequipPetRequest { id: String! }`, both return `CommonResponse!` | confirmed |
| A2 `CitySize` values | `CitySizeType { capital, city, village }` parsed with `asNameMap()` | `enum CitySize { capital city village }` | confirmed |
| A3 `cityShop` argument | `query GetCityShop($cityId: ID!) { cityShop(cityId: $cityId) … }` | `cityShop(cityId: ID!): CityShop!` | confirmed |
| `CityShop` fields | `city { id } equipment loot pets` | `city equipment loot pets` | confirmed |
| `City.size` / `hasShop` | selected by `cities` | `size: CitySize!`, `hasShop: Boolean!` | confirmed |
| `CharacterAssets.ownedPets` | selected by the character fragment | `ownedPets: [Pet!]!` | confirmed |
| `TransactionItems.petAssets` | `toJson` key `petAssets` | `petAssets: [AssetQuantityInput!]` | confirmed |
| `Pet.sellable` / `speedModifier` | `PetFragment.fields` | `sellable: Boolean`, `speedModifier: Float` | confirmed |
| error codes | `ITEM_NOT_IN_SHOP`, `PET_ALREADY_OWNED`, `PET_NOT_OWNED` | identical | confirmed |

**A1/A2/A3 confirmed — no alignment, no code commit.**

Schema check:

```
$ dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"
dumped 43 documents
$ NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"
OK AbandonQuest.graphql … OK quests.graphql   (43 lines, exit 0)
  OK count (grep -c "^OK"): 43
  non-OK count (grep -vc OK): 0
```

The 43 documents: AbandonQuest, AcceptQuest, AcknowledgeQuestResult, CompletePendingRequest, CreateCharacter, DeleteCharacter, EquipPet, EquipSpell, ExchangeLoginTicket, GetCity, GetCityShop, GetMe, GetPendingRequests, GetQuestResult, GetRaceTraits, GetServerTime, GetTravelPreview, ListUnacknowledgedQuestResults, Logout, OnPendingRequestsUpdated, OnQuestResultReceived, OnQuestUpdated, OnUserChanged, RefreshSession, RegisterPushDevice, StartTravel, TeleportCharacter, UnequipPet, UnequipSpell, UnregisterPushDevice, character, characterUpdated, cities, doTransaction, equipItem, equipment, equipmentItems, equipmentItemsByIds, lootItems, lootItemsByIds, lore, lores, quests.

Task 1 verify: `flutter test test/graphql test/tool test/models` → `00:15 +643: All tests passed!`.

## Task 2 — Gates

- Full suite (alone, foreground): `flutter test` → `01:14 +3027: All tests passed!`, exit 0, 77 s, 0 failure markers (baseline 2862 before the phase → +165).
- Analyzer gate: last line `50 issues found. (ran in 3.9s)`; errors/warnings 0 → `ANALYZE_GATE_OK` (≤ 50 as expected after the `avoid_print` removal of 13-05).
- Format gate: `dart format --output=none --set-exit-if-changed` on the 36 new Dart files of the branch (`git diff --name-only --diff-filter=A develop...HEAD -- lib test tool`) → no `UNFORMATTED` line.
- Trailers: `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` → `0` (72 commits before this plan; re-checked after each commit of this plan → 0).
- Sanity greps (all empty / `0`):
  - `grep -rn "AssetsQuantity" lib tool` → (nothing)
  - `grep -rli "cavalcatura" lib` → (nothing)
  - `grep -rn "package:flutter/" lib/models lib/screens/mainScreen/tabs/shop/shopCubit lib/screens/mainScreen/tabs/journal/companionCubit` → (nothing)
  - `grep -rn "print(" lib/screens/mainScreen/tabs/shop` → (nothing)
  - `grep -c "imagePath" lib/graphql/fragments/pet_fragment.dart` → `0`
  - `grep -rn "CompanionCubit\|equipPet" lib/screens/mainScreen/tabs/shop` → (nothing)
- `13-VALIDATION.md`: `grep -c "nyquist_compliant: true"` = 1, `grep -c "wave_0_complete: true"` = 1, `grep -c "^| 13-[01][0-9]-0[1-3] "` = 25 (20 rows of 13-01..13-09 + 13-10-01/02 + 13-11-01/02/03). Estimated runtime updated to ~77 s / 3027 tests; the schema-gate outputs are recorded under the map; Wave 0 lists the 22 new test files, the fixtures/fakes and the harness/mock/provider updates, all `[x]`; manual-only rows: device E2E (11 steps of 13-11), optional `ITEM_NOT_IN_SHOP` via DB curation, equip/unequip during a travel; sign-off boxes ticked; `status: draft` and approval pending until 13-11.

## Files Created/Modified

- `.planning/phases/13-city-shops/13-VALIDATION.md` — completed validation strategy (single writer of the 13-10 and 13-11 rows).
- `.planning/ROADMAP.md` — `- [x] 13-10-PLAN.md`; Progress Table `| 13. City Shops | 10/11 | In Progress | - |`.
- `.planning/STATE.md` — `Plan: 10 of 11`, `last_updated` (real UTC), the parked wording of Phase/Status/Next Phase/Last activity replaced by the 10/11 position (see Deviations).

## Decisions Made

- No alignment needed: the names assumed in CONTEXT D-16 / research A1–A3 are exactly the merged ones; the documents of 13-02 become real against the BE without a change.
- `requirements mark-complete` not run (forbidden here; 13-11 marks SHOP-02/03/04 after the device E2E).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] VALIDATION sign-off line repeated the frontmatter literal**
- **Found during:** Task 2 (acceptance grep `grep -c "nyquist_compliant: true"` printed 2 after the first commit, the criterion wants 1: the template's sign-off line «`nyquist_compliant: true` set in frontmatter» matches too)
- **Fix:** the sign-off line now reads «frontmatter flag `nyquist_compliant` set to true»; count = 1
- **Files modified:** `.planning/phases/13-city-shops/13-VALIDATION.md`
- **Committed in:** `87d6344` (separate commit: no amend allowed)

**2. [Boy Scout] STATE position lines updated beyond `Plan:`**
- **Found during:** bookkeeping — `Phase:`, `Status:`, `Next Phase:`, `Last activity:` and `last_activity` still described the phase as «PARKED at 9/11 awaiting the BE Phase 12 merge», false once the gate passed
- **Fix:** wording replaced with the 10/11 position (BE `0585b2e`, gate green, 13-11 next); the review-fix notes for the device UAT in `Status:` are untouched
- **Files modified:** `.planning/STATE.md` (Edit tool + python3 UTF-8 for `last_updated`)

---

**Total deviations:** 2 (1 auto-fix of a gate literal, 1 bookkeeping wording). No Dart file touched, no scope creep.

## Issues Encountered

- `flutter test` writes its progress with carriage returns on one line: `tail -3` captured the whole run (255 KB). The full suite was redirected to a scratchpad file and read back with `tr '\r' '\n'`; the counts above come from that file.

## User Setup Required

None. The user is running the device UAT against the local BE; this plan did not touch the BE process, `adb`, `flutter run` or the device.

## Known Stubs

None — this plan changed no Dart file.

## Threat Flags

None. T-13-32 (BE working tree): only `fetch -q` / `show` / `log` / `ls-tree` on `origin/develop`. T-13-33: no `.env*` read, `NODE_PATH` pointed at `node_modules` only, scratch in `mktemp -d` and the session scratchpad. T-13-34: 43/43 OK before any device run. T-13-35: the sanity greps confirm no `print` in the shop and the classifiers read codes only.

## Next Step

13-11: re-check the gate, write `13-HUMAN-UAT.md` (11 steps), device E2E with the user, handoff `BACKEND-NOTES.md`, `requirements mark-complete SHOP-02 SHOP-03 SHOP-04`, ROADMAP/STATE closure.

## Self-Check: PASSED

- `13-VALIDATION.md`, `13-10-SUMMARY.md` exist; commits `62842a7`, `87d6344` are in `git log`.
