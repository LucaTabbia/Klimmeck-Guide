# Phase 17: Unlockable Lore - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-07
**Phase:** 17-unlockable-lore (FE), discussed together with the BE Phase 16 from this repo (the FE Phase 16 was parked at 7/8 the same day because the phone was unavailable; both device UATs run at the end of this phase)
**Areas discussed:** Dati e wire, Geografia, Nemico noto, Studio (BE foundations); Foglio esiti, Fuori Biblioteca, Ritratto, Biblioteca (FE)
**Mode:** interactive, 2 `AskUserQuestion` calls of four questions each, shared with the BE discuss; facts read before the questions (BE lore module, models, resolution/travel/acceptance code paths, FE Library/Map/sheet code, two read-only DB inventories: 473 lore by type and links, 167 cities all with a city page linking 1–3 regions and 1 state, 206 enemies all with 1–2 lore of which 16 bestiary pages shared, 750 quests, 30 study quests, 4 characters). No area multi-select: the phase has three requirements and every area was asked. The BE side is in `../Klimmeck-Guide-BE/.planning/phases/16-lore-sbloccabili/16-DISCUSSION-LOG.md`.

---

## Dati e wire (BE foundation)

| Option | Description | Selected |
|--------|-------------|----------|
| Lista di id sul personaggio (Recommended) | `Character.status.unlockedLore: [ID!]!` at DB and on the wire; the FE refetches `lores` only when the list changes and knows which entries are new (~26 B per lore per event) | ✓ |
| Solo un contatore sul filo | List at DB, `status.unlockedLoreCount: Int!` on the wire | |
| Nulla sul filo | Internal list; the FE refetches on every `characterUpdated` while the Library is open | |
| Collezione dedicata | `characterlore { character, lore, unlockedAt, source }` + ids on the wire; `characterUpdated` re-emitted by hand | |

## Geografia (BE foundation)

Data in the question: every city lore links 1 state and 1–3 regions (88 → 1, 74 → 2, 5 → 3); 17 regions, 8 states; e.g. Murnborim → Regno della Madre, Lamstone, Lontano Nord. Arrival = city marker (POI type `city`); the 475 territory POIs do not count.

| Option | Description | Selected |
|--------|-------------|----------|
| Città + regioni + stato, nascita e arrivo (Recommended) | Same package at birth and at every arrival; no cascade on other linked lore | ✓ |
| Nascita città + regioni; arrivo solo città | Literal 2026-10-29 reading: 16 regions and 8 states never unlock by travelling | |
| Città + regioni, nascita e arrivo (niente stati) | States only from the study roll | |

## Nemico noto (BE foundation)

Data: 206 enemies with 1–2 lore (167 enemy, 43 animal, 2 character); 116 bestiary pages for 167 enemies, 16 shared (Draghi cuccioli 8, Draghi adulti 8, Licantropo 6, Orchi e goblinoidi 6, Goblin 4, Golem 3…).

| Option | Description | Selected |
|--------|-------------|----------|
| Conosce la specie (Recommended) | `known` = every lore of the enemy unlocked; a Goblin victory clears the 4 goblins; no second set at DB | |
| Solo il nemico esatto sconfitto | Second set `knownEnemies` (ids) at DB; the «Goblin» page opens but the Goblin boss stays dark until beaten | ✓ |

## Studio (BE foundation)

Data: 30 «Ricerche in biblioteca a <città>» quests, none with a fixed or drawn spell; pool of 110 lore (knowledge 13, god 18, religion 18, ceremony 18, material 9, state 8, character 26).

| Option | Description | Selected |
|--------|-------------|----------|
| Sempre, 100 % (Recommended) | Env-configurable default 1, deterministic UAT | |
| 50 % | Half of the studies teach nothing, like a roll | ✓ |
| 25 % | Rare | |

## Foglio esiti

| Option | Description | Selected |
|--------|-------------|----------|
| Studio e prima pagina del bestiario (Recommended) | «Conoscenza appresa: <nome>» after «Magia appresa» for the study, «Nuova pagina del Bestiario: <nome>» on a first victory; BE adds `QuestResult.loreUnlocked: [Lore!]!` with the new lore only | ✓ |
| Solo lo studio | Only the study line | |
| Nulla sul foglio | The player finds the new pages in the Library | |

## Fuori Biblioteca

Data: the Map city modal reads `City.relatedLore` (crashes today when null); narrative quest sheets show `infos.relatedLore` paragraphs (0 story/worldMission quests at DB; the 750 generated quests carry city + enemy lore but do not show it).

| Option | Description | Selected |
|--------|-------------|----------|
| Mappa: solo il nome; quest intere (Recommended) | BE resolves `City.relatedLore` to null for players until known → modal with the name and «Non conosci ancora questa città»; quest narrative stays whole | ✓ |
| Nessun filtro fuori dalla Biblioteca | The Map shows everything as today | |
| Filtro ovunque | Quest paragraphs also hide locked lore | |

## Ritratto

| Option | Description | Selected |
|--------|-------------|----------|
| Silhouette nera (Recommended) | Full shadow on the shape (alpha of the SVG/raster) | ✓ |
| Sbiadito in grigio | Desaturated, dimmed | |
| Sfocato | Blur | |

## Biblioteca

Stated defaults in the question: sections without unlocked pages hidden; an empty book shows one status line (copy to Claude).

| Option | Description | Selected |
|--------|-------------|----------|
| Nessun segno (Recommended) | The book shows the unlocked pages, live while open | |
| Segnalibro «Nuovo» | Entries unlocked since the last opening of that book carry a mark until the book is reopened (per character, on the device) | ✓ |

## Claude's Discretion

Copy, bookmark look, silhouette ink, refetch debounce, where the id comparison lives, fixture and store naming, `LoreRef` shape, the test harness for the live refresh.

## Deferred Ideas

Lore hyperlinks (v2); lore detail page; images for non-city lore; filtering narrative quest paragraphs; species-level knowledge; cover badges on the initial page; common knowledge for every character.
