# Phase 14: Quest Generation (frontend companion) - Context

**Gathered:** 2026-11-04 (joint interactive discuss with the BE Phase 13, from this repo; branch `feat/14-quest-generation` from `develop` `9993a3c`, the merge of PR #37)
**Status:** Ready for planning — no UI phase, no UI-SPEC (every visual is provisional, user-reviewed on the device); the plans that select the new contract names and the device E2E are **gated by the BE Phase 13 merge** on BE `develop` (pattern 08-12 / 09-12 / 13-10 / 13-11); every other plan runs before it on mocks and fixtures with the names fixed in the BE CONTEXT.

<domain>
## Phase Boundary

The board and the result sheet speak the new multi-enemy contract of the BE Phase 13 — `infos.enemies: [{ enemy, quantity }]` replaces `infos.enemy`, `QuestResult.enemies` + `stagesCleared`/`stagesTotal` replace `QuestResult.enemy` — and the innkeeper can force the generator from the «Locanda» («Genera missioni», BE `generateQuests`); generated quests look like any other quest and the frontend never generates, filters or balances anything itself. The phase also consumes three additive pieces of the same BE contract decided in the joint discuss: the quest **announcement** (`infos.description`, BE Phase 11 D-32) shown on the sheet, the **companion prize** (`prizes.pet`, `rewards.pet`) shown as a line, and the jewels' **`accessoryUseTypes`** shown on the item sheet. Fixed `crime`/`guard`/`dungeon` quests keep rendering with their families (QGEN-04).

Out of scope: darkening unknown enemies (Phase 17), live board refresh when quests are inserted (the board reloads on tab open), food (Phase 15), ambush results (Phase 16, same sheet), any client-side generation or filtering, filters or equip constraints on `accessoryUseTypes`, combat rules.

</domain>

<decisions>
## Implementation Decisions

### Contract consumed (QGEN-01, QGEN-02, QGEN-06)
- **D-01 (BE Phase 13 CONTEXT D-01/D-12/D-21/D-24, names final in the BE handoff):** `QuestInfos.enemies: List<QuestEnemy>` with `QuestEnemy { enemy, quantity }` replaces `enemy` in the model, `toJson`/`copyWith`/`props`, the fixtures and `QuestFragment` (`infos { … enemies { quantity enemy { id name imagePath xp } } }`; `xp` is selected only to pick the strongest enemy for the portrait, D-02); the single `enemy` selection disappears from every document (registry and schema check green against the merged BE schema). `QuestResult.enemies` (same shape), `stagesCleared`, `stagesTotal` (nullable, dungeon only) replace `QuestResult.enemy` in `QuestResultFragment` and the model. Additive: `QuestInfos.description`, `QuestPrizes.pet`, `QuestRewards.pet` (field name from the BE handoff), `EquipmentItem.accessoryUseTypes` (`List<AccessoryUseType>?`, enum `attack | defense`), mutation `generateQuests` (returns `{ created }`). Parsing stays tolerant like Phase 13: a malformed `enemies` entry makes `Quest.tryFromJson` skip the quest, not the board.

### Quest sheet, combat family (QGEN-01, QGEN-05)
- **D-02 (user decision):** **one portrait + lines with quantities**: the left column keeps a single portrait — the **strongest enemy** of the list (highest `xp`) — and under it one line per type in the «Nx nome» format already used by the «Consigliati» lines («3x Goblin», «1x Capo goblin»); a quest with one enemy and quantity 1 renders as today. `AutoSizeText` sizing and ordering (strongest first) at Claude's discretion.
- **D-03 (user decision):** the portrait is **loaded from the network and hidden when missing**: `imagePath` is read with the app's Cloudinary convention for remote images (cached through `flutter_cache_manager`); when the path is not resolvable or the download fails only the name stays, exactly as today (the known IN-03 defect: `Image.asset` with a server path never renders). The same rule serves the result sheet (D-06) and prepares Phase 17. The user fills the real images at the DB later (BE Phase 11 D-24).
- **D-04 (user decision):** «**Consigliati**» (`recommendedLoot`) is shown **in the combat body too**, under the enemy lines in the left column, omitted when the list is empty (BE Phase 11 D-33: hunt, dungeon and the new enemy/boss quests carry weapons against weaknesses, food and exploration items).
- **D-05 (user decision):** the **announcement** `infos.description` is shown **under the title in all three families** (combat, service, narrative), italic, scrollable when long, omitted when null; the fragment gains `description`. Nothing else of the sheet moves.
- **D-06 (technical default, for the veto):** when `prizes.pet` is set the prizes block shows a line «Compagno in premio: <nome>» (copy provisional); no image.

### Result sheet (QGEN-02)
- **D-07 (user decision):** the single enemy block becomes the **list of the enemies fought** («3x Goblin» lines with the portrait of the strongest, D-02/D-03 rules, `QuestResultSheet.enemyKey` kept on the block); for a **dungeon** (`stagesTotal` set) one more line «Esplorazione: tappa k di N» (`stagesCleared` of `stagesTotal`; a victory shows all the stages). When `rewards.pet` is set the rewards section shows «Compagno ottenuto: <nome>» (technical default, copy provisional). Ambush outcomes (Phase 16) reuse the same list.

### «Genera missioni» in the Locanda (QGEN-03)
- **D-08 (user decision):** the button sits **at the top of the list** on the parchment of the innkeeper panel, **always visible** (also with «Nessuna richiesta in attesa»), above the request cards.
- **D-09 (user decision — «Dialog + SnackBar»):** tap → the shared confirmation dialog (`showDestructiveConfirmation`, neutral style like the completion form) «Generare nuove missioni nel mondo?» with «Genera» / «Annulla»; the outcome goes in a **SnackBar** like the other panel actions: «Generate N missioni» or «Nessuna missione da generare» (0); network / timeout / unknown failures in a SnackBar too; **`FORBIDDEN` closes the panel** with «La Locanda non è disponibile» exactly like Phase 10 D-04 (the ROADMAP's «mapped inline» is read as «handled in the panel»). The button is disabled while the call is in flight.
- **D-10 (technical default):** a dedicated cubit (e.g. `QuestGenerationCubit`: idle → submitting → succeeded{created} / failed{failure, serial}) provided by the panel route, `InnkeeperRepository.generateQuests()` with the 15 s timeout and the existing `innkeeperFailureFrom` classifier; the mutation document `GenerateQuests` enters the schema-check registry (`tool/schema_check/schema_check_documents.dart`) and its test.

### Fixed types (QGEN-04)
- **D-11 (technical default):** `questSheetFamilyOf` already maps `crime`/`guard` to the service family and `dungeon` to combat: QGEN-04 is satisfied by the mapping and proven by the existing per-type widget tests; the research checks what renders for the **empty `imagePath`** of the `crime`/`guard` pawn and the state label («In corso…») and the planner adds a fix only if something breaks on the device. No alignment mechanic.

### Jewels (QGEN-06, user rule of 2026-11-04)
- **D-12 (user decision):** `EquipmentItem.accessoryUseTypes` enters the model and the equipment fragment; the **item sheet** (Journal and shop) shows one line **«Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa»** only for rings and necklaces (`equipType` ring/necklace), nothing for the other pieces; **no filter, no equip constraint, no icon in the lists**. The combat semantics belong to the BE engine (BE D-24).

### Gating, tests and hygiene
- **D-13 (technical default):** plans before the BE merge build models, fragments, sheets, cubit and Locanda on mocks with the BE CONTEXT names; the schema gate (`origin/develop:src/schema.gql`, dump + validate of every document, full suite, analyzer) and the device E2E (`14-HUMAN-UAT.md`, human checkpoint) run after the BE PR merges; handoff `BACKEND-NOTES.md` closes the phase. TDD red → green → refactor for every change (parsing of `enemies`/`stages`/`pet`/`accessoryUseTypes`, strongest-enemy selection, lines, dialog + SnackBar flow, classifier, registry); `dart format` only on touched files; analyzer compared with the `develop` baseline (error/warning only); no `Co-Authored-By` trailer.

### Claude's Discretion
- Copy of every new line and SnackBar (provisional), exact spacing in the combat body, the cubit and widget names, fixture shapes, how `imagePath` maps to a Cloudinary URL (research on the existing remote-image helpers), whether `generated` quests need any visual mark (no: the user wants them to look like any other quest).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### BE contract (companion phase)
- `../Klimmeck-Guide-BE/.planning/phases/13-generazione-quest/13-CONTEXT.md` — D-01 (`enemies`, `QuestResult.enemies`, `stagesCleared`/`stagesTotal`), D-12 (dungeon stages), D-16 (`generateQuests`), D-18 (no `questUpdated` on insert), D-21 (`prizes.pet`, rewards), D-22 (`infos.description` on generated quests), D-24 (`accessoryUseTypes`)
- `../Klimmeck-Guide-BE/.planning/phases/13-generazione-quest/BACKEND-NOTES.md` — written by the BE phase: final SDL, error codes, populate rules (read before the gated plans)
- `../Klimmeck-Guide-BE/.planning/phases/11-popolamento-del-mondo/BACKEND-NOTES.md` §9 — `QuestInfos.description` (announcement), D-33 `recommendedLoot` on combat quests

### Prior FE decisions carried forward
- `.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` D-09 (three layout families), D-10 (eligibility lines), D-19 (no UI phase), D-20 (populate gaps)
- `.planning/phases/09-combat-result-sheet/09-CONTEXT.md` D-03 (result sheet content and order), D-04 (one widget for every outcome), D-17 (aid in the combat family); `09-RESEARCH.md:197` (IN-03 replicated on purpose — superseded by D-03 here)
- `.planning/phases/10-admin-panel-innkeeper/10-CONTEXT.md` D-01 (utility surface), D-04 (`FORBIDDEN` pops the panel), D-11 (confirmation dialog), D-14 (per-code errors inline/SnackBar)
- `.planning/phases/13-city-shops/13-CONTEXT.md` D-16 (no device run before the gated plans), D-17 (companion dropdown); `13-10-SUMMARY.md` (schema gate procedure), `13-11-PLAN.md` (device E2E + handoff shape), `13-REPO-RULES.md`
- `.planning/phases/13-city-shops/BACKEND-NOTES.md` §5.1 — unpopulated nested refs under `me.currentCharacter` (no app impact; never select `enemies[].enemy.relatedLore`)

### Rules
- `docs/rules/graphql.md`, `docs/rules/state-management.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/naming.md`, `docs/rules/architecture.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/models/quest/quest_infos.dart` (`enemy` :20, `fromJson` :28, `toJson` :42), `lib/models/quest/quest.dart` (`tryFromJson` :36-45), `lib/models/enemy.dart`, `lib/models/enums/quest_type.dart` (`label`), `lib/models/quest/quest_sheet_details.dart` (`questSheetFamilyOf` :19-27, `recommendedLootLines` :89-93 — the «Nx nome» format), `quest_lane.dart` (`registeredQuestTypes`, `nonRepeatableQuestTypes`)
- `lib/graphql/fragments/quest_fragment.dart:19-23` (`infos { … enemy { id name imagePath } }`), `quest_result_fragment.dart:80-84` (`enemy`), `pending_request_fragment.dart` (no enemy), `tool/schema_check/schema_check_documents.dart` (registry, 43 documents) + `test/tool/schema_check_documents_test.dart`, `tool/schema_check/dump_documents.dart`, `validate_documents.js`
- `lib/shared/components/popup/quest_info_sheet.dart` (`_combatBody` :147-188 single portrait + name; `_serviceBody` «Consigliati» :220-224; family switch :113-117), `lib/shared/components/popup/quest_result_sheet.dart` (`_enemy()` :223-247, `enemyKey` :35, composition :144-163, `_consumables` as a quantity-line pattern)
- `lib/models/quest_result/quest_result.dart` (`_enemyFrom` :149-158, `assetQuantitiesFrom` :129-137 as a `{quantity, item}` parsing model), `test/helpers/fixtures/quest_fixtures.dart` (`questJson(enemy:)`), `quest_result_fixtures.dart` (`hasEnemy`)
- Locanda: `lib/screens/innkeeper/innkeeper_panel_screen.dart` (Scaffold + AppBar + parchment list :126-162, SnackBar messages :30-38/:82-88/:106-121), `innkeeper_panel_route.dart` (providers), `lib/repository/innkeeper_repository.dart` (`_guard`, 15 s timeout), `lib/repository/innkeeper_failure.dart` (classifier), `lib/shared/components/modal/destructive_confirmation_dialog.dart` (`showDestructiveConfirmation`), `request_completion_screen.dart:192-202` (confirm → submit pattern), `requestCompletionCubit/` (idle/submitting/succeeded/failed with `failureSerial`)
- Item sheets and rows of the Journal/shop (Phase 8/13: `ItemRow`, item detail sheet) for the «Uso» line; `lib/models/enums/equip_type.dart`

### Established Patterns
- Hard replacement of a wire field with gated plans (08-12 / 09-12 / 13-10): documents and models aligned on mocks first, schema check after the BE merge
- Tolerant parsing per item (`tryFromJson`, skip malformed entries) — Phase 9 IN-04, Phase 13
- Failure classifier per repository reading `extensions.code`; utility surfaces may use `SnackBar` and inline text (Phase 10 D-14); gameplay surfaces use the parchment banner
- `BlocConsumer` with a `failureSerial` to re-emit the same code; buttons disabled while submitting
- No UI phase: provisional visuals built from the CONTEXT, token-based (`kg_theme.dart`)

### Integration Points
- `QuestFragment.fields` is shared by the `quests` query and the `OnQuestUpdated` subscription — one change serves both
- `QuestResultFragment` is used by `questResult`, `unacknowledgedQuestResults`, `questResultReceived` and `CompletePendingRequest`
- `InnkeeperRepository` + panel route providers for the new cubit; `schemaCheckDocuments` registry for `GenerateQuests`
- `PageView` of `MainScreen` keeps no off-screen tab alive: the board reloads on every tab open (new generated quests appear then)

</code_context>

<specifics>
## Specific Ideas

- User 2026-11-04 (joint discuss, BE side) on the boss: «Boss è un nemico molto forte per il rango e livello richiesto dagli avventurieri. I mostri leggendari sono ad uso esclusivo delle worldMission» — the FE renders boss quests like any combat quest with party slots.
- User 2026-11-04 on the dungeon: the exploration algorithm is theirs; the FE shows only «Esplorazione: tappa k di N» from the BE counters.
- User 2026-11-04 on the jewels (verbatim, recorded in the BE CONTEXT D-23/D-25): `accessoryUseTypes` with `attack` / `defense`; FE shows the «Uso» line only.
- Facts behind the choices: the combat sheet shows a single enemy whose image never loads (IN-03); «Consigliati» lives only in the service body; `crime`/`guard` already fall in the service family, `dungeon` in combat; the Locanda has no action besides the request cards; the registry test forces every new operation into `schemaCheckDocuments`.

</specifics>

<deferred>
## Deferred Ideas

- **Darkened portrait and name-only for unknown enemies** — Phase 17 (Unlockable Lore), on top of D-03.
- **Live board refresh on generated inserts** — BE D-18 says inserts do not emit `questUpdated`; the board reloads on tab open. Revisit if the stream experience needs it.
- **Companion prize beyond a text line** (image, dedicated sheet) — later, with the pet images.
- **State labels for `crime`/`guard`** («In corso…» today) — Claude's call during the phase, not a requirement.
- **Any mark distinguishing generated quests** — rejected by the goal: generated quests look like any other quest.
- **Alignment (good/evil) for `crime`/`guard`** — v2.

</deferred>

---

*Phase: 14-quest-generation*
*Context gathered: 2026-11-04*
