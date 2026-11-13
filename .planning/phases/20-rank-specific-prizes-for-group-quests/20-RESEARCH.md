# Phase 20: Rank-Specific Prizes for Group Quests - Research

**Researched:** 2026-11-13
**Domain:** Flutter consumer of a per-viewer prize block (BE Phase 21 «Premi per rango e soccorsi») and of new dungeon-turn counters on the quest result; mixed-rank boss seats; aid flow fixes that live on the BE
**Confidence:** HIGH for code facts (file:line read this session on `feat/20-rank-specific-prizes` at `1e5f3028`, identical in code to `develop` after PR #49; analyzer run: `47 issues found`, info only; 20 candidate files checked formatter-clean one by one); MEDIUM for the wire shape (BE research in progress: every new name below is **BE to confirm**; BE `origin/develop` `fbce3e16` SDL read, identical to the BE phase branch today)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `20-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **D-01** Rank blocks belong to group quests (`worldMission`, `boss` incl. mixed bosses, `aid` cloned from a group quest); solo quests (`enemy`, `hunt`, `dungeon`, aid of a solo quest, unregistered types) keep one prize on `requirements.minTitle`.
- **D-02** Group quests have no «any rank» seats; a block for every seat title; a null-title seat in a group quest is invalid content (refuse vs report: planner/BE).
- **D-03** Mixed-rank bosses at random: seats of the rank below, never above.
- **D-04** The participant's own character title at resolution decides the block.
- **D-05 / D-05a / D-05b / D-05c** Everything in a block goes by rank (coins, xp, loot, pet, cure, spell); pet drawn once per block; spells only for ranks ≥ mage, enforced on every BE path; cures/spells in practice only in solo `heal`/`magic`/`study`.
- **D-06** Generated quests: blocks from the tables, hand-editable at DB; hand-written quests: blocks written by the user, no seeding.
- **D-07** The quest sheet shows the viewer only the block of their own rank (same rows as today); the innkeeper's view of all blocks is Phase 21.
- **D-08** The result sheet is unchanged in shape (`QuestResult.rewards`).
- **D-09 / D-09b / D-10 / D-11** Aid only from `enemy`, `boss`, `hunt`, `dungeon`, `aid`; crime unchanged; lost rescue unchanged; group aid clones the rank blocks (cure not inherited).
- **D-12 / D-13 / D-14 / D-15 / D-16** Dungeon aid by turns up to the turn where the wounded fell (exploration or fight); structure + placeholder (engine is the user's); rescuer prize proportional to turns completed; dungeon «available again» for the rescued character; archiver releases registered rescuers like the timeout.
- **D-17** DB cleanup done (0 aid at DB).

### Claude's Discretion
- Wire shape of the per-viewer prize (recommended: BE resolves `Quest.prizes` for the viewer's rank, like `noEffect`; plus a list of blocks for the innkeeper in Phase 21) — decided with the BE companion.
- Frequency and mix of the lower-rank seats in mixed bosses (D-03).
- Unit and rounding of the proportional dungeon-aid prize (D-14).
- Field names (`rankPrizes`/`prizesByRank`, saved turn on `rescue`).

### Deferred Ideas (OUT OF SCOPE)
- The turn-based dungeon combat/exploration engine (the user writes it; D-13 only prepares the structure).
- Innkeeper's view and choice of prizes per character (Phase 21).
- BE companion opened as BE Phase 21; FE plans that read the new wire shape are gated on its merge.
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs exist yet: `.planning/REQUIREMENTS.md` still scopes v1.1 to Phases 18–19 (`REQUIREMENTS.md:5`, coverage line `:62`) and ROADMAP §Phase 20 says «Requirements: TBD». Proposed IDs for the planner (to be added to `REQUIREMENTS.md` + traceability in the first plan or by the orchestrator):

| ID (proposed) | Description | Research Support |
|----|-------------|------------------|
| RANKP-01 | The quest sheet (Board and Map) shows the prize block the BE serves for the viewer, with today's rows; no client-side choice of a block | F1, F2, F6 |
| RANKP-02 | Mixed-rank bosses: one seat line per title, viewer's rank highlighted, registration and party counter judged per seat title as the BE does | F4 |
| RANKP-03 | Result sheet: dungeon-turn counters (dungeon and dungeon aid) printed from the BE, lenient parsing, the stages line kept as fallback | F3 |
| RANKP-04 | Schema gate on the merged BE SDL, schema check 46 × OK, device E2E covering rank blocks, mixed boss, dungeon aid by turns and the aid fixes visible on the FE | F5, F7, Validation |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (models Flutter-free, UI no networking, Cubit no `BuildContext`), TDD red → green → refactor, Boy Scout rule.
- Rule 1 no app chrome on gameplay (quest sheets and result sheet are gameplay). Rule 2 no blocking loading in session (rereads stay silent). Rule 3 branch `feat/20-rank-specific-prizes`, PR → `develop`. Rule 4 **backend is the source of truth**: the FE never picks a block, never scales a prize, never counts turns. Rule 5 no secrets.
- `docs/rules/graphql.md`: documents only in `lib/graphql/`, one fragment per entity (`QuestFragment`, `QuestResultFragment`). `docs/rules/state-management.md`: `Equatable` states with full `props`. `docs/rules/naming.md`: `snake_case.dart`, booleans `isX/hasX`, enums `lowerCamelCase` values. `docs/rules/testing.md`: new model field → `fromJson`/`toJson`/`Equatable` test first; critical gameplay widgets (quest sheet, combat outcome) need interaction/smoke tests. `docs/rules/ui-ux.md`: theme tokens only, no inline styles.
- Repo practice (Phase 19 `19-REPO-RULES.md`, to be reissued as `20-REPO-RULES.md`): `dart format` per touched file only (baseline not formatter-clean), analyzer `flutter analyze --no-fatal-infos` 0 error / 0 warning, full suite only in the gate plan, no commit trailers, docs scope `phase-20`, BE repo read-only, `pubspec.lock` never staged.

## Summary

Five facts shape the plan. **(1) Under the working hypothesis the FE wire does not break.** The board and the map read prizes from one place: `QuestFragment.fields` → `prizes { prizeCoins xpPrize randomLoot prizeItem pet { id name } cure { … } }` (`quest_fragment.dart:63-102`), used by exactly two documents (`quests`, `OnQuestUpdated`); the sheet renders `quest.prizes` without knowing the viewer (`quest_info_sheet.dart:119`, `:428-471`, `quest_sheet_details.dart:120`). If the BE turns `Quest.prizes` into a per-viewer resolved field with today's type `QuestPrizes` (pattern `Quest.noEffect`, BE `quest-no-effect.resolver.ts:16-27`), **no FE document, model or widget changes for D-07**: the selection stays valid, the sheet keeps reading one block. The innkeeper's list (`rankPrizes`) is additive and not selected in this phase. The only new selections are the dungeon-turn counters on `QuestResult` — additive. So the CONTEXT premise «non-additive → FE gated» does not hold for the FE under this hypothesis: only the fragment selection of the new result fields and the device E2E wait for the BE merge (Phase 18 pattern, not Phase 19).

**(2) The sheet's «same rows as today» are four, not six** (C1): coins (`CoinsDisplay`), the prize item card, the pet line «Compagno in premio: …» (prize area, `:438-468`) and the two cure lines in the body (`:339-348`). `xpPrize` and `randomLoot` are parsed (`quest_prizes.dart:34-40`) and **never shown**; `prizes.spell` is **not even selected**. So there is no spell row for a non-caster to see (question 6: nothing to hide, D-05c costs the FE nothing). **(3) The rescan on a title change already exists:** `QuestScopeListener` puts `status.title` in the scope record (`quest_scope_listener.dart:68`) and rereads `quests` silently on change (`:47-59`), pinned by `quest_scope_listener_test.dart:128` («a new title rereads the quests»); `quests` runs `FetchPolicy.noCache` (`graphql.dart:78-85`, `:325`), and the map sheet resolves its quest from the same list (`world_map.dart:366-372`; lane quests are id-only, `character_fragment.dart:104-138`). A rank-up therefore refreshes the block with no new code.

**(4) Mixed bosses need no FE logic change, but they expose two BE consistency points the FE mirrors:** `_slotLinesOf` already draws one line per distinct seat title in wire order and highlights the viewer's (`quest_sheet_details.dart:190-226`); `canRegisterWithTitle` judges exact seats per title plus the legend → hero fold (`quest_capacity.dart:33-50`). But eligibility is checked on `minTitle` first, on both sides (`quest_availability.dart:107-113`, BE `quest-eligibility.ts:164`), and the generator writes `minTitle = composition.rank` (BE `generated-quest-draft.ts:119`): a mixed boss must carry `minTitle` = its **lowest** seat title, or adventurers are refused by a seat that exists. And a **legend** sits on hero seats (BE 13.1 D-08) while D-02 creates blocks only for seat titles: there is no legend block on a hero boss (C3, product question PQ1). **(5) The result sheet has a natural slot for the turn counters:** today's stages line is `'Esplorazione: tappa ${stagesCleared ?? 0} di $total'` (`quest_result_sheet.dart:459-463`, inserted at `:171`), not «Ho superato N tappe di M» as the CONTEXT cites (C2); the BE fills `stagesCleared/Total` with **fights** (one stage per `enemies` entry, BE `placeholder-dungeon-resolver.ts:104-140`) and leaves them null on rescue results (BE `rescue-plan.ts:85-86`). The turn line replaces the stages line when the BE sends turns, and falls back to it otherwise.

**Primary recommendation:** adopt the hypothesis (`Quest.prizes` resolved per viewer, type unchanged, never null on the wire) and plan four plans: (1) pre-gate pin tests for the served-block contract and mixed bosses (mostly green at first run, they document the contract), (2) pre-gate `QuestResult` turn fields + pure lines + sheet insertion, lenient, hidden while absent, (3) gated: schema gate + `QuestResultFragment` selection + schema check 46 × OK + full suite, (4) gated human checkpoint: device E2E + `BACKEND-NOTES.md` + requirements.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `equatable` | new `QuestResult` fields in `props`; possible `DungeonTurnKind` enum (no class needed) | [VERIFIED: codebase] |
| `flutter_bloc` / `bloc_test ^10.0.0` / `mocktail ^1.0.5` | no new cubit; `QuestScopeListener` and `QuestCubit` untouched | [VERIFIED: codebase] |
| `graphql_flutter 5.2.1`, `gql` (`parseString`) | fragment selection, document pins (`quest_result_documents_test.dart`, `board_documents_test.dart`) | [VERIFIED: codebase] |
| Dart `Enum.values.asNameMap()` | lenient enum read of the turn kind (pattern `QuestResultQuest.type`, `quest_result_quest.dart:21`; `titleBefore` `quest_result.dart:173`) | [VERIFIED: codebase] |
| Node + BE `node_modules/graphql` | `tool/schema_check/validate_documents.js` (manual gate, not in CI: `.github/workflows/ci.yml` runs analyze, test, `hardening_check.sh`, release build) | [VERIFIED: codebase] |

## Architecture Patterns

### Likely files per area
```
# RANKP-01 (rank block on the sheet) — under the hypothesis: tests only
lib/graphql/fragments/quest_fragment.dart          # unchanged (prizes selection :63-102)
lib/models/quest/quest_prizes.dart, quest.dart     # unchanged
lib/models/quest/quest_sheet_details.dart          # unchanged (pet line :120, :178-179)
lib/shared/components/popup/quest_info_sheet.dart  # unchanged (rewards :119, :403-471; cure :339-348)
test/models/quest/quest_test.dart                  # + «an unknown rankPrizes key is ignored (D-07)»
test/shared/components/popup/quest_info_sheet_test.dart  # + «the sheet renders the served block, no title logic (D-07)»
# RANKP-02 (mixed bosses) — tests only
test/models/quest/quest_sheet_details_test.dart, test/models/quest/quest_capacity_test.dart (or existing capacity test file),
test/models/quest/quest_state_label_test.dart (k/N on mixed seats)
# RANKP-03 (turn counters)
lib/models/quest_result/quest_result.dart          # + turnsCleared, turnsTotal, turnKind (names BE to confirm), lenient
lib/models/enums/dungeon_turn_kind.dart            # NEW enum { exploration, fight } with Italian labels (if the BE sends a kind)
lib/utils/quest_outcome_lines.dart                 # + dungeonTurnLine(result) (pure)
lib/shared/components/popup/quest_result_sheet.dart  # :171 the stages slot prints the turn line when present
lib/graphql/fragments/quest_result_fragment.dart   # (gated) selection after stagesTotal (:116)
test/helpers/fixtures/quest_result_fixtures.dart   # dungeonResultJson (:202-226) + turn params; new aidDungeonResultJson
test/models/quest_result/quest_result_test.dart, test/utils/quest_outcome_lines_test.dart,
test/shared/components/popup/quest_result_sheet_test.dart (:308-345 stage cases), test/graphql/quest_result_documents_test.dart (:50-63)
# RANKP-04 gate + E2E
.planning/phases/20-…/20-HUMAN-UAT.md, BACKEND-NOTES.md
```
All the listed `lib`/`test` files are formatter-clean today [VERIFIED: `dart format --output=none --set-exit-if-changed` per file].

### F1. Q1 — where prizes are read and shown today [VERIFIED: codebase]

| Layer | File:line | What it does | Under the hypothesis |
|-------|-----------|--------------|----------------------|
| Fragment | `lib/graphql/fragments/quest_fragment.dart:62-102` | `noEffect` then `prizes { prizeCoins {Coins} xpPrize randomLoot {…} prizeItem {… LootItem + description effect power canHeal} pet { id name } cure { lifePointsShare canHeal } }`; **no `spell`** | unchanged |
| Documents | `quest_queries.dart:4-11` (`quests`), `quest_subscriptions.dart:4-11` (`OnQuestUpdated`) | the only two users of `QuestFragment` | unchanged; both must be per-viewer on the BE (HTTP and WS) |
| Model | `lib/models/quest/quest.dart:20, :34-36` | `QuestPrizes? prizes` (null when absent) | unchanged |
| Model | `lib/models/quest/quest_prizes.dart:30-43` | `prizeCoins`, `xpPrize`, `prizeItem` (`AssetQuantity` or bare item, `:85-90`), `randomLoot` (strict per entry `AssetQuantity.fromJson`, `:36-40`), `pet` (`Pet.tryFromJson`), `cure` (`QuestCure.tryFromJson`) | unchanged; a malformed block drops the quest through `Quest.tryFromJson` (`quest.dart:45-52`) — same as today |
| Details | `lib/models/quest/quest_sheet_details.dart:120, :178-179` | `petPrizeLine` «Compagno in premio: $name» | unchanged |
| Sheet | `lib/shared/components/popup/quest_info_sheet.dart:119-120` | rewards area built only when `quest.prizes != null` | unchanged |
| Sheet | `quest_info_sheet.dart:403-471` | «Ricompense:» + row: `CoinsDisplay(prizeCoins)`, prize item card (`EquipmentItemCard`/`LootItemCard`), pet line | unchanged |
| Sheet | `quest_info_sheet.dart:339-348` | cure lines from `prizes.cure` (`curableInjuriesLine`, `lifeShareLine`) in every family body | unchanged (cure by rank arrives already resolved) |
| Board | `lib/screens/mainScreen/tabs/board/board.dart:206, :255-339` | `QuestInfoSheet(quest, viewer, …)` | unchanged |
| Map | `lib/screens/mainScreen/tabs/map/world_map.dart:344-372` → `layers/quest_info_overlay.dart:54` | `QuestInfoSheet(quest)` with **no viewer**; quest taken from the `quests` list (`_currentOf`) | unchanged (the block is already the viewer's: no title needed on the map) |
| Innkeeper | `lib/graphql/fragments/pending_request_fragment.dart:9-14` | `quest { id type title requiredAdventurers }`, no prizes | unchanged (Phase 21) |
| Result | `quest_result_fragment.dart:64` `rewards {…}` → `quest_rewards.dart`, sheet `_rewards()` `quest_result_sheet.dart:367-388` | awarded coins, items, pet per participant | unchanged (D-08) |

`grep -rn "xpPrize\|randomLoot\|prizeCoins\|prizeItem\|prizes" lib` (outside the model and fragment) returns only the sheet and the details lines above: **no cubit reads prizes**, no other screen. Tests that carry prizes: `quest_info_sheet_test.dart:110, :530-607, :1060, :1123`, `quest_test.dart`, `quest_sheet_details_test.dart`, `board_test.dart`, `world_map_travel_test.dart`, `quest_info_overlay_test.dart`, `board_documents_test.dart:86-95` (pins `pet { id name } cure { lifePointsShare canHeal }`), fixture `test/helpers/fixtures/quest_fixtures.dart` (`buildQuest(prizes:)`).

**What breaks under the hypothesis: nothing** on the FE, provided the BE keeps (a) the field name `prizes`, (b) the type `QuestPrizes` with today's sub-fields, (c) a non-null value for every viewer (see PQ1 for the fallback), (d) per-subscriber resolution on `questUpdated`.

**Alternative — the BE exposes `rankPrizes [{ title, …block… }]` and the app chooses:**
- Fragment: a second, nested copy of the whole prize body under `rankPrizes { title … }` (best as a new `QuestPrizesFragment` shared by both, Boy Scout); payload × number of blocks for every quest of the board.
- Model: `List<RankPrizes>` lenient per entry (unknown title → entry dropped, Phase 19 D-16 rule) on `QuestPrizes` or `Quest`.
- A pure selector `prizesForViewer(Quest, TitleType?)` that mirrors the BE fallback (own block, legend → hero, ineligible viewer, no character) — a second copy of a BE rule, like `canRegisterWithTitle` (allowed precedent, but rule 4 friction).
- `QuestSheetDetails.of` gains the resolved block; `QuestInfoSheet` must read prize rows from the details, not from `quest.prizes` (`:119`, `:429`, `:340`); the **map overlay has no viewer** (`quest_info_overlay.dart:54`) → a title must be threaded `world_map.dart` → `QuestInfoOverlay` → `QuestInfoSheet`.
- If the BE also drops `prizes` for group quests or makes it the «minimum» block, the change is non-additive: legacy reader window as in Phase 19 D-15, gated fragment flip, RED-first deletion. Roughly +2 plans and ~10 test files touched.

### F2. Q2 — in-session refresh on a title change or `questUpdated` [VERIFIED: codebase]
- `QuestScopeListener` (`lib/screens/mainScreen/components/quest_scope_listener.dart:11-20` record, `:61-79` scope) includes `title: status?.title` (`:68`); `listenWhen` compares records (`:47-51`) and `_reread` calls `QuestCubit.refreshQuests(cityId:)` (`:53-59`), silent (rule 2). Pin: `test/screens/mainScreen/components/quest_scope_listener_test.dart:128` «a new title rereads the quests» (quick 261105-scp).
- `quests` is `FetchPolicy.noCache` (`graphql.dart:78-85` `performQuery`, used at `:325`): no stale normalised `prizes` from the cache.
- `QuestCubit.watchQuest` (`quest_cubit.dart:118-160`) replaces the listed quest with every `questUpdated` payload (`_replaceQuest`). Under the hypothesis the payload carries the block **of the subscriber**, so the BE must resolve per subscriber inside one event: the `noEffect` precedent memoises «per viewer inside the event key» (BE `viewer-vitals.service.ts:35-36`, «trappola Phase 16»). The FE cannot detect a wrong block; only a two-character device step can (Validation).
- Edge: the map sheet of a quest that is no longer in the `quests` list keeps the last object (`world_map.dart:366-372` returns `selected`): after a rank-up during a started quest the map may show the old block until the list contains the quest again. Cosmetic, the result sheet is authoritative (D-04 decides at resolution). Record as known limitation, no plan.
- **Conclusion:** no new reread is needed. Under the alternative, no reread is needed either (all blocks present), but the selection logic must react to `CharacterCubit` (title) — the board already passes `viewer`; the map would need it.

### F3. Q3 — result sheet: stages line, turn counters, proportional prize [VERIFIED: codebase + BE read]
- **Model:** `QuestResult.stagesCleared/stagesTotal` (`quest_result.dart:114-116`), lenient `_countFrom` (`:179-180`, `:218`: non-number → null); `toJson` `:262-263`; `props` `:301-302`. Lenient precedents for additive fields: `petXpGained` `_nonNegativeInt` (`:170`, `:220-221`), `arrested`/`guardEncounter` `== true`. `QuestResult.tryFromJson` (`:192-199`) drops the whole result on any throw → **new fields must never throw** (a `byName` on an unknown kind would make the result sheet disappear).
- **Fragment:** `quest_result_fragment.dart:115-117` `stagesCleared stagesTotal rescuedCharacters`; the pin `quest_result_documents_test.dart:50-63` asserts the substring `enemies { … } stagesCleared stagesTotal` → insert the new names **after** `stagesTotal`, before `rescuedCharacters`: the pin stays green; add a new pin for the new adjacency. Three documents share the fragment (`OnQuestResultReceived`, `GetQuestResult`, `ListUnacknowledgedQuestResults`).
- **Sheet:** `_content()` `quest_result_sheet.dart:164-200`; the stages line is `..._line(_stagesText(), QuestResultSheet.stagesKey)` at **:171**, right after the enemies block; `_stagesText()` `:459-463` prints `'Esplorazione: tappa ${stagesCleared ?? 0} di $total'`, null when `stagesTotal == null`. Pins: `quest_result_sheet_test.dart:308-345` («a dungeon shows «Esplorazione: tappa k di N» (D-07)», position check `:319`, victory 3/3, absence `:345`). Fixture `dungeonResultJson` (`quest_result_fixtures.dart:202-226`).
- **BE today:** stages = one per `enemies` entry, i.e. **fights only** (`placeholder-dungeon-resolver.ts:104-140`, «D-12: una tappa per voce di `enemies`»); rescue results write `stagesCleared: null, stagesTotal: null` (`rescue-plan.ts:85-86`). A dungeon aid result today therefore shows no stage line at all.
- **Recommended FE shape (no chrome, one line in the existing slot):**
  - `turnsTotal == null` → today's stages line, unchanged (back-compat; also the behaviour against the BE of today).
  - `turnsTotal != null` → **one** turn line in the same slot with the same key family (new key `QuestResultSheet.turnsKey`, the stages key no longer rendered), copy chosen by `(outcome, quest.type, turnKind)` in a pure helper `dungeonTurnLine(QuestResult)` in `lib/utils/quest_outcome_lines.dart` (where `arrestLine`/`guardEncounterLine`/`companionXpGainedLine` live, `:12-40`).
  - The proportional prize needs **no FE arithmetic**: the awarded coins/items/xp already arrive in `rewards` and `xpGained` (D-08, rule 4). An optional explanatory line (PQ3) is printed from the BE counters only.
- Parsing: `turnsCleared`/`turnsTotal` with `_countFrom` (negative → treat as absent? recommend `_countFrom` as today; the BE never sends negatives); `turnKind` through `DungeonTurnKind.values.asNameMap()` → unknown/absent = null (line without the kind).

### F4. Q4 — mixed bosses and title seats [VERIFIED: codebase + BE read]
- **Seat lines:** `_slotLinesOf` (`quest_sheet_details.dart:190-226`) collects distinct seat titles in wire order (`:199-203`), one `QuestSlotLine` per title with `registered = min(reg, exact)` and `isViewerRank` (`:211-217`), plus a «Qualsiasi rango» line only when wildcard seats exist (`:218-224`). Drawn only for registered, non-single-player types (`_drawsSeats` `:172-175`; `registeredQuestTypes` = worldMission, boss, enemy, aid `quest_lane.dart:14-19`; `isSinglePlayerQuest` = enemy only `quest_capacity.dart:12`). A boss with `[paladin×2, adventurer×1]` already renders «Paladino: 0 / 2», «Avventuriero: 0 / 1» with the viewer's line in `specialText` (`quest_info_sheet.dart:393-401`). **No code change.**
- **Registration mirror:** `canRegisterWithTitle` (`quest_capacity.dart:33-50`) = exact seats of the viewer's (folded) title, else wildcard overflow; legends beyond legend seats fold onto hero (`:55-79`, quick 261105-lgd). Mixed seats work as is; a paladin cannot take an adventurer seat (exact match), which matches D-03 «never the rank above» from the seat's point of view. Party counter k/N: `quest_state_label.dart:9, :37` uses total seats → unchanged.
- **Eligibility comes first:** `_availabilityOf` checks `isTitleEligible(minTitle)` (`quest_availability.dart:107-113`, rule `title.index >= minTitle.index` for non-story `:44-54`) before seats; the BE does the same (`quest-eligibility.ts:164` `meetsTitle`). The generator writes `minTitle: composition.rank` (BE `generated-quest-draft.ts:119`). **A mixed boss must carry `minTitle` = lowest seat title** (BE to confirm), otherwise an adventurer sees a red «Titolo minimo: Paladino» and a torn sheet on a quest with a free adventurer seat — and the BE refuses him. FE needs no change if the BE does this.
- **D-02 null seats:** a group quest with a null-title seat would render «Qualsiasi rango: k / n» (`:218-224`); the BE refuses/reports it (D-02). The aid of a solo quest legitimately keeps one wildcard seat (BE `aid-quest.ts:93-102` → `soloSlots()` for enemy/dungeon/hunt): the «Qualsiasi rango: 0 / 1» line on those aids stays and is correct.
- Tests to add (green at first run expected, recorded as contract pins): mixed seat lines + viewer highlight; `canRegisterWithTitle` per title on mixed seats (paladin full, adventurer free → adventurer can, paladin cannot); `isFullFor` / availability `full` for a hero viewer on a paladin+adventurer boss (no seat for his title); k/N counter on mixed seats.

### F5. Q5 — what the FE shows of an aid, and what changes [VERIFIED: codebase]
- **Board sheet:** aid = combat family (`questSheetFamilyOf` `quest_sheet_details.dart:25-33`), own paper (`quest_paper_asset.dart:81`), seats drawn (registered type), prize area = `quest.prizes` (per viewer under the hypothesis: the clone of the rank blocks, D-11, needs nothing on the FE).
- **Lane:** «Aiutando…» (`quest_state_label.dart:16`).
- **Wounded:** «In attesa di soccorso» over the pawn (`character_marker_layer.dart:35-38, :117-122`), travel/board gating through `status.awaitingAid` (`main_screen.dart:290-300`, `character_marker_layer.dart:176-182`); `AwaitingAid { quest aidQuest since }` (`character_fragment.dart:50-52`, `awaiting_aid.dart`). Innkeeper queue shows presence from `awaitingAid` (`pending_request_fragment.dart:20`, `presence_label.dart`).
- **Result:** rescued → header «Sei stato salvato» (`quest_outcome.dart:5`), HP bar hidden (`quest_result_sheet.dart:306-308`); rescuer → «Hai salvato N avventurieri» (`:506-512`, key `rescuedKey`).
- **Push:** no aid-specific category (`notification_category.dart:6-11`: travelEnd, streamerLive, questEnd, questCancelled, ambushDefeat, prisonRelease). D-16 (archiver releasing registered rescuers) should reuse the timeout's `notifyCancelled` (BE `party-timeout.service.ts:135-156, :170+`) → the rescuer gets a **`questCancelled`** push, already handled by the FE (quick 261025-grp). BE to confirm the push is sent on that path.
- **D-09 (fewer aids):** no FE code; heal/job/study/magic lost fights simply stop producing «In attesa di soccorso». **D-15:** the rescued character is freed through `characterUpdated` (`awaitingAid` → null) as today.
- **Dungeon aid:** today seats = one wildcard (dungeon has no seats), prize = dungeon prize cloned. With D-14 the prize the rescuer will get is a share; what the aid **sheet** shows is PQ2. The saved turn is not on the FE wire today (no `rescue` field on `Quest`, SDL `type Quest { id infos noEffect prizes registeredAdventurers requirements }`); a sheet line «Il ferito è caduto al turno k di N» would need a new `Quest` field — **not recommended in this phase** (no decision asks for it; result-only counters per D-13).

### F6. Q6 — the spell row [VERIFIED: codebase]
There is **no spell row** on the quest sheet: `QuestFragment` does not select `prizes.spell` (`quest_fragment.dart:63-102`), `QuestPrizes` has no `spell` field (`quest_prizes.dart:9-28`), no widget prints one. A non-caster sees nothing today and after the phase. With the hypothesis the question is moot; with the alternative it is moot too. The only spell line in the app on this path is the result's «Magia appresa: …» (`quest_result_sheet.dart:492-496`), printed from `spellLearned` — D-05b (BE refuses non-casters) makes it disappear for < mage by itself.

### F7. Q7 — schema gate, pinned tests, baselines [VERIFIED: codebase + run]
- **Registry:** `tool/schema_check/schema_check_documents.dart:43-89`, **46 entries**; this phase adds no operation (stays 46; the count pins `test/tool/schema_check_documents_test.dart:32-34` and siblings do not move). Run: `dart run tool/schema_check/dump_documents.dart <dir>` («dumped 46 documents») + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → 46 × OK. Not part of CI.
- **Documents this phase touches:** under the hypothesis only `QuestResultFragment` (→ `OnQuestResultReceived`, `GetQuestResult`, `ListUnacknowledgedQuestResults`). `quests`/`OnQuestUpdated` are re-validated (their `prizes` selection must still validate: proves (a)/(b) of F1).
- **Gate checks (block-anchored, Phase 19 D-19 style)** on `git -C <BE> show origin/develop:src/schema.gql`: `awk '/^type Quest /,/^}/'` contains `prizes: QuestPrizes` (with or without `!`); `awk '/^type QuestPrizes /,/^}/'` still contains `cure: QuestCure`, `pet: Pet`, `prizeCoins: Coins`, `prizeItem: AssetQuantity`, `randomLoot: [AssetQuantity!]!`, `xpPrize: Int`; `awk '/^type QuestResult /,/^}/'` contains the confirmed turn fields and still `stagesCleared: Int`, `stagesTotal: Int`, `rewards: QuestRewards!`; if a kind enum is used, `enum <Name>` has `exploration` and `fight`. Today every new name counts 0 (`grep -c "turn" schema.gql` on the QuestResult block = 0) [VERIFIED: SDL read].
- **Tests pinning the quest sheet:** `test/shared/components/popup/quest_info_sheet_test.dart` (1188 lines; prizes `:530-607`), `test/models/quest/quest_sheet_details_test.dart` (420), `test/models/quest/quest_test.dart` (326), `test/screens/mainScreen/tabs/board/board_test.dart`, `tabs/map/quest_info_overlay_test.dart`, `world_map_travel_test.dart`, `test/graphql/board_documents_test.dart:42-133`. **Result sheet:** `test/shared/components/popup/quest_result_sheet_test.dart` (1168; stages `:308-345`), `test/models/quest_result/quest_result_test.dart`, `test/graphql/quest_result_documents_test.dart`, `test/screens/mainScreen/main_screen_quest_results_test.dart`. **No golden tests** in the repo (`grep -rl matchesGoldenFile test` → nothing).
- **Baselines:** analyzer `47 issues found`, info only [VERIFIED: run this session]; full suite **4239 green** after quick 261111-enm (`19-VALIDATION.md:123`, STATE) [CITED, not re-run per the rules]; schema check 46 × OK on BE `48b20701` (Phase 19 gate) — BE `origin/develop` is now `fbce3e16` (PR #34 merged), to re-run in the gate plan.

### F8. Q8 — Italian copy and assets
Tone of the existing lines: short, factual, second person for the viewer («Hai salvato 2 avventurieri», «Sei stato arrestato.», «Il tuo compagno guadagna 12 PE»), labels with colon («Esplorazione: tappa 1 di 3», «Titolo minimo: Mago»). Proposed (provisional, the orchestrator fixes them in `20-REPO-RULES.md`):

| Situation | Line (one, in the stages slot) |
|-----------|-------------------------------|
| Dungeon cleared | «Turni superati: 8 di 8» |
| Dungeon lost, kind known | «Caduto al turno 4 di 8, in esplorazione» / «Caduto al turno 4 di 8, in uno scontro» |
| Dungeon lost, kind unknown | «Caduto al turno 4 di 8» |
| Dungeon aid won (rescuer) | «Ferito raggiunto al turno 4 di 8» (+ PQ3 optional «Premio in proporzione: 4 turni su 8») |
| Dungeon aid lost (rescuer) | same as «Dungeon lost» |
| Turns absent | today's «Esplorazione: tappa k di N» |

Index semantics to fix with the BE: «Caduto al turno 4» = 3 cleared + fell in the 4th → `turnsCleared + 1` must NOT be computed by the FE; the BE should send the turn number it means (see «What the FE needs», field `turnIndex` or `turnsCleared` defined as «turn reached»). **Assets: none** (text only, existing theme styles `bodyMedium`).

### Anti-Patterns to Avoid
- Picking, merging or scaling prize blocks on the FE (rule 4); computing «turn + 1» or a share.
- Threading the viewer's title into the map sheet «just in case» under the hypothesis: nothing reads it.
- A `byName` on the new turn kind inside `QuestResult.fromJson` (drops the whole result via `tryFromJson`).
- Selecting `rankPrizes` in this phase «because it exists»: payload × blocks, no reader (Phase 21 owns it).
- Moving the stage line to a new position or adding a section/box for the turns (rule 1; one text line in the existing slot).
- A bare `grep -c prizes` / `grep -c turn` acceptance check (hundreds of unrelated hits): anchor to the type block.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Choosing the viewer's block | a client selector with fallback rules | BE-resolved `Quest.prizes` (pattern `noEffect`) | one rule, server-side; legend/ineligible/no-character edge cases stay on the BE |
| Lenient counters/enums | try/catch around `byName` | `_countFrom` (`quest_result.dart:218`), `asNameMap()` | existing helpers |
| Outcome strings | literals in the sheet | pure helpers in `lib/utils/quest_outcome_lines.dart` | file doc: result lines live there; unit-testable |
| Schema validation | a new script | `dump_documents.dart` + `validate_documents.js` | 46 documents registered |
| Mixed seat logic | new seat code | `_slotLinesOf`, `canRegisterWithTitle`, `questSlotsOf` | already generic over titles |

## What the FE needs from the BE (hand to the BE research)

**Prize block (D-07) — recommended, minimal break:**
1. `Quest.prizes` keeps **name and type** `QuestPrizes` with today's sub-fields and nullability (`cure: QuestCure`, `pet: Pet`, `prizeCoins: Coins`, `prizeItem: AssetQuantity`, `randomLoot: [AssetQuantity!]!`, `spell: Spell`, `xpPrize: Int`), now **resolved for the current character of the bearer** on every path that returns `Quest`: `quests` (HTTP) and `questUpdated` (WS, per subscriber inside one event — memo per viewer as `ViewerVitalsService`).
2. **Stay non-null (`QuestPrizes!`)** for every viewer. Solo quests: the single stored prize. Group quests: the viewer's block; when the viewer's title has no block → fallback per PQ1 (recommended: highest block not above the viewer's title, else the lowest block; this also gives a legend the hero block on a hero boss); no character / anonymous → the lowest block. If the BE prefers `null` for «no block», the FE tolerates it (no rewards area, `quest_info_sheet.dart:119`) but the sheet loses the header: say so in the handoff.
3. Keep the same block rule for **resolution** (D-04) and for **display**: the block a viewer sees before accepting = the block awarded if the title does not change.
4. The list of blocks for the innkeeper (`rankPrizes`, BE draft name) is **additive and not selected by the FE in Phase 20**; any shape is fine (suggestion: `[QuestRankPrizes!]!` with `title: String!` + the `QuestPrizes` fields, or `{ title: String!, prizes: QuestPrizes! }` which lets Phase 21 reuse one FE fragment). Empty list on solo quests.
5. Group-quest `cure`/`spell` per block: unchanged sub-fields, nothing new on the FE.

**Mixed bosses (D-03):**
6. `requirements.minTitle` of a mixed boss = **lowest seat title** (FE `isTitleEligible` and BE `meetsTitle` both gate on it before seats).
7. Seat order on the wire: own rank first, lower rank second (the FE draws lines in wire order); no null-title seat on group quests (D-02).

**Dungeon turns (D-12..D-14) — additive, nullable, on `QuestResult`:**
8. `turnsTotal: Int` — total turns of the dungeon (aid: the source dungeon's total). `null` outside dungeon and dungeon-aid results.
9. `turnsCleared: Int` — turns completed by this participant (victory: = total; defeat: turns passed before falling; aid rescuer: turns completed up to and including the rescued turn).
10. `turnKind: <Enum>` with values `exploration`, `fight` — kind of the turn where the walk **stopped** (defeat turn, or the rescued turn on a won aid); `null` on a full clear. Prefer a real GraphQL enum (validated by the schema check); the FE parses leniently either way.
11. Either define «turn reached» explicitly or add `turnIndex: Int` (1-based) for the turn where it stopped, so the FE never adds 1. Recommended: send `turnIndex` and keep `turnsCleared` as the count.
12. Keep `stagesCleared`/`stagesTotal` as they are (additive change only; the FE falls back to them when turns are absent). If the BE wants to retire them, do it in a later phase with a FE twin.
13. The proportional prize lives entirely in `rewards` and `xpGained` of the rescuer's result (no FE arithmetic). If PQ2 = «share on the sheet», the **aid quest's stored prizes are the scaled ones** (computed at aid creation from the saved turn), so `Quest.prizes` of the aid already shows the share.
14. Rescued character's result (`outcome: rescued`): no turn fields needed.

**Aid fixes visible on the FE:**
15. D-16: the archiver path sends the same `questCancelled` push the timeout sends (FE category exists).
16. D-09: no FE contract change. D-05b: no FE contract change (`spellLearned` simply stays null for < mage).

**What would make the FE change non-additive (avoid in this phase):** renaming or removing `Quest.prizes`; changing `QuestPrizes` sub-fields; replacing `stagesCleared/stagesTotal`; a required argument on `quests`.

## CONTEXT amendment proposals

- **A1 (D-07 rows):** «same rows as today» = coins, prize item card, pet line «Compagno in premio: …» (prize area) and the cure lines (body); `xpPrize` and `randomLoot` are parsed but not shown; `spell` is not selected. No new rows in this phase; no spell row exists to hide.
- **A2 (canonical ref, Phase 14):** the dungeon line is «Esplorazione: tappa N di M» (`quest_result_sheet.dart:459-463`), not «Ho superato N tappe di M».
- **A3 (Established Patterns):** under the recommended shape the FE contract change is **additive** (only new `QuestResult` fields are selected): FE pre-gate plans are safe against the BE of today; only the fragment selection and the device E2E wait for the BE merge (Phase 18 pattern). The «non-additive → FE gated» line applies only to the alternative shape.
- **A4 (D-03 + D-04 + D-02):** a mixed boss carries `minTitle` = its lowest seat title; a legend seated on hero seats is resolved per PQ1 (recommended: hero block).
- **A5 (D-13 FE scope):** the FE prints one turn line in the stages slot of the result sheet (dungeon and dungeon aid), falling back to the stages line; no turn line on the quest sheet in this phase.

## Product questions for the user (minimal, each with a recommendation)

Written in Italian for `AskUserQuestion`:

- **PQ1 — Premio mostrato a chi non ha un blocco del suo rango.** «Su una quest di gruppo, chi guarda il foglio senza un blocco del proprio rango (un leggendario su un boss eroe, un avventuriero su un boss del mago, chi non ha personaggio) che premio vede? (a) il blocco del rango più alto non superiore al suo, altrimenti il blocco più basso — e un leggendario seduto su un posto eroe riceve il premio eroe; (b) nessun premio sul foglio, solo i posti.» **Raccomandazione: (a)** — il foglio resta pieno, e il leggendario sui posti eroe ha comunque un premio (oggi D-02 non crea blocchi leggendari sui boss eroe).
- **PQ2 — Premio sul foglio dell'aid di una dungeon.** «Il soccorritore di un'aid di dungeon, sul foglio, vede (a) la parte di premio che otterrà (es. metà se il ferito è caduto al 4° turno di 8) oppure (b) il premio pieno della dungeon, con la parte vera solo nel foglio d'esito?» **Raccomandazione: (a)** — il foglio dice la verità prima di accettare; il BE salva il premio già in proporzione sull'aid quando la crea.
- **PQ3 — Riga dei turni nel foglio d'esito.** «Nel foglio d'esito: (a) una sola riga dei turni al posto della riga delle tappe, sia per la dungeon sia per l'aid (es. «Caduto al turno 4 di 8, in esplorazione», «Ferito raggiunto al turno 4 di 8»); (b) come (a) più una riga «Premio in proporzione: 4 turni su 8» per il soccorritore; (c) i turni solo nell'aid, la dungeon tiene «Esplorazione: tappa k di N».» **Raccomandazione: (a)** — una riga, niente doppioni con le tappe; il premio ridotto si vede già nelle «Ricompense».

## Recommended plan order (dependencies and gates)

| # | Plan | Gate | Depends on | Notes |
|---|------|------|-----------|-------|
| 20-01 | Contract pins for the served block and mixed bosses (test-only or near): `Quest.fromJson` ignores an unknown `rankPrizes` key; the sheet renders exactly the served `prizes` on Board and Map (no title logic); mixed seat lines, highlight, `canRegisterWithTitle`/`isFullFor`/availability on mixed seats, k/N counter | pre-gate | — | cases likely green at first run (record the reason: contract already generic); if the alternative shape is chosen this plan becomes the selector + model plan |
| 20-02 | `QuestResult` turn fields (lenient), `DungeonTurnKind` enum with labels, `dungeonTurnLine` helper, sheet slot `:171` (turn line or stages fallback), fixtures (`dungeonResultJson` + `aidDungeonResultJson`) | pre-gate | PQ3 copy fixed in REPO-RULES; field names provisional, renamed in 20-03 if the BE differs | invisible against today's BE (fields absent → stages line as today) |
| 20-03 | Schema gate (block-anchored checks of F7) → `QuestResultFragment` selection after `stagesTotal` + document pins → schema check 46 × OK → full suite foreground, analyzer, per-file format, trailer grep | **gated on BE Phase 21 merge** | 20-01, 20-02 | if the merged names differ from 20-02, rename in this plan RED-first |
| 20-04 | Device E2E (`20-HUMAN-UAT.md`), `BACKEND-NOTES.md`, requirements mark-complete, closing docs | **gated, human checkpoint** | 20-03; BE boot by the orchestrator, seeds at DB (mixed boss, dungeon with known turn count, two characters of different titles) | parks at N−2/N like Phases 14/19 until the BE merge |

Alternative shape: insert «20-0x model + selector» and «20-0y sheet/map wiring» before 20-02, and a legacy-reader deletion in 20-03.

## Common Pitfalls

### Pitfall 1: per-viewer field on a shared WS payload
The `questUpdated` payload object is shared among subscribers; a resolver that memoises per event (not per viewer) serves the first viewer's block to everybody (BE «trappola Phase 16», `viewer-vitals.service.ts:35-36`). FE cannot detect it: device step with two characters of different titles watching the same mixed boss.

### Pitfall 2: `minTitle` vs mixed seats
`isTitleEligible` runs before seats (`quest_availability.dart:107-113`). A mixed boss with `minTitle` = boss rank tears the sheet for the lower rank and the BE refuses the acceptance. Gate/E2E: an adventurer on a paladin+adventurer boss sees «Titolo minimo: Avventuriero» and an intact sheet.

### Pitfall 3: legend without a block
D-02 + BE 13.1 D-08: legends sit on hero seats; no legend block. Without PQ1 the BE may return no block (null `prizes` → sheet without «Ricompense:») or crash resolution.

### Pitfall 4: a strict enum in `QuestResult.fromJson`
`tryFromJson` (`quest_result.dart:192-199`) swallows any throw and drops the result: the viewer would lose the whole outcome sheet for an unknown turn kind. Use `asNameMap()`.

### Pitfall 5: «turn + 1» on the FE
Do not derive «Caduto al turno N» from `turnsCleared + 1`: send the index (What the FE needs #11).

### Pitfall 6: stages line pin
`quest_result_sheet_test.dart:308-345` pins the stages copy and position; the turn line takes the same slot (`:171`) — keep the position assertion (`:319`) for the turn line and keep the stages cases for the fallback (do not delete them).

### Pitfall 7: fragment pin adjacency
`quest_result_documents_test.dart:50-63` pins `… stagesCleared stagesTotal`: append the new selections after `stagesTotal`, never between enemies and stages.

### Pitfall 8: the map sheet of a delisted quest
`world_map.dart:366-372` keeps the selected object when the quest is not in the list: a rank-up during a started quest may leave the old block on the map sheet. Known limitation; the result sheet is authoritative (D-04). Do not add a per-quest fetch for this.

### Pitfall 9: re-running the schema check against the right SDL
BE `origin/develop` moved to `fbce3e16` after the Phase 19 gate; the orchestrator aligns the ref, the plans never fetch. Validate `quests` and `OnQuestUpdated` too: they prove the hypothesis held (prizes selection still valid).

### Pitfall 10: formatter and baseline
All candidate files are clean today; format only touched files one by one; the suite count grows from 4239.

### Pitfall 11: REQUIREMENTS.md scope
`REQUIREMENTS.md` still says v1.1 = Phases 18–19; add the RANKP IDs before any plan references them (gsd-tools `requirements mark-complete` would fail on unknown IDs).

## Code Examples

### Lenient turn kind (pattern of `QuestResultQuest.type`)
```dart
// Source: lib/models/quest_result/quest_result_quest.dart:21 (pattern)
turnKind: DungeonTurnKind.values.asNameMap()[json['turnKind']],
turnsCleared: _countFrom(json['turnsCleared']),
turnsTotal: _countFrom(json['turnsTotal']),
```

### One line in the existing slot
```dart
// Source: lib/shared/components/popup/quest_result_sheet.dart:171 (today)
..._line(_stagesText(), QuestResultSheet.stagesKey),
// after: the turn line wins when the BE sends turns, else today's stages line
if (dungeonTurnLine(_result) case final turn?)
  ..._line(turn, QuestResultSheet.turnsKey)
else
  ..._line(_stagesText(), QuestResultSheet.stagesKey),
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stored `Quest.prizes`, same for everybody | Per-viewer resolved field (`noEffect` precedent) | BE Phase 18 (pattern), BE 21 (prizes) | FE reads one block, no selection |
| Dungeon stages = fights | Turns = exploration + fight, defeat possible in exploration | BE 21 D-12/D-13 | new counters, stages kept as fallback |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The BE keeps `Quest.prizes: QuestPrizes!` and resolves it per viewer | Summary, F1 | if the BE ships the alternative, +2 plans and a legacy window (F1 alternative) |
| A2 | New turn names `turnsCleared`, `turnsTotal`, `turnKind`/`turnIndex`, enum `exploration`/`fight` | F3, What the FE needs | rename in 20-03; plan 20-02 uses provisional names |
| A3 | `stagesCleared/stagesTotal` stay on the SDL | F3 | if removed: non-additive, 20-02 must drop the fallback in the gated plan |
| A4 | Archiver path sends `questCancelled` | F5 | rescuer gets no push; UAT step adjusts |
| A5 | Full suite = 4239 (not re-run) | F7 | baseline number in the gate SUMMARY only |
| A6 | Italian copy of F8 | F8 | orchestrator/user fix it in REPO-RULES |

## Open Questions (RESOLVED)

1. **Does a rank-up refresh the sheet's block?** RESOLVED: yes, `QuestScopeListener` already rereads on a title change (`quest_scope_listener.dart:68`, pin `:128`); `quests` is `noCache`.
2. **Is there a spell row to hide for non-casters?** RESOLVED: no; `spell` is not selected nor rendered (F6).
3. **Do mixed bosses need FE seat logic?** RESOLVED: no; `_slotLinesOf`/`canRegisterWithTitle` are generic; the BE must set `minTitle` = lowest seat title (What the FE needs #6).
4. **Is the FE change non-additive?** RESOLVED for the recommended shape: additive (only new `QuestResult` selections); non-additive only under the alternative.
5. **Where does the turn line go?** RESOLVED: the stages slot `quest_result_sheet.dart:171`, one line, fallback to stages (copy: PQ3).
6. **Does the FE compute the proportional prize?** RESOLVED: no; `rewards`/`xpGained` carry it; the aid sheet shows whatever `prizes` the BE stores (PQ2).
7. Open for the user: PQ1, PQ2, PQ3. Open for the BE research: final names and nullability of the turn fields, the fallback block, `minTitle` of mixed bosses, the `questCancelled` push on the archiver path. RESOLVED: CONTEXT D-18, D-20, D-21, D-22, D-25 (BE D-18..D-27).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | analyze/test | ✓ | 3.35.5 (CI pin; analyzer ran) | — |
| Node + BE `node_modules/graphql` | schema check | ✓ (used in Phase 19) | — | — |
| BE merged SDL with Phase 21 | gate plans 20-03/20-04 | ✗ (BE research in progress) | — | park at N−2/N |
| Device + BE boot | 20-04 | orchestrator/user | — | none (human checkpoint) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async` |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` (`fixtures/quest_fixtures.dart`, `fixtures/quest_result_fixtures.dart`, `test_app.dart`, `svg_cache_seed.dart`) |
| Quick run command | `flutter test <touched test files>` |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, gate plan only, timeout ≥ 300 000 ms) |
| Analyzer gate | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| Schema gate | block-anchored `awk` checks (F7) on `origin/develop:src/schema.gql` + `dump_documents.dart` / `validate_documents.js` → 46 × OK |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RANKP-01 | served block rendered as is, unknown `rankPrizes` ignored, no title logic on Board/Map | unit + widget | `flutter test test/models/quest/quest_test.dart test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart` | ✅ (add cases) |
| RANKP-01 | title change rereads quests | widget | `flutter test test/screens/mainScreen/components/quest_scope_listener_test.dart` | ✅ (existing `:128`) |
| RANKP-02 | mixed seat lines, highlight, registration per title, full for an unseated title, k/N | unit | `flutter test test/models/quest` | ✅ (add cases) |
| RANKP-03 | turn fields lenient, line copy per outcome/kind, stages fallback, slot position | unit + widget | `flutter test test/models/quest_result test/utils/quest_outcome_lines_test.dart test/shared/components/popup/quest_result_sheet_test.dart` | ✅ (add groups); `dungeon_turn_kind` test ❌ W0 if the enum is created |
| RANKP-03 | fragment selects the turn fields after `stagesTotal` | unit (document) | `flutter test test/graphql/quest_result_documents_test.dart test/tool` | ✅ (add pin) |
| RANKP-04 | gate + 46 × OK + full suite | gate | gate script + schema check + full suite | ✅ |
| RANKP-04 | device: blocks per title, mixed boss, dungeon turns, dungeon aid share, rescued freed, archiver release push | manual | `20-HUMAN-UAT.md` | ❌ (created in 20-04) |

### Sampling Rate
- **Per task commit:** touched tests + analyzer + trailer check
- **Per plan:** the test directories named in the plan
- **Phase gate:** full suite green, schema check 46 × OK, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/models/enums/dungeon_turn_kind_test.dart` (labels, lenient parse) — RANKP-03, only if the BE sends a kind
- [ ] `aidDungeonResultJson` + turn parameters of `dungeonResultJson` in `test/helpers/fixtures/quest_result_fixtures.dart` — RANKP-03
- [ ] a mixed-boss builder in `test/helpers/fixtures/quest_fixtures.dart` (seats `[paladin×2, adventurer×1]`, `minTitle: adventurer`) — RANKP-02
- No framework install, no new mock, no new harness provider.

### Device E2E outline (20-04, human)
1. Mixed boss seeded (paladin×2 + adventurer×1, `minTitle` adventurer, two blocks): paladin viewer sees two seat lines with «Paladino» highlighted and the paladin block; adventurer viewer (second character) sees the adventurer block on the same quest, intact sheet.
2. Title change of a test character at DB (orchestrator script with the BE's own `$set`) → board sheet block switches silently.
3. Win the boss → «Ricompense» = own block (coins/items/pet as drawn).
4. Dungeon defeat → «Caduto al turno k di N, in …»; «In attesa di soccorso» on the pawn.
5. Aid sheet shows the prize per PQ2; rescuer wins → turn line + proportional rewards; rescued freed (label gone).
6. Optional: archive the wounded while a rescuer is registered → rescuer lane freed + `questCancelled` push (D-16); a lost heal/job with enemies creates no aid (D-09); a non-caster never sees «Magia appresa» (D-05b).

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged |
| V3 Session Management | no | unchanged |
| V4 Access Control | yes (light) | per-viewer resolution on the BE; the FE never receives other blocks under the recommended shape (not secret data either way) |
| V5 Input Validation | yes | lenient parsing at the model boundary (`_countFrom`, `asNameMap()`, `tryFromJson`) |
| V6 Cryptography | no | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed/unknown turn kind drops the result sheet | DoS | lenient enum → null; pinned test |
| Negative or absurd counters printed | Tampering | `_countFrom` + line hidden when `turnsTotal` null; no arithmetic on the FE |
| Wrong viewer's block on a shared WS event | Information disclosure (minor) | BE memo per viewer per event; device two-character step |
| Logging prize payloads | Information disclosure | no new `appLog`; `hardening_check.sh` keeps guarding `print` |

## Sources

### Primary (HIGH confidence)
- Codebase `feat/20-rank-specific-prizes` `1e5f3028`: files cited inline.
- BE read-only: `src/schema.gql` (= `origin/develop` `fbce3e16`), `src/quests/no-effect/quest-no-effect.resolver.ts`, `viewer-vitals.service.ts`, `src/quests/acceptance/quest-capacity.ts`, `quest-eligibility.ts`, `src/quests/outcomes/aid/aid-quest.ts`, `rescue-plan.ts`, `outcome-plan.ts`, `dungeon/placeholder-dungeon-resolver.ts`, `party/party-timeout.service.ts`, character archiver, `generation/generated-quest-draft.ts`, `generated-prizes.ts`; `.planning/phases/21-premi-per-rango-e-soccorsi/21-CONTEXT.md`, `21-REPO-RULES.md`.
- `20-CONTEXT.md`, `20-DISCUSSION-LOG.md`, `19-RESEARCH.md`, `19-REPO-RULES.md`, `19-VALIDATION.md`, `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `docs/rules/*.md`.

### Secondary / Tertiary
- None (no web sources needed: the domain is this codebase and its BE).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — nothing new.
- Architecture: HIGH for the FE map; MEDIUM for the plan count (depends on the BE shape).
- Pitfalls: HIGH — each tied to a file:line.

**Research date:** 2026-11-13
**Valid until:** the BE Phase 21 research fixes the SDL (then refresh the names in `20-REPO-RULES.md`).
