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

- [x] **GMFLOW-01**: Step 1: the group pawn drops on city markers and inner POIs (POI layer in teleport mode, own drop rule), skip when the group already stands on the place; after the Map round trip the Locanda reopens the wizard of that request
- [x] **GMFLOW-02**: Wizard shell over the served draft: explicit start, resume at the served step from any device, back navigation, discard with confirmation, exits when the request is gone; no local persistence
- [x] **GMFLOW-03**: Encounters: one or several fights, each with enemies × quantity picked from the served list (search, «Mostra tutti»); the app never filters by rank, habitat or POI type
- [x] **GMFLOW-04**: Per fight: «Simula» / «Rilancia» on the BE engine, outcome read as served, corrections within served bounds (life slider, injuries of this mission removable, consumables and spells), invalidation shown from the served draft
- [x] **GMFLOW-05**: Prizes per character: served prefilled rank block, entries removable, additions from the served catalogue, free coins and xp
- [x] **GMFLOW-06**: Completion: recap, explicit confirmation, `completeGuidedMission`, results recap, failure mapping per code; the Phase 10 override form is retired
- [x] **GMFLOW-07**: Players: the two served mission flags read live; pawn label only for the guided flow; travel, acceptance, shop, equipment, companion, spells and potions hidden or disabled in every mission in progress; `MISSION_IN_PROGRESS` mapped in every classifier of the locked actions
- [x] **GMFLOW-08**: Schema gate on the merged BE Phase 22 SDL, schema check green, full suite, device E2E with an innkeeper and a participant

### Companion Defeat, Rest and Recovery (Phase 22, added 2026-11-14)

- [x] **PET-01**: Companion state parsed leniently on `OwnedPet` (name, defeated, `lifeAsOf`, `fullLifeAt`, `potionRecoveryUntil`) and `Pet` (`recoveryTime`, `maxLifePoints`, `imagePath`); the catalogue pet id is the only key; one display-name function (name, else species) for every wording; vitality (life now, resting or defeated, remaining, potion wait) derived only from served dates and the server clock, never from `recoveryTime`
- [x] **PET-02**: Journal «Compagno»: «Vita: x / max» rising live while resting, «A riposo: in forze fra …», a defeated parchment faded and not tappable with «Sconfitto: torna fra …» and re-enabled locally at `fullLifeAt`; the slot shows the equipped companion's life; the name is the title and the species sits below
- [x] **PET-03**: Companion cards with the pet image, restyled like spell and equipment cards, in the Journal, the shop list and basket, the quest-sheet prize and the innkeeper prize rows; a long press opens the companion details sheet (life, rest, potion wait, recovery time, attack, defense, speed, xp, rename entry); the result sheet keeps its text line
- [x] **PET-04**: Potion sheet: «Bevi» plus one «Dai a <nome>» parchment per eligible companion (not defeated, below full life, no wait of its own); the potion row is tappable when the character or a companion can drink and «Bevi» is disabled during the character's wait; `useItem` with the target pet; `PET_DEFEATED`, `PET_POTION_RECOVERING` and `ITEM_NO_EFFECT` mapped with the companion's name; `PET_DEFEATED` on `equipPet` mapped
- [x] **PET-05**: Companion name: prompt after a shop purchase and after a result with a prize companion (one each, skippable), rename from the details sheet, the character-name form rules client-side (2–20 characters: letters, spaces, apostrophes, hyphens), `PET_NAME_INVALID` notice with retry or skip, not locked by «Missione in corso»; a named companion reads its name in every wording, the shop sell list included
- [x] **PET-06**: Result sheet and ambush pages: the companion life line when its life dropped, the defeat line with the duration `fullLifeAt − resolvedAt`, the xp line with the name, «Prosegui a piedi» from `AmbushReport.onFoot`
- [x] **PET-07**: Ambushes and pushes: unseen ambush reports opened at the Map also mid-travel (existing queue), the recomputed or redirected travel read from the stream, one «Imboscate» category accepting `ambush` and `ambushDefeat` with the banner suppressed when the carousel opens live, a new «Compagno in forze» category (`petRecovered`) with its toggle
- [x] **PET-08**: Innkeeper corrections: a companion life slider next to the character's within served bounds (1 = defeated, marker «Sconfitto»), sent as `companionLifeAfter` in the per-fight correction only when the participant has a companion
- [x] **PET-09**: Schema gate on the merged BE Phase 23 SDL (gated selections, `UseItem` target, the one switch flipped, registry 55, schema check, full suite) and device E2E
- [x] **PET-10**: Companion levels: `OwnedPet.level` and the companion's own `maxLifePoints` read from the wire (lenient: level hidden while absent, the species' max as fallback) through one getter used by every reader of the companion's max; «Livello N» shown in the details sheet and next to the species on the Journal parchment; the app never computes a level, a threshold or a max

