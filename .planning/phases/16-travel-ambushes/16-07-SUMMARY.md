---
phase: 16-travel-ambushes
plan: 07
subsystem: graphql
tags: [flutter, dart, graphql, schema-gate, ambush, push, validation]

requires:
  - phase: 16-01
    provides: QuestResultFragment kind/ambush selection, QuestResult.kind/ambush with a nullable quest (the names the gate proves)
  - phase: 16-02
    provides: NotificationCategory.ambushDefeat('ambush_defeat', 'ambushDefeat') (the wire type the gate proves)
  - phase: 16-06
    provides: last executed plan before the park; reroute proof and D-07/D-17 pins
provides:
  - Contract proof of every agreed name on the merged BE SDL (BE develop 9103440, BE PR #24)
  - Schema check 45/45 OK against the merged SDL (dump + validate)
  - ambushDefeat push payload confirmed in the BE Phase 15 handoff (type, id, title, body, sentAt)
  - UAT seed field names for 16-08 (no ids, no secrets)
  - 16-VALIDATION.md completed except the 16-08 device rows (wave_0_complete: true, status: approved)
affects: [16-08]

tech-stack:
  added: []
  patterns:
    - "Schema gate after the BE companion merge (pattern 13-10 / 14-10 / 15-08): awk blocks on the SDL, dump + validate every registered document, full suite, analyzer, format, trailer and sanity greps"

key-files:
  created:
    - .planning/phases/16-travel-ambushes/16-07-SUMMARY.md
  modified:
    - .planning/phases/16-travel-ambushes/16-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "Names confirmed on the merged SDL: no fragment, model or category change was needed, so Task 1 produced no code commit (plan step 1: «If nothing differs, record names confirmed and make no code commit»)"
  - "The BE ref was read from the local origin/develop (9103440) without a fetch: the SSH agent is dead in this session and the orchestrator had already aligned the ref over HTTPS (plan allows it)"

requirements-completed: []

duration: 8min
completed: 2026-11-07
---

# Phase 16 Plan 07: Schema gate on the merged BE Phase 15 Summary

**Every agreed contract name (`QuestResultKind`, `QuestResult.kind`, nullable `quest`, `ambush: AmbushReport`, `AmbushCity`, `PushEventType.ambushDefeat`, unchanged `ActiveTravel`) is proven on the merged BE SDL `9103440`, the 45 registered documents validate 45/45 OK, the `ambushDefeat` payload carries `sentAt`, and every code gate (full suite +3391, analyzer 0/0/50, format, trailers, sanity greps) is green; no code change was needed.**

## Performance

- Duration: ~8 min
- Completed: 2026-11-07
- Tasks: 2 (1 docs commit for Task 2; Task 1 confirmed the names and committed nothing, as the plan prescribes)
- Files: 1 created (this SUMMARY), 3 modified (VALIDATION, ROADMAP, STATE)

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | BE gate, contract proof on the merged SDL and handoff, alignment test-first, schema check 45/45 | — (names confirmed, no code commit) | none |
| 2 | Full gates and the completed validation strategy | c22517e | 16-VALIDATION.md |

## 1. BE gate (Task 1 step 0)

- BE repo `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`, checked out on `develop`, `HEAD` = `origin/develop` = **`9103440`**.
- **`git -C <BE> fetch` was NOT run**: the SSH agent is dead in this session (the orchestrator confirmed `origin/develop` aligned to `9103440` over HTTPS and the GitHub API). The local `origin/develop` ref was used, as the plan allows.
- `git -C <BE> show origin/develop:src/schema.gql > $SCRATCH/schema.gql` (scratchpad, not the repo); `diff -q` against `<BE>/src/schema.gql` → IDENTICAL.
- Gate: `grep -c "AmbushReport" $SCRATCH/schema.gql` → **2** (≥ 1, continue).
- `git -C <BE> log --oneline -5 origin/develop`:

```
9103440 Merge pull request #24 from LucaTabbia/feat/15-imboscate-in-viaggio
bf1a899 docs(state): record the phase 15 PR number
f2bcf6c docs(phase-15): complete phase execution
d124737 docs(phase-15): record the security audit
3b37dfd docs(phase-15): record the review fixes
```

## 2. Contract proof on the merged SDL (Task 1 step 1)

`awk '/^type QuestResult /,/^}/'`:

```graphql
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
```

`awk '/^enum QuestResultKind /,/^}/'`:

```graphql
enum QuestResultKind {
  ambush
  quest
}
```

`awk '/^type AmbushReport /,/^}/'`:

```graphql
type AmbushReport {
  at: DateTime!
  nearCity: AmbushCity!
  reachedCity: AmbushCity
}
```

`awk '/^type AmbushCity /,/^}/'`:

```graphql
type AmbushCity {
  id: ID!
  name: String!
}
```

`awk '/^enum PushEventType /,/^}/'`:

```graphql
enum PushEventType {
  ambushDefeat
  questCancelled
  questEnd
  streamerLive
  travelEnd
}
```

`awk '/^type ActiveTravel /,/^}/'`:

```graphql
type ActiveTravel {
  duration: Float!
  endTime: DateTime!
  road: TravelPath!
  startTime: DateTime!
  to: ID!
}
```

Comparison with the FE names (16-01 / 16-02):

| Agreed name | Merged SDL | FE | Verdict |
|-------------|------------|----|---------|
| `QuestResult.kind: QuestResultKind!` | present, non-null | `QuestResultFragment` selects `kind` after `outcome`; `QuestResult.kind` via `QuestResultKind.fromWire` | confirmed |
| `QuestResult.quest: QuestResultQuest` nullable | `quest: QuestResultQuest` (no `!`) | `QuestResultQuest? quest`, null when `isAmbush` | confirmed |
| `QuestResult.ambush: AmbushReport` nullable | `ambush: AmbushReport` | `AmbushReport? ambush`, parsed only when `kind == ambush` | confirmed |
| `enum QuestResultKind { quest ambush }` | `{ ambush quest }` (alphabetical SDL order) | `fromWire` matches by name, order irrelevant | confirmed |
| `AmbushReport { at: DateTime! nearCity: AmbushCity! reachedCity: AmbushCity }` | identical | `AmbushReport {at, nearCity, reachedCity?}` | confirmed |
| `AmbushCity { id: ID! name: String! }` | identical | `AmbushCity {id, name}` | confirmed |
| `PushEventType` contains `ambushDefeat` | first (alphabetical) value | `NotificationCategory.ambushDefeat('ambush_defeat', 'ambushDefeat')` | confirmed |
| `ActiveTravel` exactly `duration endTime road startTime to` | exactly those five | `ActiveTravel.tryFromJson` untouched by the phase | confirmed |

**Names confirmed — no RED test, no fix commit, no code change.**

## 3. `ambushDefeat` payload (BE handoff, Task 1 step 1)

Source: `git -C <BE> ls-tree -r --name-only origin/develop .planning/phases | grep -i "15-.*BACKEND-NOTES"` → `.planning/phases/15-imboscate-in-viaggio/BACKEND-NOTES.md` (309 lines), §2 «Push di sconfitta» (builder `ambushDefeat(characterId, cityName)` in `src/push/push-events.ts`, data-only):

```json
{
  "type": "ambushDefeat",
  "id": "<characterId>",
  "title": "Imboscata!",
  "body": "Sei stato sconfitto: la via torna verso <città>",
  "ttlSeconds": 3600,
  "sentAt": "<ISO>"
}
```

- `sentAt` is added by `PushService.sendToUser` → `PushEvent.tryParse` keeps the event (`push_event.dart` requires a parseable `sentAt`, a non-empty `title` and `body` and a known `type`); `ttlSeconds` is an extra key the FE ignores, like for every other category.
- Personal (`id` = character id, like `travelEnd`); `title`/`body` composed by the BE; `<città>` = `reachedCity.name`; sent after the commit on every defeat (also when the nearest city is the destination), never on a victory; no `questEnd` for the reports; `travelEnd` as today at the end of the detour.

## 4. Schema check (Task 1 step 2)

`dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"` → **`dumped 45 documents`** (45 `.graphql` files).

`NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"` (exit 0):

```
OK AbandonQuest.graphql
OK AcceptQuest.graphql
OK AcknowledgeQuestResult.graphql
OK CompletePendingRequest.graphql
OK CreateCharacter.graphql
OK DeleteCharacter.graphql
OK EquipPet.graphql
OK EquipSpell.graphql
OK ExchangeLoginTicket.graphql
OK GenerateQuests.graphql
OK GetCity.graphql
OK GetCityShop.graphql
OK GetMe.graphql
OK GetPendingRequests.graphql
OK GetQuestResult.graphql
OK GetQuestTravelPreview.graphql
OK GetRaceTraits.graphql
OK GetServerTime.graphql
OK GetTravelPreview.graphql
OK ListUnacknowledgedQuestResults.graphql
OK Logout.graphql
OK OnPendingRequestsUpdated.graphql
OK OnQuestResultReceived.graphql
OK OnQuestUpdated.graphql
OK OnUserChanged.graphql
OK RefreshSession.graphql
OK RegisterPushDevice.graphql
OK StartTravel.graphql
OK TeleportCharacter.graphql
OK UnequipPet.graphql
OK UnequipSpell.graphql
OK UnregisterPushDevice.graphql
OK character.graphql
OK characterUpdated.graphql
OK cities.graphql
OK doTransaction.graphql
OK equipItem.graphql
OK equipment.graphql
OK equipmentItems.graphql
OK equipmentItemsByIds.graphql
OK lootItems.graphql
OK lootItemsByIds.graphql
OK lore.graphql
OK lores.graphql
OK quests.graphql
```

`| grep -c '^OK '` → **45**; `| grep -vc OK` → **0**. The four `QuestResultFragment` documents (`OnQuestResultReceived`, `GetQuestResult`, `ListUnacknowledgedQuestResults`, `CompletePendingRequest`) validate with `kind` and `ambush { at nearCity { id name } reachedCity { id name } }` against the merged schema (Pitfall 7 / D-15 closed for a BE at `9103440`).

## 5. UAT seed facts for 16-08 (BE handoff §3–§7, field names only)

- **Internal pending ambush** (never on the wire): `status.activeTravel.ambush = { at: <past instant>, km: <integer>, attempts: 0 }`, seeded **whole** on a real in-progress travel of **≥ 10 km**, with `1 ≤ km < road.distance` and `startTime ≤ at ≤ now`. The ambush **point** derives from `km / distance` (planar fraction of the polyline, same algorithm as `TravelRoute.pointAt`), not from `at`: pick `km` for the wanted position.
- **Trigger:** Bull job `ambush` on the `travel` queue (jobId `ambush-<characterId>-<startTimeMs>-<atMs>`) is only the trigger; the **reconciler at boot and the sweep every `TRAVEL_SWEEP_INTERVAL_MS` (default 60 000 ms)** resolve every ambush with `at ≤ now` → a seeded ambush resolves within ≤ 60 s. Moving `startTime`/`endTime` by hand orphans the Bull jobs, but the sweeps by `ambush.at` and `endTime` still resolve (wait ≤ one interval). Travel completion waits for a pending ambush (the completion filter requires no pending ambush).
- **Forced defeat:** the placeholder resolver wins with `power / (power + enemies' HP)`; character HP do not count. Remove the worn equipment (`assets.wearedEquipment`, every piece with `damages`) and the active spells (`assets.activeSpells`) → power 0 → certain defeat. Low `status.currentLifePoints` makes the HP bar visible (HP never below 1). A victory is never guaranteed: keep weapons and spells and repeat if needed.
- **Two ambushes (carousel):** after the first resolution (victory: travel unchanged, possible redraw that can be cancelled), a second seed with a larger `km` and a later `at` (still in the past); or, equivalently, two reports already in `status.activeTravel.ambushReports[]` with the travel `endTime` in the past → at the arrival they become two `QuestResult` and two pages.
- **Closing a travel with held reports:** the reports are held in an internal travel field until the arrival (completion sweep by `endTime`, coherent `startTime`/`endTime`) or the GM **teleport** (`teleportCharacter`, transactional: cancels the pending ambush and delivers the held reports; still refused with `QUEST_IN_PROGRESS` while the standard lane is occupied — after a defeat the lane is free).
- **After a defeat (DB):** `characters.status.activeTravel` has `startTime = at`, `to` = the city marker, no `ambush`, `quests.pendingQuest = null`; `kind: free`, so the arrival sends `travelEnd`. After a victory: same `startTime`/`endTime`, possibly a new `ambush`.
- **Delivered reports (DB `questresults`):** `kind: 'ambush'`, `quest: null`, `ambush.at` = seeded instant = `resolvedAt`; on a defeat `ambush.reachedCity` set and `rewards.coins` zero; `rewards.items = []`, `rewards.pet = null`, `rescuedCharacters = []`, `stagesCleared/stagesTotal = null`, `spellLearned = null`.
- **Effects immediately, report later (BE D-17):** HP, injuries, coins, xp, level, consumables and spell usages arrive at once on `characterUpdated`; the report waits for the arrival.
- **BE log lines:** `Imboscata <jobId> risolta: won` / `Imboscata <jobId> risolta: lost verso <città>` / `… skipped (<motivo>)`.
- **GraphQL probe (owner bearer):** `{ unacknowledgedQuestResults { id kind outcome resolvedAt quest { title } ambush { at nearCity { name } reachedCity { name } } } }`.
- **Deploy facts:** optional BE env `AMBUSH_TIMEZONE` (empty = Europe/Rome); new index `character_active_travel_ambush` created at boot; no migration, no seeder; the BE must be rebuilt only while stopped (already done by the orchestrator at `9103440`, port 3001).
- **An FE older than 16** drops the ambush reports silently and shows them all together after the update until acknowledged.

## 6. Tests

- Task 1 verify: `flutter test test/graphql test/tool test/models test/repository` → **`00:29 +1543: All tests passed!`**
- Task 2 full suite (foreground, alone, Bash timeout 600 000 ms): `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'` → **`01:11 +3391: All tests passed!`** (no `[E]` line; 3310 at 15-08 + 81 tests of the phase; same count as the park after the fixer).
- No pinned test went RED in this plan: nothing differed on the merged SDL (the plan's `<behavior>` applies «only if a name differs»).

## 7. Gates (Task 2)

- Analyzer: `flutter analyze` → `50 issues found. (ran in 3.4s)`; `grep -cE '^ *(error|warning) •'` → **0**; info → 50; **`ANALYZE_GATE_OK`** printed.
- Format of the phase's new Dart files (`git diff --name-only --diff-filter=A develop...HEAD -- lib test tool | grep '\.dart$'`, 7 files): `lib/models/quest_result/ambush_city.dart`, `lib/models/quest_result/ambush_report.dart`, `lib/models/quest_result/quest_result_kind.dart`, `lib/shared/components/popup/ambush_report_carousel.dart`, `test/models/quest_result/ambush_report_test.dart`, `test/models/quest_result/quest_result_kind_test.dart`, `test/shared/components/popup/ambush_report_carousel_test.dart` → **no `UNFORMATTED` line**. This plan touched no Dart file, so no `dart format` run.
- Trailers: `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` → **0** (45 commits since `develop` `f560d1d`; also 0 including `claude-session`).
- Sanity greps (each printed nothing):
  1. `grep -rn "package:flutter/" lib/models` → (empty)
  2. `grep -rn "Sei stato sconfitto" lib` → (empty) — no FE copy of the defeat push (D-10)
  3. `git diff develop -- lib/models/push_event.dart` → (empty) — `PushEvent` unchanged (D-10)
  4. `grep -rnE "animateToPage|nextPage|PageController" lib/shared/components/popup/ambush_report_carousel.dart` → (empty) — no programmatic paging (D-05 veto)
  5. `grep -rn "Imbosc" lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart lib/models/quest/quest_travel_line.dart lib/screens/mainScreen/tabs/board` → (empty) (D-07)
  6. `git diff develop --stat -- lib/screens/mainScreen/tabs/map lib/models/travel lib/screens/mainScreen/travelCubit lib/graphql/queries/travel_queries.dart lib/graphql/fragments/travel_preview_fragment.dart` → (empty) — no reroute mechanism (D-03/D-07)
  7. `grep -n "ambushDefeat" lib/screens/mainScreen/components/quest_result_presenter.dart` → (empty) — the toggle never gates the carousel (D-10)
- `pgrep -fl flutter_tester` → none; `git status --short` → empty before each commit.

## 8. `16-VALIDATION.md` (Task 2 step 6, commit c22517e)

- Rows `16-01-01` … `16-06-02` were already `✅ green`; rows `16-07-01`, `16-07-02` → `✅ green`; rows `16-08-01..03` stay `⬜ pending`.
- «Wave 0 Requirements» all `[x]`; frontmatter `status: approved`, `wave_0_complete: true`, `nyquist_compliant: true` kept; sign-off checklist ticked; `**Approval:** approved 2026-11-07 (plan 16-07, device rows 16-08-01..03 still pending)` + the line «Gate passed on BE `9103440`: 45/45 OK, full suite 3391 green, analyzer 50 info (0 error / 0 warning).»
- Acceptance greps: `grep -c "wave_0_complete: true"` → 1; `grep -cE "^\| 16-0[1-7]-0[1-2] .*✅ green"` → **14**; `grep -c "nyquist_compliant: true"` → **2**, not 1: the frontmatter line (`grep -c "^nyquist_compliant: true"` → 1) plus the pre-existing sign-off item «`nyquist_compliant: true` set in frontmatter» written at planning time. The checklist text was not altered to satisfy the grep (REPO-RULES: never reshape a file by hand for a grep).

## Deviations from Plan

No code deviation; names confirmed, nothing aligned. Notes:

1. **`git -C <BE> fetch` skipped** (plan `<interfaces>` line 3): the SSH agent is dead in this session; the local `origin/develop` ref (`9103440`, aligned by the orchestrator over HTTPS) was used, as the plan and the brief allow. No BE checkout/pull/edit, no BE process touched.
2. **`nyquist_compliant: true` acceptance grep counts 2** (frontmatter + the sign-off checklist literal, pre-existing). The frontmatter carries exactly one; nothing was rewritten to force the count.
3. `grep -c "⬜ pending"` on the VALIDATION prints 4 because the status legend line contains the glyph; the table cells (`| ⬜ pending |`) are exactly the 3 device rows of 16-08.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None: this plan created no network endpoint, auth path, file access pattern or schema change (T-16-17..T-16-20 mitigations applied: BE read-only via `show`/`log`/`ls-tree` on `origin/develop`, scratch outside the repo, `NODE_PATH` to `node_modules` only, no `.env*` read, sanity greps of T-16-20 empty).

## Next Phase Readiness (16-08)

- BE at `9103440` running from `dist/` on port 3001 (orchestrator-owned); schema 45/45 OK.
- Seed facts in §5; UAT shape in RESEARCH F8 and the BE handoff §6 table (won / lost / two ambushes / teleport).
- From the review: after a carousel of N ambushes a lone quest sheet reads «N+1 di N+k» (IN-03, specified D-11); offline a queued carousel waits for the silent retry give-up (IN-01).

## Self-Check: PASSED

- Files named in this SUMMARY exist (VALIDATION, ROADMAP, STATE, the 7 new Dart files of the phase); commits `c22517e` (Task 2) and `522ae91` (plan start) are in `git log`; BE ref `9103440` resolves in the BE repo.
