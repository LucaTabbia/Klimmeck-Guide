# Roadmap: Klimmeck Guide

**Created:** 2026-04-10
**Last updated:** 2026-11-11 — Phase 19 Model Review (companion) complete: both phases of v1.1 Healing & Models are done, the milestone close is next; v1.0 Core Loop archived in `milestones/v1.0-ROADMAP.md`
**Milestone:** v1.1 Healing & Models — Phases 18–21 (companion of the BE milestone v1.1 «Cura e modelli», BE Phases 18–20)

## Milestones

- ✅ **v1.0 Core Loop** — Phases 1–17 (shipped 2026-11-10) — [roadmap archive](milestones/v1.0-ROADMAP.md) · [requirements archive](milestones/v1.0-REQUIREMENTS.md) · [summary](MILESTONES.md)
- 🚧 **v1.1 Healing & Models** — Phases 18–23 (started 2026-11-10; Phase 23 — spell origins, void and shamanic quests — added 2026-11-15 and complete 2026-11-16; Phase 22 — companion defeat, rest and recovery — added 2026-11-14 and complete 2026-11-15; Phases 18–19 complete 2026-11-11; Phase 20 — rank-specific prizes for group quests — and Phase 21 — innkeeper mission completion flow — added 2026-11-11; Phase 20 planned and complete 2026-11-13, Phase 21 planned and complete 2026-11-14) — heal quests by city size with the Journal potions (↔ BE Phase 18) and the model review companion (↔ BE Phase 19); BE Phase 20 (progressive travel food and life) has no FE phase

## Phases

<details>
<summary>✅ v1.0 Core Loop (Phases 1–17) — SHIPPED 2026-11-10</summary>

- [x] Phase 1: Dev Auth Stub (3/3 plans) — completed 2026-04-15
- [x] Phase 2: Character Creation (11/11 plans) — completed 2026-10-09
- [x] Phase 3: Real-Time Sync Foundation (9/9 plans) — completed 2026-10-14
- [x] Phase 4: Settings Screen (7/7 plans) — completed 2026-10-18
- [x] Phase 5: Notifications Infrastructure (9/9 plans) — completed 2026-10-20
- [x] Phase 6: Quest Accept & Info Sheets (12/12 plans) — completed 2026-10-22
- [x] Phase 7: Travel (11/11 plans) — completed 2026-10-26
- [x] Phase 8: Spells Section (Journal Tab) (14/14 plans) — completed 2026-10-27
- [x] Phase 9: Combat Result Sheet (13/13 plans) — completed 2026-10-29
- [x] Phase 10: Admin Panel (innkeeper) (11/11 plans) — completed 2026-11-01
- [x] Phase 11: Auth & Session Bootstrap (11/11 plans) — completed 2026-10-06
- [x] Phase 12: Hardening (17/17 plans) — completed 2026-11-10 (executed last)
- [x] Phase 13: City Shops (11/11 plans) — completed 2026-11-03
- [x] Phase 14: Quest Generation (frontend companion) (11/11 plans) — completed 2026-11-05
- [x] Phase 15: Travel Food (9/9 plans) — completed 2026-11-06
- [x] Phase 16: Travel Ambushes (9/9 plans) — completed 2026-11-09
- [x] Phase 17: Unlockable Lore (12/12 plans) — completed 2026-11-09

Execution order followed: 1 → 11 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 13 → 14 → 15 → 16 → 17 → 12. Every content phase was gated on the merge of its BE companion (BE Phases 2–17 with 2.1, 3.1, 9.1, 9.2, 13.1). Full goals, success criteria, plans and traceability: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md).

</details>

### 🚧 v1.1 Healing & Models (Phases 18–21)

**Milestone goal:** the heal quests cure by the size of the city and the heal potions are drunk from the Journal with the backend's global recovery; the app follows the cleaned backend models, with the companion experience as the only visible change. Numbering continues from 18 (never restarts).

