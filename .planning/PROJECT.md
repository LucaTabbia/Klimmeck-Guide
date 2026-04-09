# Klimmeck Guide

## What This Is

Un'app mobile Flutter che trasforma i punti canale Twitch in un RPG: i viewer di un singolo canale spendono punti canale che diventano valuta di gioco (1:1), usata per accettare quest. Un backend NestJS con MongoDB gestisce la logica di combattimento algoritmica, la mappa con spostamenti in tempo reale, e il sistema di ferite. Lo streamer funge da game master per le quest story e worldMission durante le live.

## Core Value

I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.

## Requirements

### Validated

- ✓ Modelli dati personaggio, equipaggiamento, ferite, quest — existing
- ✓ UI equipaggiamento con SVG caching (CachedSvg) — existing
- ✓ Menu zaino (SatchelMenu) con animazioni — existing
- ✓ Schermata info equipaggiamento (EquipmentInfoSheetDisplay) — existing
- ✓ Architettura BLoC/Cubit con layer repository — existing
- ✓ Comunicazione GraphQL (query, mutation, subscription) + REST — existing
- ✓ Mappa con flutter_map e coordinate LatLng — existing
- ✓ Sistema enums completo (12 tipi quest, 26 tipi ferite, 10 effetti ferite) — existing
- ✓ Navigazione a 6 tab (board, journal, library, map, shop, profile) — existing
- ✓ SVG caching multi-livello (memory, disk, network via Cloudinary) — existing
- ✓ Enum classi personaggio (ClassType) — existing

### Active

- [ ] Login OAuth Twitch con persistenza solo dell'ID account
- [ ] Integrazione API Twitch per ottenere punti canale spesi sul canale target
- [ ] Conversione 1:1 punti canale → valuta di gioco
- [ ] UI sistema quest: accettazione nei villaggi in base ai POI di influenza
- [ ] UI spostamento personaggio sulla mappa con timer reale basato su distanza e velocità strade
- [ ] UI pet/cavalcature come modificatori di velocità di spostamento
- [ ] UI esiti combattimento: visualizzazione risultato (nessun danno / ferite / morte)
- [ ] UI quest "aid" generate dalla morte di un personaggio
- [ ] UI quest "heal" per rimozione ferite presso ospedali/cliniche
- [ ] UI quest "job" sempre disponibili in tutti i villaggi
- [ ] UI quest "hunt", "enemy", "boss", "dungeon" con relativi flussi
- [ ] UI sistema livelli con visualizzazione HP e progressione
- [ ] UI sistema magie: 3 slot, sbloccati dopo title "mage" (3a quest story)
- [ ] UI apprendimento magie a Valantar (capital) tramite quest study
- [ ] UI magie con utilizzi limitati e recoveryTime
- [ ] UI negozi per acquisto equipaggiamento, cibo, oggetti
- [ ] UI pannello admin: lista pendingRequest per quest story/worldMission
- [ ] UI admin: spostamento istantaneo personaggio utente su qualsiasi POI
- [ ] UI admin: selezione mostri per POI e grado quest, scelta premi, applicazione ferite
- [ ] UI sezione lore (senza collegamenti tra oggetti)

### Out of Scope

- Gilde e arena — v2, richiede sistema sociale complesso
- Blog gilde — v2, dipende da sistema gilde
- Negozi contestuali per tipo — v2, v1 ha shop generico
- Villaggio visuale con case cliccabili — v2, refactor UI significativo
- Generazione quest tramite LLM — v2, richiede integrazione AI
- Upload e playback audio quest story/worldMission — v2, richiede storage media
- Speech-to-text per quest audio — v2, dipende da upload audio
- Sistema allineamento buono/cattivo (crime/guard) — v2, meccanica complessa
- Lore con link ipertestuali navigabili tra oggetti — v2
- Riepilogo quest completate con dettagli — v2

## Context

- **Codebase esistente:** App Flutter funzionante con architettura BLoC, modelli dati, UI equipaggiamento, mappa, e sistema di caching SVG multi-livello
- **Backend:** NestJS con MongoDB, già operativo, espone GraphQL (HTTP + WebSocket) e REST
- **Asset:** Immagini su Cloudinary (equipaggiamento, ferite, quest pawn)
- **Mappa:** Fissa, con POI gestiti manualmente dallo streamer. Strade con velocità di percorrenza
- **Canale Twitch:** Singolo canale target, lo streamer è anche l'admin/game master
- **Titoli personaggio:** adventurer → paladin → mage → hero (progressione tramite quest story)

## Constraints

- **Tech stack:** Flutter (mobile) + NestJS + MongoDB — già in uso, non negoziabile
- **Auth:** Solo OAuth Twitch, nessun account proprio — l'identità è l'ID Twitch
- **API Twitch:** Dipendenza esterna per i punti canale, soggetta a rate limit e disponibilità
- **Mappa:** POI e sfondo gestiti manualmente dallo streamer, non generati
- **Single channel:** L'app è legata a un solo canale Twitch

## Key Decisions

| Decision                                        | Rationale                                                      | Outcome   |
| ----------------------------------------------- | -------------------------------------------------------------- | --------- |
| Conversione punti 1:1                           | Semplicità, trasparenza per i viewer                           | — Pending |
| Backend NestJS + MongoDB                        | Stack già esistente e funzionante                              | ✓ Good    |
| Stats solo da equipaggiamento (no stats innate) | Semplifica bilanciamento, le classi sono solo flavor narrativo | — Pending |
| Magie sbloccate dopo 3a quest story             | Gate di progressione narrativa, evita overload iniziale        | — Pending |
| Morte genera quest aid                          | Meccanica sociale emergente tra giocatori                      | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):

1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):

1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---

_Last updated: 2026-04-10 after initialization_
