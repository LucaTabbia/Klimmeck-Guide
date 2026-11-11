# Roadmap: Klimmeck Guide

**Created:** 2026-04-10
**Last updated:** 2026-11-10 — milestone v1.1 Healing & Models started (Phases 18–19); v1.0 Core Loop archived in `milestones/v1.0-ROADMAP.md`
**Milestone:** v1.1 Healing & Models — Phases 18–19 (companion of the BE milestone v1.1 «Cura e modelli», BE Phases 18–20)

## Milestones

- ✅ **v1.0 Core Loop** — Phases 1–17 (shipped 2026-11-10) — [roadmap archive](milestones/v1.0-ROADMAP.md) · [requirements archive](milestones/v1.0-REQUIREMENTS.md) · [summary](MILESTONES.md)
- 🚧 **v1.1 Healing & Models** — Phases 18–19 (started 2026-11-10) — heal quests by city size with the Journal potions (↔ BE Phase 18) and the model review companion (↔ BE Phase 19); BE Phase 20 (progressive travel food and life) has no FE phase

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

### 🚧 v1.1 Healing & Models (Phases 18–19)

**Milestone goal:** the heal quests cure by the size of the city and the heal potions are drunk from the Journal with the backend's global recovery; the app follows the cleaned backend models, with the companion experience as the only visible change. Numbering continues from 18 (never restarts).

- [x] **Phase 18: Heal Quests by City Size** — Quest and result sheets consume the new `prizes.cure` (HP ceiling share + `canHeal` list, backend-owned): the sheet of a quest with a cure lists only the viewer's own injuries that it heals («Cura le tue ferite: …», no line when none) plus the life row («Vita: almeno il 50%»); the result sheet lists the injuries actually healed («Guarite: …») from `QuestResult.injuriesHealed`; content by city size (lists ≤20/≤40/all with lore touches, 2/5/8 h, descriptions) lives at DB; heal potions drunk from the Journal (tap → in-world confirmation → `useItem`) with the backend's global recovery (`CharacterStatus.potionRecoveryUntil`, countdown «pronta fra …», «Ricarica: …» on item rows, 30 min–24 h at DB) and the lore «Il limite del corpo» unlocked by the first potion. BE companion: BE Phase 18. _(added 2026-11-09; planned now, executed after the Phase 12 Hardening merge, user decision)_ (completed 2026-11-11)
- [ ] **Phase 19: Model Review (frontend companion)** — The app follows the cleaned BE models (BE Phase 19) with no visible change except the companion xp: `Enemy.weaknesses { base, energy }`, `ownedPets` entries with `xp`/`currentLifePoints` (companion row «Esperienza: N / maxXp», result line «Il tuo compagno guadagna N PE» from `QuestResult.petXpGained`), `Pet.attack`/`Pet.defense`, `wornEquipment`/`feet`, one `spellStates` list with `active` (Journal spells section), no `PointOfInterest.quest`, `Lore.imagePath`; plus the FE-only fragile-parser fixes (`PointOfInterest.type`). Non-additive contract: gated plans after the BE Phase 19 merge. _(added 2026-11-09, executes after Phase 18)_

**Execution order:** 18 → 19. Each phase is gated on the merge of its BE companion (schema gate on the merged BE SDL before the plans that select the new fields and before the device UAT). Requirements: [REQUIREMENTS.md](REQUIREMENTS.md).

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
- [ ] 19-08-PLAN.md — `Spellbook` and `SpellsCubit` on the single list, legacy reader wired in `Character.fromJson`
- [ ] 19-09-PLAN.md — Spell fixtures migrated to the single list (test-only), then model contraction: the two old spell lists and `ActiveSpell` removed
- [ ] 19-10-PLAN.md — Schema gate, atomic `wornEquipment`/`feet` rename, atomic `Lore.imagePath` rename (gated on the BE Phase 19 merge)
- [ ] 19-11-PLAN.md — Fragment flip, 46 documents OK, legacy readers deleted RED-first (gated)
- [ ] 19-12-PLAN.md — Schema check, full suite, analyzer, validation (gated)
- [ ] 19-13-PLAN.md — Device E2E, requirements closed, closing docs (human checkpoint, gated)

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
| 19. Model Review (companion) | v1.1 | 7/13 | In Progress | - |

---

_Roadmap created: 2026-04-10_ · _v1.0 Core Loop archived: 2026-11-10_ · _v1.1 Healing & Models started: 2026-11-10_
