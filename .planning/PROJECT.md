# Klimmeck Guide

## What This Is

Un'app mobile Flutter che trasforma i punti canale Twitch in un RPG: i viewer di un singolo canale spendono punti canale che diventano valuta di gioco (1:1), usata per accettare quest. Un backend NestJS con MongoDB gestisce la logica di combattimento algoritmica, la mappa con spostamenti in tempo reale, e il sistema di ferite. Lo streamer funge da game master per le quest story e worldMission durante le live.

## Core Value

I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.

## Current Milestone: v1.0 Core Loop

**Goal:** Chiudere il loop di gioco base — il viewer si logga via Twitch, riceve punti canale/stato personaggio via subscription, accetta quest con gesture swipe, viaggia con notifiche, vede esiti combattimento, gestisce magie possedute. Lo streamer amministra tutto via admin panel.

**Target features:**

- Auth Twitch (OAuth + refresh + logout/switch) e sezione Impostazioni
- Sync utente real-time via GraphQL subscription (punti canale, stato, progressione)
- Quest accept gesture (swipe-left "strappa foglio") + quest info sheets per tipo
- Viaggio con conferma (ETA + costo) e timer live
- Notifiche Firebase (FCM/APNs) + in-app per fine viaggio, streamer live, fine quest
- Magie nel tab diario: lista, equip/disequip, cooldown, utilizzi residui
- UI esiti combattimento: HP prima/dopo, consumabili + magie usati, ferite, premi, XP
- Admin panel completo: pendingRequest, teleport, gestione mostri/grado/premi/ferite
- Fase finale di hardening: bug fixing, security audit, gestione concurrency

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
- ✓ UI negozi (shop) per acquisto equipaggiamento, cibo, oggetti — existing
- ✓ Sezione lore (library) senza link ipertestuali — existing
- ✓ UI lista quest nel tab board — existing (quasi definitiva, solo layout info per tipo mancanti)

### Active

**v1.0 Core Loop (in corso):**

- [ ] Login OAuth Twitch con persistenza account ID + refresh token handling + logout/switch account
- [ ] Sezione Impostazioni (nuova) — logout + setting notifiche
- [ ] Sync utente via GraphQL subscription (punti canale, valuta, stato personaggio)
- [ ] Gesture swipe-left "strappa foglio" per accettare quest nel tab board (tutti i tipi)
- [ ] Layout quest info sheets distinti per tipo (hunt, enemy, boss, dungeon, heal, aid, job, study, story, worldMission)
- [ ] UI spostamento sulla mappa con timer live basato su distanza e velocità strade
- [ ] UI conferma viaggio con ETA + costo
- [ ] Notifiche Firebase (FCM/APNs) + in-app: fine viaggio, streamer live, fine quest
- [ ] Sezione Magie nel tab diario: lista, equip/disequip, cooldown, utilizzi residui
- [ ] UI esiti combattimento: HP prima/dopo, consumabili + magie usati, ferite subite, premi, XP
- [ ] Admin panel: lista pendingRequest story/worldMission
- [ ] Admin panel: spostamento istantaneo personaggio su qualsiasi POI
- [ ] Admin panel: selezione mostri/grado quest, scelta premi, applicazione ferite
- [ ] Hardening finale: bug fixing intensivo, security audit, gestione concurrency

**Future (post v1.0):**

- [ ] UI pet/cavalcature come modificatori di velocità di spostamento
- [ ] Log round-per-round esiti combattimento

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
- UI sistema livelli / progressione HP — backend only, frontend puramente reattivo ai valori calcolati dal server
- UI apprendimento magie a Valantar — backend only, gestito come outcome di quest study lato server
- UI sblocco slot magie dopo title "mage" — backend determina disponibilità slot, frontend visualizza stato

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

## Workflow Conventions

### Branching & PR (mandatory per ogni fase)

- **Inizio fase:** prima di qualsiasi lavoro di una fase, creare un branch nuovo partendo da `develop`:
  ```bash
  git checkout develop && git pull
  git checkout -b <prefix>/<phase-slug>
  ```
- **Prefissi consentiti** (Conventional Commits):
  - `feat/` — fasi che aggiungono nuove capability (es. `feat/dev-auth-stub`)
  - `fix/` — fasi di bug-fix mirato
  - `refactor/` — fasi di refactor/hardening senza nuove feature visibili
- **Slug del branch:** usare lo stesso slug della directory di fase (`.planning/phases/NN-<slug>/`), così Phase 1 → `feat/dev-auth-stub`.
- **Fine fase:** aprire una **PR verso `develop`** (non verso `main`). La PR è il punto di review prima del merge — ogni fase si chiude con una PR aperta che lo streamer/dev può controllare.
- **Niente push diretti su `develop` o `main`** durante una fase.

## Key Decisions

| Decision                                        | Rationale                                                                           | Outcome   |
| ----------------------------------------------- | ----------------------------------------------------------------------------------- | --------- |
| Conversione punti 1:1                           | Semplicità, trasparenza per i viewer                                                | — Pending |
| Backend NestJS + MongoDB                        | Stack già esistente e funzionante                                                   | ✓ Good    |
| Stats solo da equipaggiamento (no stats innate) | Semplifica bilanciamento, le classi sono solo flavor narrativo                      | — Pending |
| Magie sbloccate dopo 3a quest story             | Gate di progressione narrativa, evita overload iniziale                             | — Pending |
| Morte genera quest aid                          | Meccanica sociale emergente tra giocatori                                           | — Pending |
| Sync utente via GraphQL subscription            | Real-time di punti canale/stato/progressione senza polling; backend source of truth | — Pending |
| Progressione e apprendimento magie lato backend | Frontend puramente reattivo, riduce rischio desync e logica duplicata               | — Pending |
| Notifiche Firebase (FCM + APNs)                 | Stack standard cross-platform per push mobile; necessario per notifiche background  | — Pending |
| Quest accept via gesture swipe-left             | Feedback tattile "strappa foglio" coerente con tema diario, evita tap accidentali   | — Pending |

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

_Last updated: 2026-04-10 — milestone v1.0 Core Loop started_