- [x] **Phase 18: Heal Quests by City Size** — Quest and result sheets consume the new `prizes.cure` (HP ceiling share + `canHeal` list, backend-owned): the sheet of a quest with a cure lists only the viewer's own injuries that it heals («Cura le tue ferite: …», no line when none) plus the life row («Vita: almeno il 50%»); the result sheet lists the injuries actually healed («Guarite: …») from `QuestResult.injuriesHealed`; content by city size (lists ≤20/≤40/all with lore touches, 2/5/8 h, descriptions) lives at DB; heal potions drunk from the Journal (tap → in-world confirmation → `useItem`) with the backend's global recovery (`CharacterStatus.potionRecoveryUntil`, countdown «pronta fra …», «Ricarica: …» on item rows, 30 min–24 h at DB) and the lore «Il limite del corpo» unlocked by the first potion. BE companion: BE Phase 18. _(added 2026-11-09; planned now, executed after the Phase 12 Hardening merge, user decision)_ (completed 2026-11-11)
- [x] **Phase 19: Model Review (frontend companion)** — The app follows the cleaned BE models (BE Phase 19) with no visible change except the companion xp: `Enemy.weaknesses { base, energy }`, `ownedPets` entries with `xp`/`currentLifePoints` (companion row «Esperienza: N / maxXp», result line «Il tuo compagno guadagna N PE» from `QuestResult.petXpGained`), `Pet.attack`/`Pet.defense`, `wornEquipment`/`feet`, one `spellStates` list with `active` (Journal spells section), no `PointOfInterest.quest`, `Lore.imagePath`; plus the FE-only fragile-parser fixes (`PointOfInterest.type`). Non-additive contract: gated plans after the BE Phase 19 merge. _(added 2026-11-09, executes after Phase 18)_ (completed 2026-11-11)
- [x] **Phase 20: Rank-Specific Prizes for Group Quests** — A group quest carries a prize for each rank that can join it: the adventurer gets a prize fit for an adventurer, the mage in the same quest a prize fit for a mage; backend-owned, the sheets show the viewer the prize of their own rank. Needs a BE companion phase. _(added 2026-11-11)_ (completed 2026-11-13)
- [x] **Phase 21: Innkeeper Mission Completion Flow** — The innkeeper completes story/worldMission quests through a guided flow: teleport of the participants to a POI/city → enemies picked from a list by mission rank and POI type (quantity and kind) → combat simulation on the backend engine without writing on the characters → manual fixes (injuries in excess removed, life by slider) → prizes per character (coins, xp, items, pets, spells) → quest completion and update of the playing characters. The prize step starts from the prizes suited to each character's rank (Phase 20). Needs a BE companion phase. _(added 2026-11-11; completed 2026-11-14)_
- [x] **Phase 22: Companion Defeat, Rest and Recovery** — An equipped companion that drops to 0 life in a fight is unequipped at the end of the fight and cannot be used again until it is back to full life, after a wait proportional to its rarity and power. A companion that is only hurt can be put to rest (unequipped: it regains life in proportion to the time it rests) or healed with potions (same rule as the character's potions, with the wait). Needs a BE companion phase. _(added 2026-11-14; completed 2026-11-15)_
- [x] **Phase 23: Spell Origins, Void and Shamanic Quests** — Every spell carries a macro-class on top of its use and energy (origin → use → energy; origins: `void`, `arcane`, `shamanic`); two new quest types, `shamanic` and `void`, work exactly like the `arcane` quest (renamed from `magic`, label «Magia») and teach a spell of their own origin (before, that quest taught them all), with the four new sheet assets; the `void` quest lives only in Necrorian, the `shamanic` quest in the two new capitals (`aarakocraCapital`, `dragonbornCapital`, drawn on the map at the size of Talmvere), both from rank mage up; new city types `aarakocraCapital`, `dragonbornCapital`, `dragonbornVillage` with their assets and the `aarakocraVillage` asset replaced; a spell is learned from a minimum character level, no longer a minimum xp. Needs a BE companion phase (BE Phase 24). _(added 2026-11-15)_ (completed 2026-11-16)
- [x] **Phase 24: Participants' Stories and Innkeeper Wounds** — The guided completion of story/worldMission quests opens on a page where the innkeeper reads the background of every participant (one dropdown each) before starting the mission, and ends, after the recap, on a page where he may add one entry to the background of each participant (one optional addition per participant, up to 1000 characters) while rereading that participant's story; the additions are written with the completion and shown to the player by the wax sigil and a line on the result sheet. The wounds the innkeeper adds by hand are his alone to remove (from the corrections of every resolution): heal quests, potions and prizes never touch them, and the player reads them as «Troppo grave per essere curata». Needs a BE companion phase (BE Phase 25). _(added 2026-11-21)_ (completed 2026-11-22)

**Execution order:** 18 → 19 → 20 → 21 (rank-specific prizes before the innkeeper flow, so that its prize step offers a list already filtered by the character's rank). Each phase is gated on the merge of its BE companion (schema gate on the merged BE SDL before the plans that select the new fields and before the device UAT). Requirements: [REQUIREMENTS.md](REQUIREMENTS.md).

## Phase Details

### Phase 18: Heal Quests by City Size
**Goal**: Heal quests stop being all alike. The backend owns the cure as an explicit prize of the quest (`prizes.cure { lifePointsShare, canHeal }`: a ceiling on the maximum HP and the list of injuries healed, applied to every won quest that carries it) and the content by city size (village ≤20 / city ≤40 / capital all, lore touches by city type, 2 / 5 / 8 hours, descriptions by size, free). The frontend consumes the field: on the sheet of a quest with a cure it shows only the current character's injuries that the quest heals plus the life row, on the result sheet the injuries actually healed; it computes no game rule (the intersection with the character's injuries is display filtering). In the same phase the heal potions are drunk from the Journal with the backend's global recovery (`LootItem.recovery { time, turns }`, `CharacterStatus.potionRecoveryUntil`, `useItem` → `UseItemResult`), shown as a countdown and a «Ricarica: …» line, and the first potion unlocks the lore «Il limite del corpo» shown by the Library as any new page.
**Depends on**: Phase 6 (per-type sheets), Phase 9 (result parchment, HP delta, injuries line), Phase 14 (description on the sheet), quick tasks 261109-inj/inj2 (`canHeal` item line, 37 `InjuryType`, tolerant parsing), BE Phase 18 (`QuestPrizes.cure`, `QuestResult.injuriesHealed`, content at DB); **executes after Phase 12 Hardening** (user decision 2026-11-09)
**Scope**: M
**Requirements**: HEAL-01, HEAL-02, HEAL-03, HEAL-04, HEAL-05, HEAL-06
**Success Criteria** (what must be TRUE):
  1. `QuestPrizes.cure` (`lifePointsShare`, `canHeal`) is parsed leniently into the quest model from the shared fragment (unknown injuries dropped, malformed cure → null, the quest stays); on the sheet of any quest with a non-null cure the cure line lists only the current character's injuries present in `canHeal` (lowercase Italian labels, character order) and is absent when none matches; the life row «Vita: almeno il N%» is shown whenever the cure is present (share 1 → «al massimo», share 0 → hidden); a heal without a cure shows neither row.
  2. The result sheet shows «Guarite: <labels>» from `QuestResult.injuriesHealed` (lenient) after the HP delta and before the injuries added, hidden when empty.
  3. Device UAT with the player identity after the BE Phase 18 merge and the content write: seeded injuries on the test character, one heal per size (village: one listed and one unlisted injury → one healed, HP to 50%, «Guarite» line; city; capital: everything healed, HP full); the schema gate confirms the names on the merged BE SDL.
  4. In the Journal «Oggetti» section a heal parchment with a `recovery` is tappable: an in-world confirmation («Bevi <nome>?») calls `useItem`; on success the HP gain animates, «Guarite: …» lists the injuries healed and the Phase 17 lore line («Conoscenza appresa: …») appears when `loreUnlocked` is not empty, the state arrives from the character stream; refusals are notices with the backend's remaining time for `POTION_RECOVERING`; the action is available in travel and hidden while awaiting aid; nothing on the FE touches combat.
  5. While `CharacterStatus.potionRecoveryUntil` is in the future every heal parchment is disabled with a countdown «pronta fra …» from the server date; item rows in the shop and the Journal show «Ricarica: …» from `recovery.time` (`turns` not shown); `LootRecovery` and `potionRecoveryUntil` are parsed leniently; the device E2E drinks a field herb, sees the countdown and the lore line; the `POTION_RECOVERING` notice on a second potion is proved by tests and by the orchestrator's GraphQL probe, the parchments being disabled during the countdown (D-19).
**Decisions of the discuss (2026-11-09, `18-CONTEXT.md` D-01..D-10)**: HP and injuries separated with explicit lists per place (user); ceiling 50/80/100; lists ≤20/≤40/all with lore touches; hours 2/5/8; sheet with only the viewer's curable injuries, no count, no line when none (user, confirmed); life row always; «Guarite: …» on the result; executed after Phase 12; travel food deferred (user). **Amended the same evening (D-11..D-16)**: Journal potions with the global recovery (`recovery { time, turns }`, 30 min–24 h, `turns` data only), confirmation + feedback + countdown, «Ricarica: …» rows, lore «Il limite del corpo» through the Phase 17 Library flow.
**Backend prerequisite**: BE Phase 18 merged on BE `develop` (itself after the BE Phase 17).
**Plans**: 13 plans

Plans:
- [x] 18-01-PLAN.md — Quest cure models (`QuestCure`, `QuestPrizes.cure`, `QuestResult.injuriesHealed`, lenient injury reader)
- [x] 18-02-PLAN.md — Potion models (`LootRecovery`, `potionRecoveryUntil`, `UseItemResult`, fixtures)
- [x] 18-03-PLAN.md — Lines (`curableInjuriesLine`, `lifeShareLine`, `healedLine`, `recoveryLine`, `potionReadyInLine`)
- [x] 18-04-PLAN.md — Quest sheet: cure line and life row, `characterInjuries` from Board and Map
- [x] 18-05-PLAN.md — Result sheet «Guarite» and `ItemRow` «Ricarica» / disabled look / status line
- [x] 18-06-PLAN.md — `useItem` plumbing (document + registry 46, extension reader, `ItemUseFailure`, `ItemUseRepository`)
- [x] 18-07-PLAN.md — Potion cubits (`PotionCubit`, `PotionRecoveryCubit`)
- [x] 18-08-PLAN.md — Potion notices and wiring (`potionNoticeFor`, `PotionOutcomeListener`)
- [x] 18-09-PLAN.md — Shared lore line and Journal potion flow (`PotionSheet`, `ItemsSection`, countdown, travel, awaiting aid)
- [x] 18-10-PLAN.md — Heal with no effect: `Quest.noEffect`, torn inert sheet, vitals reread
- [x] 18-11-PLAN.md — Heal with no effect: `QUEST_NO_EFFECT` refusal, notice, list reread
- [x] 18-12-PLAN.md — Schema gate, fragment selections, document validation, full suite (gated on the BE Phase 18 merge)
- [x] 18-13-PLAN.md — Device E2E, requirements closed, closing docs (human checkpoint, gated)

### Phase 19: Model Review (frontend companion)
**Goal**: The frontend consumes the cleaned backend models without changing what the player sees, except the companion xp decided by the user: owned companions carry `xp` and `currentLifePoints` on the character, the companion row shows the experience and the result sheet says how much the companion gained (10 % of the enemies' xp, capped at the catalogue `maxXp`, backend-owned). Shape changes consumed: `Enemy.weaknesses { base, energy }`, `Pet.attack`/`Pet.defense` instead of `damages`, `ownedPets` entries, `wornEquipment` with `feet`, one `spellStates` list with `active` (the Journal spells section reads known = all, equipped = active), `PointOfInterest.quest` removed, `Lore.imagePath`. FE-only: fragile parsers fixed with tests.
**Depends on**: Phase 8 (spells section), Phase 9 (result sheet), Phase 13 (companions), Phase 14 (non-additive contract pattern), Phase 18 (same branch, executed before), BE Phase 19 (SDL + migrator + handoff table)
**Scope**: M
**Requirements**: MODEL-01, MODEL-02, MODEL-03, MODEL-04
**Success Criteria** (what must be TRUE):
  1. Enemy, lore and POI models and fragments follow the new SDL: `weaknesses` parsed leniently into `{ base, energy }`, `Lore.imagePath` read everywhere, `PointOfInterest.quest` gone; the Map and the Library behave as before.
  2. `CharacterAssets.ownedPets` is parsed as entries (`pet`, `xp`, `currentLifePoints`; malformed entry dropped); the «Compagni» list and the «Compagno» slot work on the entry's catalogue pet; the owned companion row shows «Esperienza: N / maxXp»; `Pet.attack`/`Pet.defense` replace `damages` on the companion card; the result sheet shows «Il tuo compagno guadagna N PE» when `petXpGained` > 0.
  3. `wornEquipment` and the `feet` slot replace the old names in fragment, model, enum and mannequin; the Journal spells section reads the single `spellStates` list (`active` = equipped) with usages and recovery from the same entry, `CharacterStatus.spells` and `CharacterAssets.activeSpells` no longer selected; equip/unequip optimistic rollback adapted; `maxActiveSpells` unchanged.
  4. FE-only: `PointOfInterest.fromJson` builds a `List<PoiType>` and guards `location`; the sweep of the models for the same fragile patterns lands with a pinned test per fix; the schema gate and the device E2E after the BE Phase 19 merge pass (Journal companions, spells, mannequin; a fight with the equipped companion; Map; Library).
**Decisions of the discuss (2026-11-09, `19-CONTEXT.md` D-01..D-12)**: as above; out of scope the single inventory list, spell `damages`/`requiredLearnTime` (separate session), combat rules.
**Backend prerequisite**: BE Phase 19 merged on BE `develop` (after the BE Phase 18).
**Plans**: 13 plans

Plans:
- [x] 19-01-PLAN.md — POI and enemy parsers (`type` lenient, `location` guarded, no `quest`), `Weaknesses`
- [x] 19-02-PLAN.md — Lenient damage entries, spell energy and `title` (MODEL-04 rows 5–7)
- [x] 19-03-PLAN.md — Entry boundaries: `AssetQuantity`, worn slots, shop pool, `getCities` (MODEL-04 rows 8–10, 12)
- [x] 19-04-PLAN.md — `Pet.attack`/`defense`, `OwnedPet` with the window branch, consumers on the entries
- [x] 19-05-PLAN.md — Companion lines and widgets: «Esperienza», «Attacco», «Difesa» (Journal and shop)
- [x] 19-06-PLAN.md — `petXpGained` and «Il tuo compagno guadagna N PE» on the result sheet
- [x] 19-07-PLAN.md — `SpellState` with `spell` and `active`, pure legacy reader (not wired)
- [x] 19-08-PLAN.md — `Spellbook` and `SpellsCubit` on the single list, legacy reader wired in `Character.fromJson`
- [x] 19-09-PLAN.md — Spell fixtures migrated to the single list (test-only), then model contraction: the two old spell lists and `ActiveSpell` removed
- [x] 19-10-PLAN.md — Schema gate, atomic `wornEquipment`/`feet` rename, atomic `Lore.imagePath` rename (gated on the BE Phase 19 merge)
- [x] 19-11-PLAN.md — Fragment flip, 46 documents OK, legacy readers deleted RED-first (gated)
- [x] 19-12-PLAN.md — Schema check, full suite, analyzer, validation (gated)
- [x] 19-13-PLAN.md — Device E2E, requirements closed, closing docs (human checkpoint, gated)

### Phase 20: Rank-Specific Prizes for Group Quests
**Goal**: A group quest rewards every participant with a prize suited to their own rank: if an adventurer can join, the quest carries a prize fit for an adventurer, and the mage who joins the same quest gets a prize fit for a mage. Prizes are defined per rank among the ranks admitted by the quest and resolved by the backend for each participant; the app shows each viewer the prize of their own rank on the quest sheet and on the result sheet.
**Depends on**: Phase 6 (quest sheets), Phase 9 (result sheet), Phase 14 (quest generation, pools by rank), BE Phase 21 «Premi per rango e soccorsi» (BE-RANKP-01..06, opened 2026-11-12). Executed before Phase 21, whose prize step reuses the prizes by rank (user decision, 2026-11-11).
**Scope**: FE side of the rank blocks. The contract change is additive (D-22): `Quest.prizes` keeps its shape and is resolved by the BE for the viewer, so the quest sheet needs contract pins only; the result sheet gains one dungeon-turn line (dungeon and dungeon aid) with the stages line as fallback; mixed-rank bosses are pinned by tests. Schema gate and device E2E wait for the BE Phase 21 merge.
**Requirements**: RANKP-01, RANKP-02, RANKP-03, RANKP-04
**Success Criteria** (what must be TRUE):
  1. On a group quest the sheet (Board and Map) prints the prize block the BE serves for the viewer with today's rows (coins, prize item, pet line, cure lines); the app never chooses a block, and a rank-up rereads the quests.
  2. A mixed-rank boss shows one seat line per title; registration and the party counter are judged per seat title as the BE does.
  3. The result sheet of a dungeon and of a dungeon aid prints one turn line from the BE fields («Piani superati: C su T», «Soccorso effettuato al raggiungimento del L° piano su T», «Caduto al L° piano su T, in esplorazione / in uno scontro»; copy amended during the device UAT, `20-UAT-FIX-02.md`), nothing on `rescued`, `death` and `gmCompleted`; without the turn fields it falls back to «Esplorazione: tappa N di M»; a malformed new field never drops the result.
  4. Schema check green against the merged BE SDL with the four turn fields selected; device E2E passed (rank block, mixed boss, dungeon aid by turns with the real share on the aid sheet, dungeon won, lost fight without aid).
**Decisions**: `20-CONTEXT.md` D-01..D-17 (discuss 2026-11-12) and D-18..D-25 (after the research, 2026-11-13).
**Backend prerequisite**: BE Phase 21 merged on BE `develop` for plans 20-03 and 20-04 (the phase parks at 2/4).
**Plans**: 4 plans

Plans:
- [x] 20-01-PLAN.md — Contract pins for the served prize block and mixed-rank bosses (test-only)
- [x] 20-02-PLAN.md — Dungeon turn fields on the result, one turn line in the stages slot with fallback, backend notes
- [x] 20-03-PLAN.md — Schema gate, turn-field selection, 46 documents OK, full suite (gated on the BE Phase 21 merge)
- [x] 20-04-PLAN.md — Device E2E, requirements closed, closing docs (human checkpoint, gated)

### Phase 21: Innkeeper Mission Completion Flow
**Goal**: The innkeeper completes a story or worldMission quest from the Inn through a guided flow instead of the current plain form: (1) teleport the participants to a POI/city; (2) pick the enemies from a list — quantity and kind — filtered by the rank of the mission and the type of the POI; (3) run a combat simulation with the backend combat engine that does **not** write its outcome on the characters; (4) fix the outcome by hand where needed (remove the injuries in excess, set each character's life with a slider); (5) choose the prizes per character (coins, xp, items, pets, spells) from a list already filtered to the prizes suited to that character's rank (Phase 20); (6) complete the quest, which updates the playing characters. The backend stays the source of truth: simulation, enemy lists and the final write are server-side, the app only drives the steps.
**Depends on**: Phase 10 (Admin Panel — Inn queue, completion form, teleport), Phase 9 (combat result sheet), Phase 19 (cleaned models), Phase 20 (rank-specific prizes: the filtered list of the prize step), BE Phase 22 «Completamento guidato delle missioni» (BE-GMFLOW-01..07, opened 2026-11-12: enemy list by rank/POI type, dry-run simulation, draft, completion with manual outcome and per-character prizes)
**Scope**: decisions D-01..D-30 of `21-CONTEXT.md` (discuss 2026-11-12, amended 2026-11-14 after the research); BE companion: BE Phase 22 «Completamento guidato delle missioni»
**Requirements**: GMFLOW-01, GMFLOW-02, GMFLOW-03, GMFLOW-04, GMFLOW-05, GMFLOW-06, GMFLOW-07, GMFLOW-08
**Success Criteria** (what must be TRUE):
  1. The innkeeper teleports the group to a city or an inner POI from the wizard and comes back to the wizard of that request.
  2. The wizard starts, resumes at the served step (also from another device) and discards the draft; simulations, corrections and prizes are read from and saved to the backend, never computed in the app.
  3. The mission is completed from the recap with a confirmation and the players get the usual result sheet; the Phase 10 form is gone.
  4. A character with a mission in progress sees the notice and cannot travel, accept quests, trade, change equipment, companion or spells, nor drink potions; a refusal shows the wait banner.
  5. Schema check green on the merged BE Phase 22 SDL and device E2E passed.
**Plans**: 18 plans (sequential waves; 01–15 work against today's BE, 16–18 gated by the BE Phase 22 merge)

Plans:
- [x] 21-01-PLAN.md — Mission lock plumbing I: status flags, shared code and copy, travel and acceptance refusals
- [x] 21-02-PLAN.md — Mission lock plumbing II: shop, spell and companion refusals
- [x] 21-03-PLAN.md — Equipment refusal made visible: repository, classifier, Journal notice
- [x] 21-04-PLAN.md — Players' lock on the Board, the Map pawn and the satchel
- [x] 21-05-PLAN.md — Players' lock in the Journal and the potion refusal
- [x] 21-06-PLAN.md — Inner-place data: POI labels, place names, teleport destination, POI document
- [x] 21-07-PLAN.md — Teleport mode over destinations and the card to resume
- [x] 21-08-PLAN.md — Map: inner-POI layer and the teleport-only drop rule
- [x] 21-09-PLAN.md — Return to the wizard after the Map and the «Riprendi» flag
- [x] 21-10-PLAN.md — Mission draft models and wire inputs
- [x] 21-11-PLAN.md — Mission documents, registry, service and repository operations
- [x] 21-12-PLAN.md — Wizard Cubits: draft, participants, enemies, prize options
- [x] 21-13-PLAN.md — Wizard UI 1: route, host, start, resume, discard, «Luogo»
- [x] 21-14-PLAN.md — Wizard UI 2: «Scontri» and the fight page with corrections
- [x] 21-15-PLAN.md — Wizard UI 3: «Premi» and «Riepilogo» with completion
- [x] 21-16-PLAN.md — Gate: schema, gated selection, «Completa» wired to the wizard (after the BE Phase 22 merge)
- [x] 21-17-PLAN.md — Phase 10 form retired, registry, schema check, full suite (after the BE Phase 22 merge)
- [x] 21-18-PLAN.md — Device E2E, handoff and closing (after the BE Phase 22 merge, human)

### Phase 22: Companion Defeat, Rest and Recovery
**Goal**: The companions (pets) a character has equipped can be defeated, rested and healed. (1) A companion that reaches 0 life during a fight is unequipped automatically at the end of the fight and can be equipped again only when it is back to full life; the wait is proportional to its rarity and power. (2) A companion that is only hurt can be unequipped and put to rest: it regains life for as long as it rests, in proportion to the time (user example, 2026-11-14: a companion that takes 100 minutes to go from 1 to 100 life, put to rest at 20 life and left for 20 minutes, has 40 life when equipped again), so the time to a full recovery is proportional to the life to regain. (3) A hurt companion can instead be healed with potions, with the same rule as the potions on the character (wait time included). The backend stays the source of truth: defeat, recovery times, life regained and the potion rule are server-side; the app shows the state and drives the actions.
_Amended 2026-11-14 (D-03): the companion's life floor is 1; «0 life» above reads «the floor»._
**Depends on**: Phase 13 (companions in the Journal), Phase 18 (Journal potions and their wait), Phase 19 (companion model, companion xp), Phase 9 (result sheet), Phase 21 (mission lock on the companion; guided completion writes the companions' state), a BE companion phase (BE Phase 23 «Sconfitta, riposo e recupero dei compagni», added 2026-11-14)
**Scope**: decisions D-01..D-35 of `22-CONTEXT.md` (discuss 2026-11-14, amended after the research); BE companion: BE Phase 23 «Sconfitta, riposo e recupero dei compagni»
**Requirements**: PET-01, PET-02, PET-03, PET-04, PET-05, PET-06, PET-07, PET-08, PET-09, PET-10
**Success Criteria** (what must be TRUE):
  1. The Journal shows each companion's life, rising live while it rests; a defeated companion is faded with its countdown and comes back by itself at full life.
  2. A potion can be given to an eligible companion from the potion sheet; refusals show the companion's name.
  3. Companions can be named at purchase, after a prize and from the details sheet; every wording uses the name.
  4. The result sheet and the ambush pages tell the companion's life, defeat and walk on foot; every ambush pushes, and a defeated companion back in shape pushes «in forze».
  5. Schema check green on the merged BE Phase 23 SDL and device E2E passed.
**Plans**: 17 plans (sequential waves; 01–15 work against today's BE, 16–17 gated by the BE Phase 23 merge)

Plans:
- [x] 22-01-PLAN.md — Requirements and companion models (lenient, unselected)
- [x] 22-02-PLAN.md — Pure rules: vitality, display name, name rules, companion copy
- [x] 22-03-PLAN.md — Live-safe pet fields and the companion vitality ticker
- [x] 22-04-PLAN.md — Details sheet frame and the companion card restyle
- [x] 22-05-PLAN.md — Companion details sheet, its route and the companion care switch
- [x] 22-06-PLAN.md — Journal «Compagno»: live life, rest, defeat, details
- [x] 22-07-PLAN.md — Companion cards in the shop lists and the basket, names in the sell list
- [x] 22-08-PLAN.md — Companion cards in the quest-sheet prize and the innkeeper prize rows
- [x] 22-09-PLAN.md — Companion potion plumbing: target, refusals, PotionCubit.give
- [x] 22-10-PLAN.md — Potion sheet with companion targets
- [x] 22-11-PLAN.md — Companion name plumbing: RenamePet, classifier, Cubit
- [x] 22-12-PLAN.md — Name prompt sheet and its entry points
- [x] 22-13-PLAN.md — Result sheet: companion life, defeat, xp and walk on foot
- [x] 22-14-PLAN.md — Ambush and «in forze» notification categories
- [x] 22-15-PLAN.md — Innkeeper companion life slider
- [x] 22-16-PLAN.md — Gate: schema, gated selections, UseItem target, switch (after the BE Phase 23 merge)
- [x] 22-17-PLAN.md — Device E2E, handoff and closing (after the BE Phase 23 merge, human)

### Phase 23: Spell Origins, Void and Shamanic Quests
**Goal**: The spells get a macro-class and two new schools of quests. User's words (2026-11-15): «Le magie devono avere una macroclasse (ovvero origin->use->energy). Le origini sono 3: void, magic e shamanic»; every spell at DB is reviewed and given the right origin from its description, and the DB is filled with new spells where some are missing; «Poi dovremo aggiungere due tipi di quest: shamanic e void. Funzioneranno esattamente come la missione magic. Ognuna di loro insegnerà una magia sulla base del tipo (adesso magic le insegna tutte)»; the `void` quest only in Necrorian («nessuna quest a Necrorian dovrebbe venir creata con rango minimo inferiore a mage»); the `shamanic` quest in the two new capitals, acceptable from rank mage up; city `690961bfe74c2f6dfc837d8f` is now `aarakocraCapital`, `690961bf1bf8bb61e5f6af2f` is `dragonbornVillage`, `690961bf31795cde80768bc7` is `dragonbornCapital` (the two capitals have size `capital` and the map size of Talmvere); «Le magie non devono più avere un minimo xp per impararle, ma un minimo livello» (the parameter is reviewed against the character level table). The backend stays the source of truth: origin, teaching rule, quest generation and the level gate are server-side; the app shows the origin, the new quest sheets and the new city types.
_Amended 2026-11-15 (D-01, D-20..D-24 of `23-CONTEXT.md`): the origin `magic` reads `arcane`, and the quest type `magic` is renamed `arcane` too (label «Magia» kept, the three school types are `arcane`, `shamanic`, `void`); the eleven Cloudinary ids are given (no stand-in ids); learning the first spell of an origin unlocks the lore of that origin (server-side, shown by the existing lore-unlock path); the heal quests and shops of the two new capitals are those of a city and the lore of the three cities is rewritten (DB content)._
**Depends on**: Phase 8 (spells in the Journal), Phase 14 (generated quests and their sheets), Phase 6 (quest sheets), Phase 7 (map and city markers), Phase 22, a BE companion phase (BE Phase 24 «Origini delle magie, quest void e shamanic»)
**Scope**: decisions D-01..D-31 of `23-CONTEXT.md` (interactive discuss of 2026-11-15, joint with BE Phase 24, amended after the research); BE companion: BE Phase 24 «Origini delle magie, quest void e shamanic». No UI phase.
**Requirements**: ORIGIN-01, ORIGIN-02, ORIGIN-03, ORIGIN-04, ORIGIN-05, ORIGIN-06, ORIGIN-07, ORIGIN-08
**Success Criteria** (what must be TRUE):
  1. Every spell card shows the origin icon before use and energy and the spell details read «Origine: …» and «Per impararla: Livello N»; «XP» appears nowhere on a spell and the app compares the level with nothing.
  2. The Board and the Map draw «Rito sciamanico» and «Rito del Vuoto» on their own sheets, torn until the rank, «Ricercando…» while the research runs, exactly like the arcane quest («Magia»), whose stored type `magic` is still read.
  3. Murnborim and Thengran are on the Map at every zoom at the size of Talmvere, Veg Faldir from the village zoom, Balkuldir with its new drawing.
  4. The first spell learned of an origin shows its lore unlock on the result sheet and in the Library.
  5. Schema check green on the merged BE Phase 24 SDL (with BE PR #43) and device E2E passed.
  6. A draw quest reads «Ricercando…» during its «Fase di ricerca», then the name of the spell being learned with its countdown; the research outcome arrives as a result sheet and a push (spell found, or none), and the end of the learning as a second small sheet.
**Plans**: 14 plans (sequential waves; 01–06 work against today's BE, 07 gated by the BE Phase 24 merge; 09–14 added on 2026-11-16 for the research and learning parts, D-26..D-31 — 09–13 work against any BE, 14 gated by the BE research block; 08 runs LAST, after 14)

Plans:
- [x] 23-01-PLAN.md — Requirements and the quest type wire boundary (wireName / fromWire)
- [x] 23-02-PLAN.md — Spell model: origin and minimum level (lenient, unselected), minXpToLearn removed
- [x] 23-03-PLAN.md — Quest types: magic renamed arcane, the shamanic and void rites with their sheets
- [x] 23-04-PLAN.md — City types: aarakocraCapital, dragonbornCapital, dragonbornVillage with their markers
- [x] 23-05-PLAN.md — Asset ids: the aarakocra village redrawn, audit of the eight sheet and city ids
- [x] 23-06-PLAN.md — Origin drawing: icon ids, origin first on the spell card, origin row in the details
- [x] 23-07-PLAN.md — Gate: schema, origin and minimum level selected, schema check, full suite (after the BE Phase 24 merge)
- [x] 23-09-PLAN.md — Research and learning requirements; the learn time leaves the spell details (D-28)
- [x] 23-10-PLAN.md — Models: learning spell on the lane, spell draw, spell found and failed research (lenient, unselected)
- [x] 23-11-PLAN.md — «Ricercando…» and learning copy rules, the learning countdown cubit
- [x] 23-12-PLAN.md — Map: learning countdown owned by the Map, pawn and overlay labels of the two parts
- [x] 23-13-PLAN.md — Result sheets of a research and of the learning end; research pushes handled as quest ends
- [x] 23-14-PLAN.md — Gate: research fields on the BE SDL, selections, schema check, full suite (after BE plans 24-13..24-18)
- [x] 23-08-PLAN.md — Device E2E, handoff and closing (LAST: after 23-14 and the BE Phase 24 merge, human)

### Phase 24: Participants' Stories and Innkeeper Wounds
**Goal**: The innkeeper reads every participant's story before resolving a story/worldMission quest and adds to each story at the end; the wounds he inflicts by hand are beyond every cure but his own. User's words (2026-11-21): «Come primo step serve una schermata dove ogni partecipante ha una propria dropdown, al cui interno si trova il suo background, in modo che io possa leggere la storia di tutti prima di prendere decisioni. Infine serve un ultimo step (alla fine di tutto), dove io possa fare un aggiunta al background di ogni partecipante, potendo anche rileggere la storia del singolo. Altra cosa importante: Le ferite applicate dall'innkeeper sono rimuovibili solo dall'innkeeper, non sono influenzabili da quest heal, pozioni o premi».
**Depends on**: Phase 21 (guided completion flow), Phase 18 (cures and potions), Phase 10 (innkeeper corrections), a BE companion phase (BE Phase 25 «Storie dei partecipanti e ferite dell'oste»)
**Scope**: decisions D-01..D-18 of `24-CONTEXT.md` (interactive discuss of 2026-11-21, joint with BE Phase 25; amended the same day: any wound removable from the corrections, no popup, removed wounds read as healed), plus D-20..D-23 born at the device UAT of 2026-11-22 (heal item lines list every wound, the reader's innkeeper wounds in red; «Ferite» as a dropdown; recap and additions in one dropdown per participant). Branch stacked on the local `fix/ui-layout-review` (background list, wax sigil). The app has no plain pending-request form since plan 21-17: the corrections live only in the guided flow. No UI phase.
**Requirements**: STORY-01, STORY-02, STORY-03, STORY-04, WOUND-01, WOUND-02, WOUND-03
**Success Criteria** (what must be TRUE):
  1. Opening the guided completion of a story/worldMission request shows one closed dropdown per participant with that participant's background entries, before the mission is started and without creating the draft; «Inizia la missione» is at the bottom, the page stays reachable by «Indietro», and no popup exists.
  2. After the recap the innkeeper reaches a last page with, per participant, the story so far and one optional field (1000 characters); leaving and coming back finds the texts; one confirmed «Concludi» saves them and completes the mission.
  3. In the corrections the innkeeper removes any carried wound, sees his own marked, and makes an ordinary wound his by removing and re-adding it; nothing about a wound's origin is computed on the device.
  4. The participant reads «La tua storia ha una nuova pagina» and the removed wounds inside «Guarite: …» on the result sheet, and finds the wax sigil on Profile and on the new background entry.
  5. In the Journal an innkeeper wound reads «Troppo grave per essere curata»; the line «Cura le tue ferite: …» of a heal quest (sheets, Board, map) lists only what will be cured, never an innkeeper wound; the line «Cura: …» of a heal item lists every wound the item can cure, and where the reader is the logged character (the item row of the Journal, the potion sheet) the reader's innkeeper wounds are written in red (D-20, D-21, device UAT of 2026-11-22; the backend still decides what a potion cures, D-14); a heal quest that would cure only innkeeper wounds is not acceptable, also right after an origin flip.
  6. Schema check green on the merged BE Phase 25 SDL (55 documents), full suite green, device E2E passed.
**Plans**: 11 plans (sequential waves; 01–09 work against today's BE — nothing new selected, the new input behind one switch; 10 gated by the BE Phase 25 merge; 11 runs LAST, human)

Plans:
- [x] 24-01-PLAN.md — Innkeeper-side models and inputs (additions, step, wound removals and origins), the switch, suite baseline
- [x] 24-02-PLAN.md — Player-side models (innkeeper wounds, removed wounds, story flag) and the «nothing selected before the gate» pins
- [x] 24-03-PLAN.md — Shared story pieces: BackgroundEntries promoted, the participant's story dropdown, participants read before the draft
- [x] 24-04-PLAN.md — Reading page: the wizard opens on the stories, «Inizia la missione» at the bottom, reachable by going back
- [x] 24-05-PLAN.md — Additions: save and conclude on the Cubit, SheetTextField promoted, the last page widget
- [x] 24-06-PLAN.md — Additions wired in the wizard behind the switch: recap «Avanti», «Concludi» with confirmation, save on back and on leave
- [x] 24-07-PLAN.md — Corrections that remove and re-add wounds, the innkeeper mark, removals in the recap
- [x] 24-08-PLAN.md — Player side: Journal line, cure and potion lines without innkeeper wounds, Board reread on an origin flip
- [x] 24-09-PLAN.md — Result sheet: story line and joined «Guarite» line; proof that the sigil marks an appended entry
- [x] 24-10-PLAN.md — Gate: schema, selections, switch on, schema check, full suite (after the BE Phase 25 merge)
- [x] 24-11-PLAN.md — Device E2E, handoff and closing (LAST, human)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 1. Dev Auth Stub | v1.0 | 3/3 | Complete | 2026-04-15 |
| 2. Character Creation | v1.0 | 11/11 | Complete | 2026-10-09 |
| 3. Real-Time Sync Foundation | v1.0 | 9/9 | Complete | 2026-10-14 |
| 4. Settings Screen | v1.0 | 7/7 | Complete | 2026-10-18 |
| 5. Notifications Infrastructure | v1.0 | 9/9 | Complete | 2026-10-20 |
| 6. Quest Accept & Info Sheets | v1.0 | 12/12 | Complete | 2026-10-22 |
| 7. Travel | v1.0 | 11/11 | Complete | 2026-10-26 |
| 8. Spells Section (Journal Tab) | v1.0 | 14/14 | Complete | 2026-10-27 |
| 9. Combat Result Sheet | v1.0 | 13/13 | Complete | 2026-10-29 |
| 10. Admin Panel (innkeeper) | v1.0 | 11/11 | Complete | 2026-11-01 |
| 11. Auth & Session Bootstrap | v1.0 | 11/11 | Complete | 2026-10-06 |
| 12. Hardening | v1.0 | 17/17 | Complete | 2026-11-10 |
| 13. City Shops | v1.0 | 11/11 | Complete | 2026-11-03 |
| 14. Quest Generation (companion) | v1.0 | 11/11 | Complete | 2026-11-05 |
| 15. Travel Food | v1.0 | 9/9 | Complete | 2026-11-06 |
| 16. Travel Ambushes | v1.0 | 9/9 | Complete | 2026-11-09 |
| 17. Unlockable Lore | v1.0 | 12/12 | Complete | 2026-11-09 |
| 18. Heal Quests by City Size | v1.1 | 13/13 | Complete | 2026-11-11 |
| 19. Model Review (companion) | v1.1 | 13/13 | Complete | 2026-11-11 |
| 20. Rank-Specific Prizes for Group Quests | v1.1 | 4/4 | Complete | 2026-11-13 |
| 21. Innkeeper Mission Completion Flow | v1.1 | 18/18 | Complete | 2026-11-14 |
| 22. Companion Defeat, Rest and Recovery | v1.1 | 17/17 | Complete | 2026-11-15 |
| 23. Spell Origins, Void and Shamanic Quests | v1.1 | 14/14 | Complete | 2026-11-16 |
| 24. Participants' Stories and Innkeeper Wounds | v1.1 | 11/11 | Complete | 2026-11-22 |
| 25. Account Deletion and Legal Consent | v1.1 | 7/8 | In Progress | - |

### Phase 25: Account Deletion and Legal Consent

**Goal:** (↔ BE Phase 26) il giocatore elimina il proprio account da Impostazioni con una conferma in-world e il backend cancella definitivamente utente, personaggi (anche archiviati), sessioni, device push e ritratto su Cloudinary; nella pagina di login le diciture «Termini di servizio» e «Privacy» aprono https://lucatabbia.github.io/klimmeck-guide-legal/termini e /privacy, e una checkbox obbligatoria di accettazione di termini e privacy abilita il login. Le pagine legali promettono già queste funzioni (repo `LucaTabbia/klimmeck-guide-legal`).
**Depends on:** Phase 24, Phase 11 (session and login), Phase 4 (Settings), Phase 10 (innkeeper section), a BE companion phase (BE Phase 26 «Eliminazione account e consenso»)
**Scope**: decisions D-01..D-23 of `25-CONTEXT.md` (interactive discuss of 2026-11-24, joint with BE Phase 26; amended the same day after the two researches: D-06, D-12, D-15 revised, D-13 replaced, D-17..D-23 added). No «Elimina account» on the character-creation screen (D-17); no party list and no placeholder wording — a started quest is cancelled server-side and the app only reacts (D-13, D-23); the version constant is a provisional date, the `[DATA DI PUBBLICAZIONE]` placeholder of the legal pages is not touched (D-12); the two privacy lines of D-22 are written in the legal repo by the orchestrator. No UI phase.
**Requirements**: ACCOUNT-01, ACCOUNT-02, ACCOUNT-03, ACCOUNT-04, ACCOUNT-05, CONSENT-01, CONSENT-02, CONSENT-03
**Success Criteria** (what must be TRUE):
  1. The login shows above its button one checkbox with «Accetto i Termini di servizio e l'Informativa sulla privacy», the two wordings open the public pages in the browser, the footer links are gone and the login stays disabled until the box is ticked; the acceptance is remembered on the device for the current document version and forgotten only when the account is deleted.
  2. The login carries the accepted version (`termsVersion` on `/auth/twitch/start`); the backend records version and date, and its refusal reads as its own line, never as a connection error.
  3. A player deletes his account from Settings → Account («Elimina account», last, under «Esci», hidden for the innkeeper) through one in-world destructive dialog, and lands on the login with «Il tuo account è stato eliminato.»; after the deletion the app calls nothing more on the backend, and a racing refresh or socket close never turns the landing into «sessione scaduta».
  4. The innkeeper deletes a player's account from the Twitch username in Settings → «Locanda» (dialog with the field, confirmation naming the username, every refusal inline); a player deleted while online lands on the same notice.
  5. When the deletion cancels a quest that had started, the companions left behind are drawn back in the city with the lane free and the refunds as served, the quest is back on the Board, and the push shows the backend's text — with no party list and no computation on the device.
  6. Schema check green on the merged BE Phase 26 SDL (57 documents), full suite green, device E2E passed, privacy lines of D-22 in the legal repo.
**Plans**: 8 plans (sequential waves; 01–06 work against today's BE — no new document, the deletions behind one switch; 07 gated by the BE Phase 26 merge; 08 runs LAST, human)

Plans:
- [x] 25-01-PLAN.md — Suite baseline, `LinkOpener` moved out of push, legal constants, consent memory and Cubit, checkbox row with the two links, footer removed, login gated on the tick
- [x] 25-02-PLAN.md — `accountDeleted` reason from the refused refresh (HTTP and WS 4409) and from the local teardown, the D-03 notice, the consent forgotten only on that landing
- [x] 25-03-PLAN.md — Own account deletion behind the abstract API: failure mapping, repository with the silent teardown, the race test, Cubit, dialog, «Elimina account» behind the switch
- [x] 25-04-PLAN.md — Innkeeper's deletion by Twitch username: failures, repository, Cubit, username dialog with inline refusals, the «Locanda» entry behind the switch
- [x] 25-05-PLAN.md — The login carries `termsVersion`: `login({required String acceptedLegalVersion})`, the stubs, `terms_not_accepted` mapped to its own sign-in failure
- [x] 25-06-PLAN.md — Cancelled started quest: tests proving the existing reactive paths draw the members back in the city and the quest back on the Board, fixes only where RED
- [x] 25-07-PLAN.md — Gate: schema, names, the two documents (55 → 57), GraphQL API, providers, switch on, schema check, full suite, BACKEND-NOTES (after the BE Phase 26 merge)
- [ ] 25-08-PLAN.md — Device E2E, UAT outcome in the handoff and closing (LAST, human)

---

_Roadmap created: 2026-04-10_ · _v1.0 Core Loop archived: 2026-11-10_ · _v1.1 Healing & Models started: 2026-11-10_
