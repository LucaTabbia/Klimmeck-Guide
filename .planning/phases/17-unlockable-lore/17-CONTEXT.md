# Phase 17: Unlockable Lore - Context

**Gathered:** 2026-11-07 (joint interactive discuss with the BE Phase 16, from this repo; branch `feat/17-unlockable-lore` from `develop` `f560d1d`, the merge of PR #41; the FE Phase 16 is parked at 7/8 on its own branch, its device E2E runs at the end of this phase)
**Status:** Ready for planning — no UI phase, no UI-SPEC (every visual is provisional, user-reviewed on the device); the plans that select the new contract names (`CharacterStatus.unlockedLore`, `QuestEnemy.known`, `QuestResult.loreUnlocked`) and the device E2E are **gated by the BE Phase 16 merge** on BE `develop` (pattern 13-10 / 14-10 / 15-08 / 16-07); every other plan runs before it on mocks and fixtures with the names fixed in the BE CONTEXT (`../Klimmeck-Guide-BE/.planning/phases/16-lore-sbloccabili/16-CONTEXT.md`) and its `16-REPO-RULES.md` (written at plan time, before the research).

<domain>
## Phase Boundary

Knowledge belongs to the character and lives in the backend. The Library renders only the lore the backend returns for the bearer's current character (`lores` is server-filtered), refreshes itself while open when the character's unlocked set changes (ids on the Character subscription), hides the sections of a book with nothing unlocked, shows one status line for an empty book and marks with a «Nuovo» bookmark the entries unlocked since the last opening of that book. On the quest and result sheets an enemy the character has never defeated (the exact enemy, not its species) shows its portrait as a full black silhouette with the name lines unchanged; the flag comes from the backend (`known`), the FE computes nothing. The result sheet lists the lore unlocked by that outcome («Conoscenza appresa: <name>» for the study roll, «Nuova pagina del Bestiario: <name>» for a first victory). On the Map a city the character has not visited opens a name-only modal («Non conosci ancora questa città.») because the backend resolves `City.relatedLore` to null for players until the city is known. A new character starts with the geography of the home city (city lore + its regions + its state); deleting and recreating the character resets everything (new Character document, nothing to do on the FE).

Out of scope: any client-side unlock logic (what is known is the backend's word), lore hyperlinks between entries (v2), filtering the narrative lore paragraphs of quest sheets (the quest text is the commissioner's voice and stays whole), changes to the Bestiario/Luoghi/Religioni/Conoscenze book structure, a lore detail page, GM views, images for non-city lore (data, not this phase).

</domain>

<decisions>
## Implementation Decisions

### Contract consumed (LORE-01, LORE-02, LORE-03)
- **D-01 (user decision, «Lista di id sul personaggio»):** the character carries its knowledge: `CharacterStatus.unlockedLore: [ID!]!` (ids only, no populate) on the Character subscription and queries; the FE parses it into `CharacterStatus.unlockedLore` (`List<String>`, order irrelevant, duplicates impossible) and uses it ONLY to know *when* and *what* changed (refetch trigger, «Nuovo» marks). The known-enemies set stays internal to the BE (never on the wire). Names are technical defaults to be fixed in the BE `16-REPO-RULES.md`.
- **D-02 (BE Phase 16 D-05/D-06):** `lores` and `lore(id)` return only the unlocked lore of the bearer's current character (nested `relatedLore` filtered the same way; a locked `lore(id)` is `NOT_FOUND`, same code as a missing one); the innkeeper sees everything. **The dev-bypass account is the innkeeper**: the device E2E needs a player identity (second identity via env on the BE process, as on 2026-11-01), written in `17-HUMAN-UAT.md`.
- **D-03 (user decision, «Solo il nemico esatto sconfitto»):** `QuestEnemy.known: Boolean!` on `Quest.infos.enemies[]` and `QuestResult.enemies[]`, resolved per viewer by the BE = the exact enemy id is among the character's defeated enemies (a Goblin victory does not reveal the Goblin boss, even if they share the «Goblin» bestiary page). The FE model `QuestEnemy` gains `known` (strict on the board as today: a malformed entry drops the quest; lenient on results); `Enemy` itself does not change.
- **D-04 (user decision, «Studio e prima pagina del bestiario»):** `QuestResult.loreUnlocked: [Lore!]!` = only the lore newly unlocked by that outcome (study roll or first victory on a species); the FE selects `{ id name type }` into a small `LoreRef`/equivalent model (lenient: malformed entries dropped, the result stays).

### Library (LORE-01)
- **D-05 (user decision, «Lista di id» → live refresh):** `LibraryCubit` refetches `lores` when the set of `unlockedLore` ids of the current character changes while a book is open (compare sets, not lengths or order; ignore every other Character change); the data page recomputes its per-type lists from the new state (today `_loreLists` is built in `initState` only); no refetch on HP ticks. Offline or failed refetch: keep the page shown, no error page mid-session (rule 2: no blocking loading in session; a silent retry on the next change).
- **D-06 (technical default, stated in the question):** a dropdown section (type) with no unlocked entry is **hidden**; a book with nothing unlocked shows **one status line** on the parchment in place of the sections (copy Claude's discretion, in-world, e.g. «Le pagine di questo libro sono ancora bianche.»); the four books and their type mapping (`library_initial_page.dart`) do not change.
- **D-07 (user decision, «Segnalibro Nuovo»):** entries unlocked since the **last opening of that book** carry a «Nuovo» bookmark/ribbon on the card until the book is reopened; baseline = the set of ids shown at the previous opening of the same book, persisted on the device per character (`shared_preferences`, key by character id + book, pattern of `SharedPreferencesNotificationPreferencesStore`); entries arriving live while the book is open are marked too; **no baseline (first opening ever for this character) → no marks** (the birth geography is not «new»); recreating the character changes the id → fresh baseline. Pure UI convenience, never sent to the BE.

### Enemy portraits (LORE-02)
- **D-08 (user decision, «Silhouette nera»):** an unknown enemy's portrait renders as a **full black silhouette** of its shape (alpha of the SVG or raster, e.g. `ColorFiltered` with `BlendMode.srcIn` over the existing `EnemyPortrait`, ink color from the theme), same size and placement as today; the «Nx nome» lines and the recommended loot do not change; semantics label distinguishes the two states. `EnemyPortrait` (already annotated «la Phase 17 lo scurirà») takes the flag; the portrait of the strongest enemy follows **that enemy's** `known`. No portrait path → nothing, as today.
- **D-09:** result sheet after a victory: the enemies just defeated are known (the BE writes the knowledge in the same transaction as the result) → portrait in clear; after a defeat, rescue or death → silhouette stays. Ambush sheets (Phase 16 carousel) reuse the same block and inherit the rule. Board staleness: a quest card already fetched keeps `known: false` until the board rereads (the BE resolves the flag per read); accepted, noted in BACKEND-NOTES.

### Result sheet lines (LORE-02)
- **D-10 (user decision):** after «Magia appresa» the sheet renders one line per `loreUnlocked` entry, in BE order: lore of the Bestiario types (`enemy`, `animal`, `plant`) → **«Nuova pagina del Bestiario: <name>»**; any other type → **«Conoscenza appresa: <name>»**; empty list → no line (defeats, repeats, geography never produce lines: arrivals have no sheet). Copy is Claude's discretion.

### Map (LORE-03)
- **D-11 (user decision, «Mappa: solo il nome; quest intere»):** `City.relatedLore` is null for a player until the city is known; tapping such a city opens the same paper modal with the city **name** and one line «Non conosci ancora questa città.» (no image, no description) instead of calling `lore(id)` (today `city.relatedLore!.id` would crash); known cities behave as today. Teleport mode unchanged (cities are targets, no lore). The narrative quest sheets keep their lore paragraphs whole.

### Technical defaults (for the veto)
- **D-12:** models: `CharacterStatus.unlockedLore` (`List<String>`), `QuestEnemy.known` (`bool`), `QuestResult.loreUnlocked` (`List<LoreRef>` with `id`, `name`, `type`), fixtures beside the Phase 9/14 ones; `CharacterFragment.statusFields` selects `unlockedLore`; `QuestFragment` and `QuestResultFragment` select `known` under `enemy`-level entries (`enemies { quantity known enemy { … } }`) and `loreUnlocked { id name type }`; `CityQueries.getAllCities` keeps `relatedLore { id description image }` (nullable already); the lore queries do not change (registry stays at 45 documents unless the planner needs one; the count test is updated in the same commit if so); Library: `LibraryCubit` subscribes to the `CharacterCubit` stream (or receives the ids from the shell) and a `LibraryBookmarksStore` (or equivalent) in `lib/repository/storage/`; `EnemyPortrait.known`/`silhouette`; `QuestResultSheet` lines with keys like the existing ones; tests mirror Phase 9/15/16 conventions (`fakeAsync`, `useSvgHttpOverrides()` + seeded SVGs, `[lat, lng]` fixtures); `dart format` only on touched files; analyzer compared with the `develop` baseline; no `Co-Authored-By` trailer.
- **D-13 (gating, pattern 13-10 / 14-10 / 15-08 / 16-07):** plans before the BE merge build models, parsing, Library behaviour, silhouette, sheet lines and the Map modal on fixtures and mocks with the names of the BE CONTEXT/REPO-RULES; after the merge: the schema gate (`origin/develop:src/schema.gql` fetched over HTTPS when the SSH agent is dead, dump + validate of every document, full suite, repo-wide analyzer) and the device E2E (`17-HUMAN-UAT.md`, human checkpoint, player identity: new character → Library shows the home city, its regions and its state only, the other books empty; travel to a new city → its page appears live with «Nuovo»; tap an unknown city on the Map → name only; a quest with an unknown enemy → silhouette; win → portrait in clear on the result sheet + «Nuova pagina del Bestiario»; a study → «Conoscenza appresa» half of the time; delete and recreate → reset; DB tricks from the BE handoff); the Phase 16 device E2E (16-08) runs in the same session from the APK of `feat/16-travel-ambushes`; handoff `BACKEND-NOTES.md` closes the phase.
- **D-14:** once the fragments select the new fields, every Character/Quest/QuestResult read fails validation on a BE without Phase 16: the branch is never run against the old BE; the device E2E runs only after the BE merge (D-13); BACKEND-NOTES says so.

### Claude's Discretion
- Copy of the status line, the «Nuovo» mark, the Map line and the result lines; the bookmark's look; the silhouette ink; the refetch debounce; where the id comparison lives (cubit vs shell); fixture names; whether `LoreRef` reuses `Lore` with nullable fields or is its own class; the store's key shape; the test harness for the live refresh.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### BE contract (companion phase)
- `../Klimmeck-Guide-BE/.planning/phases/16-lore-sbloccabili/16-CONTEXT.md` — D-01..D-04 (sets on the character, ids on the wire, geography at birth and arrival, exact-enemy knowledge), D-05/D-06 (filtered queries, `City.relatedLore` null, `known`), D-07 (study roll 50 %), D-08 (`loreUnlocked`), D-10 (backfill of the existing characters)
- `../Klimmeck-Guide-BE/.planning/phases/16-lore-sbloccabili/BACKEND-NOTES.md` — written by the BE phase: final SDL, UAT data and identity (read before the gated plans)
- `../Klimmeck-Guide-BE/.planning/phases/11-popolamento-del-mondo/BACKEND-NOTES.md` — lore data (473 entries: 167 cities with image, 116 bestiary pages, 54 animals, 17 regions, 8 states…), D-25 (no `unlocked` flag)

### Prior FE decisions carried forward
- `.planning/phases/16-travel-ambushes/16-CONTEXT.md` D-09/D-14/D-15 (gating and the never-run-against-old-BE rule), `16-REPO-RULES.md` (model for `17-REPO-RULES.md`), `16-07-PLAN.md` (schema gate), `16-08-PLAN.md` (device E2E + handoff shape) — **on the `feat/16-travel-ambushes` branch** until its PR merges (read them with `git show feat/16-travel-ambushes:<path>`); on `develop` the same patterns are in `.planning/phases/15-travel-food/15-CONTEXT.md` D-09, `15-REPO-RULES.md`, `15-08-PLAN.md`, `15-09-PLAN.md`
- `.planning/phases/14-quest-generation/14-CONTEXT.md` D-01..D-03 (`enemies` entries, strongest-enemy portrait, `EnemyPortrait`), `.planning/phases/09-combat-result-sheet/09-CONTEXT.md` (sheet sections, «Magia appresa» line, FIFO queue)
- `.planning/phases/13-city-shops/13-CONTEXT.md` D-17 (dropdown + parchment entries pattern), `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` (per-user `shared_preferences` store pattern)
- `.planning/phases/07-travel/07-CONTEXT.md` (Map modals, city markers), `.planning/phases/10-admin-panel-innkeeper/10-CONTEXT.md` C14 (teleport mode: cities without lore)

### Rules
- `docs/rules/graphql.md`, `docs/rules/state-management.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/naming.md`, `docs/rules/architecture.md`, `docs/rules/assets.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Library: `lib/screens/mainScreen/tabs/library/library.dart` (four books → `LoreType` lists, `LibraryCubit.loadLoreData` on tap), `cubit/library_cubit.dart` + `library_state.dart` (`LibraryInitial/Loading/LoadData/Error`, provided in `authenticated_shell.dart` :153), `statesPages/library_initial_page.dart` (Bestiario = enemy/animal/plant, Luoghi = city/region/state, Religioni = religion/ceremony/god, Conoscenze = character/knowledge/material), `statesPages/library_data_page.dart` (`Dropdown` per type, `_LoreList` → `LoreCard`; lists computed in `initState`), `components/lore_card.dart` (name, description, 200×200 SVG when `image` set)
- Lore: `lib/models/lore.dart` (`type` parsed by name from the wire `String!`), `lib/models/enums/lore_type.dart` (12 types with Italian labels), `lib/graphql/queries/lore_queries.dart` (`lores`, `lore(id)`, fields `id image type name description relatedLore { id name }`), `test/graphql/lore_documents_test.dart` (pins «without unlocked», BE Phase 11 D-25)
- Enemies on sheets: `lib/shared/components/enemy_portrait.dart` (`canShow`, SVG via `CachedSvg`, raster via `CachedNetworkImage`; doc: «la Phase 17 lo scurirà»), `lib/utils/enemy_portrait_url.dart`, `lib/models/quest/quest_enemy.dart` (`QuestEnemy.fromJson` strict, `lenientListFrom`, `enemyLinesOf`, `strongestEnemyOf`), `lib/models/quest/quest_sheet_details.dart` :79-114 (`enemyLines`, `strongestEnemy`, `loreParagraphs` from `infos.relatedLore`), `lib/shared/components/popup/quest_info_sheet.dart` :213-243 (`_enemyColumn`), `lib/shared/components/popup/quest_result_sheet.dart` :253-275 (`_enemies`), :446-449 (`_spellLearnedText` «Magia appresa: …»)
- Character: `lib/graphql/fragments/character_fragment.dart` (`statusFields` :26-69), `lib/models/character/character_status.dart` (nullable fields, `spellStates`/`awaitingAid` as additive precedents), `CharacterCubit` (`CharacterLoaded.character`)
- Map: `lib/screens/mainScreen/tabs/map/world_map.dart` :182-188 (`WorldMapLoadData` → `_showCityInfoModal`), :441-442 (`_openCityLore` with `city.relatedLore!.id`), :635-647 (`PaperSheetModal(child: CityModal(lore))`), `components/city_modal.dart`, `cubit/world_map_cubit.dart` (`loadLoreData` → `getLoreById`), `layers/city_markers_layer.dart` (`onCityTap`, null in teleport mode), `lib/graphql/queries/city_queries.dart` (`relatedLore { id description image }`), `lib/models/city.dart` (`Lore? relatedLore`)
- Storage: `lib/repository/storage/notification_preferences_store.dart` (abstract interface + `SharedPreferences` implementation, per-user keys), `active_user_store.dart`
- Results: `lib/models/quest_result/quest_result.dart` (`spellLearned` parsed with `_spellFrom`, `tryFromJson`, fixtures), `lib/graphql/fragments/quest_result_fragment.dart` :89-96 (`enemies { quantity enemy { id name imagePath xp } }`), `quest_fragment.dart` :21-34

### Established Patterns
- Additive, tolerant parsing of new Character fields (`spellStates`, `awaitingAid`: null when absent); strict quest parsing on the board (a malformed entry drops the quest, never the board), lenient on results
- Gated plans after the BE companion merge: schema check `tool/schema_check` (45 documents registered in `schemaCheckDocuments`, three count tests at 45), full suite, analyzer vs the `develop` baseline (0 error / 0 warning / 50 info on 2026-11-07)
- Cubits with `SafeEmit`, states Equatable; widgets render only prepared details (`QuestSheetDetails`); `showGeneralDialog`/`PaperSheetModal` for sheets; SVGs through `CachedSvg` and tests seeding `useSvgHttpOverrides()`
- Per-user device preferences through an abstract store + `SharedPreferences` implementation injected in the shell

### Integration Points
- `authenticated_shell.dart` :151-153 provides `WorldMapCubit` and `LibraryCubit` with the GraphQL client: the Library refresh needs the `CharacterCubit` (already in the shell) or the ids passed down
- `QuestEnemy`/`Enemy` are shared by the board, the quest sheet, the result sheet and the ambush carousel: `known` travels with the `QuestEnemy` entry (not on `Enemy`, which the shop/library never show)
- `CityQueries.getAllCities` feeds `WorldMapCubit`/markers: `relatedLore` null must not drop the city (check `City.fromJson`)
- Document registry: new selections change document texts, not their count; the count tests (45) stay unless a document is added

</code_context>

<specifics>
## Specific Ideas

- The bestiary page «Goblin» opens after beating any goblin (Enemy.relatedLore), but the Goblin boss portrait stays a silhouette until that exact boss is beaten (user: «Solo il nemico esatto sconfitto»)
- «Nuovo» as a small bookmark ribbon on the lore card, in the ink of the book's bookmark colour; cleared at the next opening of that book
- The empty-book line sits where the sections would be, same parchment, no second screen
- Unknown city modal: the paper sheet with the city name and «Non conosci ancora questa città.», nothing else; it must not crash when `relatedLore` is null (latent bug today)
- The study teaches a random locked lore half of the time (BE `LORE_STUDY_CHANCE` default 0,5): the UAT seeds the roll or repeats

</specifics>

<deferred>
## Deferred Ideas

- Lore hyperlinks between entries (v2 in PROJECT.md)
- A lore detail/zoom page, images for non-city lore (data work)
- Filtering the narrative quest paragraphs by knowledge (rejected: the quest text is the commissioner's voice)
- Knowing the species instead of the exact enemy (rejected by the user)
- Showing «Nuovo» pages on the book covers of the initial page (count badges) — not asked, not planned
- Common knowledge shared by every character (no `Lore.unlocked` flag exists since BE Phase 11 D-25; nothing is common)

</deferred>

---

*Phase: 17-unlockable-lore*
*Context gathered: 2026-11-07*