### Spell Origins, Void and Shamanic Quests (Phase 23, added 2026-11-15)

- [x] **ORIGIN-01**: `SpellOrigin` (wire `void` / `arcane` / `shamanic`, Dart `theVoid` / `arcane` / `shamanic`, labels «Vuoto» / «Arcana» / «Sciamanica») parsed leniently on `Spell.origin` through an explicit wire name; an unknown or absent origin reads null, the spell stays and nothing is drawn for it
- [x] **ORIGIN-02**: A spell prints the minimum **level** the backend sends («Per impararla: Livello N», no learn time: D-28); `minXpToLearn` leaves the model, the fragments and the copy; the app never computes or compares a level
- [x] **ORIGIN-03**: The three school quest types are `arcane` (renamed from `magic`, label «Magia», the legacy wire value `magic` still read as `arcane` and never written), `shamanic` («Rito sciamanico») and `void` («Rito del Vuoto», Dart `theVoid`): the two new types behave exactly like the arcane one (standard lane, repeatable, unregistered, service sheet, «Ricercando…» while the research runs (D-26, D-32), torn until the rank) with their own whole and torn sheets; the quest type crosses the wire only through `wireName` / `fromWire`
- [x] **ORIGIN-04**: City types `aarakocraCapital`, `dragonbornCapital` (marker 39) and `dragonbornVillage` (marker 30) parse and draw; visibility by the served size, no `alwaysVisible`; `aarakocraVillage` drawn with the new file
- [x] **ORIGIN-05**: The origin icon sits before the use and energy icons wherever a spell is drawn with icons (spell card, spell details with «Origine: …»); three icons never overflow the card; a spell without origin is drawn as before
- [x] **ORIGIN-06**: Schema gate on the merged BE Phase 24 SDL (`origin` and `minLevelToLearn` selected, registry 55, schema check, full suite) and device E2E, the origin lore unlocked by the first learned spell of an origin included (surfaced by the existing lore-unlock path, no new selection)
- [x] **ORIGIN-07**: A quest with a spell draw shows its two parts in session from the served pending quest: «Ricercando…» while the draw quest runs (its «Fase di ricerca», D-32) (school types, or `prizes.spellDraw`), and during the learning part the name of the spell being learned with a countdown to `startDate + waitingTime`; `PendingQuest.learningSpell`, `QuestPrizes.spellDraw` parsed leniently; no blocking loading, no app chrome, nothing computed beyond that date (D-26, D-29)
- [x] **ORIGIN-08**: The research outcome reaches the player: the result sheet of a research with a spell found shows the spell and its learning time (`QuestResult.spellFound`), a failed research reads its own line (`spellResearchFailed`), the small sheet at the end of the learning reads well without gains; the pushes `spellResearchSucceeded` and `spellResearchFailed` open the result like `questEnd`; schema check green on the BE SDL with the research fields and device E2E (D-29, D-31)

### Participants' Stories and Innkeeper Wounds (Phase 24, added 2026-11-21)

