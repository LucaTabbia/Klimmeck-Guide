# Requirements: Klimmeck Guide — v1.1 Healing & Models

**Defined:** 2026-11-10
**Core Value:** I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.
**Milestone:** v1.1 Healing & Models (Phases 18–19), companion of the backend milestone v1.1 «Cura e modelli» (BE Phases 18–20). The v1.0 requirements are archived in [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md).

The backend is the source of truth for every rule: each requirement below describes what the app parses and shows, never a game rule computed on the device. The requirements were written in the joint discuss sessions of 2026-11-09 (`18-CONTEXT.md` D-01..D-16, `19-CONTEXT.md` D-01..D-12) and confirmed as the v1.1 scope on 2026-11-10.

## v1.1 Requirements

### Heal Quests by City Size (Phase 18, added 2026-11-09)

- [x] **HEAL-01**: The sheet of a quest whose `prizes.cure` is non-null (backend-owned: `lifePointsShare` ceiling + `canHeal` list, same name as on heal items) shows the life row «Vita: almeno il N%» (share 1 → «al massimo», share 0 → hidden) and a cure line listing only the current character's injuries present in `canHeal` («Cura le tue ferite: taglio profondo, contusione», lowercase labels, character order), absent when none matches; lenient parsing (unknown injuries dropped, malformed cure → null); no count, never the full list, no game rule on the FE
- [x] **HEAL-02**: The result sheet lists the injuries actually healed by the outcome («Guarite: <labels>») from `QuestResult.injuriesHealed` (lenient), after the HP delta and before the injuries added, hidden when empty
- [x] **HEAL-03**: Device UAT with the player identity after the BE Phase 18 merge and the content write by city size: one heal per size (village: one listed and one unlisted seeded injury → one healed and HP to 50%; city; capital: everything healed, HP full), schema gate on the merged BE SDL; the heal paper, description and time line (2 / 5 / 8 h, data only) unchanged
- [x] **HEAL-04**: In the Journal «Oggetti» section a heal item with a `recovery` is tappable: an in-world confirmation on parchment calls `useItem(itemId)` (repository + failures); on success the HP gain animates (`HpDeltaBar`), «Guarite: …» lists `injuriesHealed`, the Phase 17 lore line («Conoscenza appresa: <name>») appears when `loreUnlocked` is not empty, and the new state arrives from the character stream; refusals are in-world notices (`POTION_RECOVERING` with the backend's remaining time, `ITEM_NO_EFFECT`, others generic); available in travel, hidden while awaiting aid; combat untouched _(added 2026-11-09 evening)_
- [x] **HEAL-05**: `CharacterStatus.potionRecoveryUntil` (nullable date) and `LootItem.recovery { time, turns }` (nullable, lenient) are parsed; while the date is in the future every heal parchment is disabled with a countdown «pronta fra …» from the server date (local tick, no call); shop and Journal item rows show «Ricarica: …» humanised from `recovery.time` (`turns` not shown); the device E2E drinks a field herb, sees the countdown and the lore line; the `POTION_RECOVERING` notice on a second potion is proved by tests and by the orchestrator's GraphQL probe, the parchments being disabled during the countdown (D-19) _(added 2026-11-09 evening)_
- [x] **HEAL-06**: On the Board a quest whose per-viewer `noEffect` is true (backend-owned: a `heal` that would change nothing for the current character) is drawn as an already torn sheet that cannot be torn or accepted; the list is reread silently when the character's HP or injuries change, so the sheet becomes whole again when the heal is useful; a `QUEST_NO_EFFECT` refusal shows an in-world notice; `noEffect` parsed leniently (missing → false); no rule computed on the FE _(added 2026-11-10, user rule during the plan)_

### Model Review companion (Phase 19, added 2026-11-09)

- [x] **MODEL-01**: Enemy, lore and POI follow the cleaned SDL: `Enemy.weaknesses { base, energy }` parsed leniently (unknown names dropped) and read where the two lists were read; `Lore.imagePath` replaces `image`; `PointOfInterest.quest` leaves fragment and model; `Enemy.spells` and `CityShop` unchanged on the wire
- [x] **MODEL-02**: `CharacterAssets.ownedPets` parsed as entries `{ pet, xp, currentLifePoints }` (malformed entry dropped), «Compagni» list and «Compagno» slot on the entry's catalogue pet, companion row «Esperienza: N / maxXp», `Pet.attack`/`Pet.defense` instead of `damages` on the companion card (defense shown when not empty), result sheet «Il tuo compagno guadagna N PE» from `QuestResult.petXpGained` when above 0; the catalogue `Pet` no longer carries `xp`/`currentLifePoints`
- [x] **MODEL-03**: `wornEquipment` and the `feet` slot replace the old names (fragment, model, `SlotType`, mannequin, equip request); the Journal spells section reads the single `spellStates` list with `active` (known = all, equipped = active, usages and recovery from the same entry), `CharacterStatus.spells` and `CharacterAssets.activeSpells` no longer selected, optimistic rollback adapted; `maxActiveSpells` unchanged
- [x] **MODEL-04**: FE-only fixes before the gated plans: `PointOfInterest.fromJson` builds a `List<PoiType>` and guards `location`; sweep of the models for the same fragile patterns with a pinned test per fix; schema gate on the merged BE SDL and device E2E (Journal companions, spells and mannequin; a fight with the equipped companion; Map; Library)

### Rank-Specific Prizes for Group Quests (Phase 20, added 2026-11-13)

- [x] **RANKP-01**: The quest sheet (Board and Map) shows the prize block the BE serves for the viewer, with today's rows; the app never chooses a block
- [x] **RANKP-02**: Mixed-rank bosses: one seat line per title, registration and party counter judged per seat title as the BE does
- [x] **RANKP-03**: Result sheet: one dungeon-turn line (dungeon and dungeon aid) printed from the BE fields, lenient parsing, the stages line kept as fallback
- [x] **RANKP-04**: Schema gate on the merged BE SDL, schema check green, device E2E covering rank blocks, mixed boss, dungeon aid by turns and the aid fixes visible on the FE

### Innkeeper Mission Completion Flow (Phase 21, added 2026-11-14)

- [ ] **GMFLOW-01**: Step 1: the group pawn drops on city markers and inner POIs (POI layer in teleport mode, own drop rule), skip when the group already stands on the place; after the Map round trip the Locanda reopens the wizard of that request
- [ ] **GMFLOW-02**: Wizard shell over the served draft: explicit start, resume at the served step from any device, back navigation, discard with confirmation, exits when the request is gone; no local persistence
- [ ] **GMFLOW-03**: Encounters: one or several fights, each with enemies × quantity picked from the served list (search, «Mostra tutti»); the app never filters by rank, habitat or POI type
- [ ] **GMFLOW-04**: Per fight: «Simula» / «Rilancia» on the BE engine, outcome read as served, corrections within served bounds (life slider, injuries of this mission removable, consumables and spells), invalidation shown from the served draft
- [ ] **GMFLOW-05**: Prizes per character: served prefilled rank block, entries removable, additions from the served catalogue, free coins and xp
- [ ] **GMFLOW-06**: Completion: recap, explicit confirmation, `completeGuidedMission`, results recap, failure mapping per code; the Phase 10 override form is retired
- [ ] **GMFLOW-07**: Players: the two served mission flags read live; pawn label only for the guided flow; travel, acceptance, shop, equipment, companion, spells and potions hidden or disabled in every mission in progress; `MISSION_IN_PROGRESS` mapped in every classifier of the locked actions
- [ ] **GMFLOW-08**: Schema gate on the merged BE Phase 22 SDL, schema check green, full suite, device E2E with an innkeeper and a participant

## Future Requirements

Deferred beyond v1.1. Tracked but not in the current roadmap.

- **FUT-01**: Round-by-round combat log with replay
- **FUT-03**: Village visual with clickable buildings showing available quests
- **FUT-04**: Full accessibility pass (screen reader support, large text, motor-impairment affordances)
- **FUT-05**: Live position sharing: the pawns of the other players of a room move on the Map in real time (about 50 players per room), a player can create their own room and join or leave one; the server owns rooms and positions, the FE renders the pawns with the same interpolation as its own (BE-FUT-06) _(added 2026-11-09)_
- **CHAR-06** (carried from v1.0): client-side NSFW pre-screen of the portrait — known gap; the authoritative moderation is server-side (BE Phase 10) and its codes are mapped by the FE. To be decided: implement or drop.

## Out of Scope

| Feature | Reason |
| ------- | ------ |
| Any game rule on the device (cure, recovery, companion xp, food, life) | The backend is the source of truth; the FE filters and formats only |
| Travel food and life changes on the FE (BE Phase 20) | No change on the wire: inventory and HP keep arriving from the character stream |
| Single inventory list, spell `damages` / `requiredLearnTime`, combat rules | Excluded from the model review by the Phase 19 discuss (separate session) |
| «Log out from every device», live position rooms (FUT-05), iOS, accessibility pass | Backlog after v1.1 (user decision 2026-11-10: only the three discussed phases) |
| Everything listed as Out of Scope in `PROJECT.md` | Unchanged from v1.0 |

## Traceability

| Requirement | Phase | Status |
| ----------- | ----- | ------ |
| HEAL-01 | Phase 18 | Complete |
| HEAL-02 | Phase 18 | Complete |
| HEAL-03 | Phase 18 | Complete |
| HEAL-04 | Phase 18 | Complete |
| HEAL-05 | Phase 18 | Complete |
| HEAL-06 | Phase 18 | Complete |
| MODEL-01 | Phase 19 | Complete |
| MODEL-02 | Phase 19 | Complete |
| MODEL-03 | Phase 19 | Complete |
| MODEL-04 | Phase 19 | Complete |
| RANKP-01 | Phase 20 | Complete |
| RANKP-02 | Phase 20 | Complete |
| RANKP-03 | Phase 20 | Complete |
| RANKP-04 | Phase 20 | Complete |
| GMFLOW-01 | Phase 21 | Pending |
| GMFLOW-02 | Phase 21 | Pending |
| GMFLOW-03 | Phase 21 | Pending |
| GMFLOW-04 | Phase 21 | Pending |
| GMFLOW-05 | Phase 21 | Pending |
| GMFLOW-06 | Phase 21 | Pending |
| GMFLOW-07 | Phase 21 | Pending |
| GMFLOW-08 | Phase 21 | Pending |

**Coverage:** 22 / 22 v1.1 requirements mapped (6 HEAL → Phase 18, 4 MODEL → Phase 19, 4 RANKP → Phase 20, 8 GMFLOW → Phase 21). No orphans. No duplicates.

---

_Requirements defined: 2026-11-10 (v1.1 start; HEAL and MODEL text from the discuss sessions of 2026-11-09)_