- [ ] **STORY-01**: The guided completion of a `story` / `worldMission` request opens on a reading page: one closed `Dropdown` per participant (name · rank), every background entry in the served order (oldest first), an in-world line for an empty story, the start note and «Inizia la missione» at the bottom; opening never creates the draft and a failed read never blocks the start; once the mission is started the page is reachable by «Indietro»; no popup anywhere (D-01..D-03, D-02a, D-10)
- [ ] **STORY-02**: After the recap a last page shows per participant the story so far (same dropdown) and one optional field with a 1000-character counter (UX only: the backend validates, `BACKGROUND_ADDITION_TOO_LONG` has its own line); the additions live in the served draft (`backgroundAdditions`, step `stories`), are found again after leaving, and ONE «Concludi» with the explicit confirmation saves them and completes the mission (D-04..D-08)
- [ ] **STORY-03**: The participant's result sheet reads «La tua storia ha una nuova pagina» only from the served `QuestResult.backgroundEntryAdded`; the existing wax sigil marks Profile and the appended entry with no new code, proved by tests (D-09)
- [ ] **STORY-04**: Schema gate on the merged BE Phase 25 SDL (new fields selected only there, the one switch flipped, registry 55, schema check, full suite) and device E2E of the stories and of the innkeeper wounds, with the FE `BACKEND-NOTES.md`
- [ ] **WOUND-01**: In the corrections of the guided flow (the only correction surface of the app) the innkeeper removes any wound the participant carries, sees which are his from the served `innkeeperInjuriesBefore` / `innkeeperInjuries`, and turns an ordinary wound into an innkeeper wound by removing it and adding it again in the same correction; a wound carried and not removed cannot be added; removals are sent as `injuriesRemoved` and listed in the recap; the app never derives an origin (D-12, D-13, D-16)
- [ ] **WOUND-02**: The player recognises an innkeeper wound (`CharacterStatus.innkeeperInjuries`, lenient): the Journal reads «Troppo grave per essere curata» under it; the quest sheet line «Cura le tue ferite: …» and the potion line «Cura: …» of the Journal and of the potion sheet leave it out; the Board is reread in silence when only the origin of a wound changes; no cure rule on the device (D-14, D-15)
- [ ] **WOUND-03**: The result sheet shows the wounds the innkeeper took off (`QuestResult.injuriesRemoved`, lenient) inside the one line «Guarite: …» together with `injuriesHealed`, without repeating a wound (D-18)

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
| GMFLOW-01 | Phase 21 | Complete |
| GMFLOW-02 | Phase 21 | Complete |
| GMFLOW-03 | Phase 21 | Complete |
| GMFLOW-04 | Phase 21 | Complete |
| GMFLOW-05 | Phase 21 | Complete |
| GMFLOW-06 | Phase 21 | Complete |
| GMFLOW-07 | Phase 21 | Complete |
| GMFLOW-08 | Phase 21 | Complete |
| PET-01 | Phase 22 | Complete |
| PET-02 | Phase 22 | Complete |
| PET-03 | Phase 22 | Complete |
| PET-04 | Phase 22 | Complete |
| PET-05 | Phase 22 | Complete |
| PET-06 | Phase 22 | Complete |
| PET-07 | Phase 22 | Complete |
| PET-08 | Phase 22 | Complete |
| PET-09 | Phase 22 | Complete |
| PET-10 | Phase 22 | Complete |
| ORIGIN-01 | Phase 23 | Complete |
| ORIGIN-02 | Phase 23 | Complete |
| ORIGIN-03 | Phase 23 | Complete |
| ORIGIN-04 | Phase 23 | Complete |
| ORIGIN-05 | Phase 23 | Complete |
| ORIGIN-06 | Phase 23 | Complete |
| ORIGIN-07 | Phase 23 | Complete |
| ORIGIN-08 | Phase 23 | Complete |
| STORY-01 | Phase 24 | Pending |
| STORY-02 | Phase 24 | Pending |
| STORY-03 | Phase 24 | Pending |
| STORY-04 | Phase 24 | Pending |
| WOUND-01 | Phase 24 | Pending |
| WOUND-02 | Phase 24 | Pending |
| WOUND-03 | Phase 24 | Pending |

**Coverage:** 47 / 47 v1.1 requirements mapped (6 HEAL → Phase 18, 4 MODEL → Phase 19, 4 RANKP → Phase 20, 8 GMFLOW → Phase 21, 10 PET → Phase 22, 8 ORIGIN → Phase 23, 4 STORY + 3 WOUND → Phase 24). No orphans. No duplicates.

---

_Requirements defined: 2026-11-10 (v1.1 start; HEAL and MODEL text from the discuss sessions of 2026-11-09)_
