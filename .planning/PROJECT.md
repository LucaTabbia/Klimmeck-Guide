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
- Viaggio con conferma (distanza, durata ed ETA dal backend, nessun costo) e posizione live sulla rotta
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
- ✓ Notifiche push FCM + banner in-app per fine viaggio, streamer live, fine quest (Android; iOS rinviata; prompt del permesso cablato dalla Phase 7) — Phase 5 (2026-10-20)
- ✓ Accettazione quest con lo swipe-left "strappa foglio" (strappo orizzontale con feedback aptico, il BE resta il giudice: rifiuti mappati per `extensions.code` sul banner in-app, timeout client 15 s) e schede quest per famiglia (combat / narrativa con lore scorrevole / servizio) con indicatori di eleggibilità (titolo, slot per rango D-32, loot consigliato) e riga `Punti canale: saldo / costo`; board raggiungibile solo da un marker di città con le quest della città (worldMission comprese) e la sola story del titolo esatto, quest piene strappate per tutti/per rango, story e worldMission in parallelo alla corsia standard e strappate per il proprietario; foglio della quest standard sulla Map con etichetta di stato server-driven ("In viaggio" / per tipo, nessun countdown); parsing tollerante del catalogo editato a mano — Validated in Phase 6: Quest Accept & Info Sheets (E2E su Android 12/12 il 2026-10-22 contro BE develop con la Phase 8; QUEST-01..07 emendati; PR FE dopo la merge BE PR #11)
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
- ✓ Contratto `AuthTokenService` + stub dev backed da `.env` (bypass dell'autenticazione per sviluppo e QA) — Validated in Phase 1: Dev Auth Stub
- ✓ Sessione reale contro il backend: login Twitch via browser di sistema mediato dal BE (ticket monouso + challenge S256), refresh token in storage cifrato, refresh single-flight e proattivo, retry trasparente su HTTP/REST, ri-autenticazione WebSocket, logout atomico, `AuthGate` (Splash → SignIn → shell autenticata) — Validated in Phase 11: Auth & Session Bootstrap (login reale su device da verificare all'arrivo delle chiavi Twitch; lo stub dev resta selezionabile fino a Phase 12)

- ✓ Creazione personaggio: pagina post-login (utility screen, scheda-pergamena in landscape) con sesso, ritratto facoltativo da galleria/camera caricato su Cloudinary al submit (default `silhouette.jpeg`), nome, pronome, razza, classe, età limitata per razza dalla query `raceTraits`, background ≤ 500; mutation `createCharacter` e passaggio alla shell con il personaggio reale (id cablato rimosso); `AuthGate` si ricostruisce al cambio di `currentCharacter`; errori inline in italiano; ritratto nel Profilo tramite `CharacterPortrait` — Validated in Phase 2: Character Creation (CHAR-06 pre-screen NSFW rinviato dall'utente; set curato di ritratti rinviato)
- ✓ Sync utente e personaggio in tempo reale: subscription GraphQL `userUpdated` (consumatore unico che alimenta la sessione) e `characterUpdated` (hardening), socket keep-alive con token corrente a ogni `connection_init`, riconnessione silenziosa con backoff e snapshot, refetch su resume, watchdog del tempo degradato che chiude la sessione dopo ~3 min con "Connessione persa, accedi di nuovo.", FORBIDDEN/NOT_FOUND terminali, shell ricreata al cambio personaggio, teardown pulito — Validated in Phase 3: Real-Time Sync Foundation (E2E approvato su Android il 2026-10-14; `activeTravel`/`activeStoryQuest`/`activeWorldMissionQuest` rinviati alle Phase 6/7 per D-05; PR FE verso develop solo dopo la merge della PR BE Phase 3, D-04)
- ✓ Sezione Impostazioni: settima voce della borsa (griglia Mappa 1x2 + 2x3, icona `settings_linee3.svg`), tab utility su pergamena con tre toggle notifiche (fine viaggio, streamer live, fine quest) persistiti per utente in `shared_preferences` con toggle ottimistico e rollback all'ultimo valore salvato, logout tramite il dialog di conferma condiviso, eliminazione del personaggio con conferma esplicita via `deleteCharacter` (soft delete lato BE), progress nel bottone, errori inline per codice e passaggio alla pagina di creazione (riuso dello stesso nome ammesso) — Validated in Phase 4: Settings Screen (E2E approvato su Android il 2026-10-18 contro BE develop con la Phase 03.1; i toggle vengono consumati dalla Phase 5)
- ✓ Viaggio: drag della pedina su una città → foglio di pergamena con distanza, durata ed ETA dal backend (`travelPreview`, nessun costo) e rotta tratteggiata, "Parti"/"Resta"; pedina che avanza sulla rotta interpolata sull'ora del server (offset `serverTime`, l'orologio del telefono non la sposta) con il solo tempo residuo sopra, ricostruzione dopo un kill da `activeTravel`, arrivo con push "Viaggio completato" o banner in-app e scatto su `characterUpdated`, viaggio automatico delle quest senza push, rifiuti `TRAVEL_IN_PROGRESS`/`QUEST_IN_PROGRESS` sul banner per codice, Bacheca e Negozio solo su un marker di città e mai in viaggio — Validated in Phase 7: Travel (E2E su Android il 2026-10-26, passi 1-11 pass, contro il BE con la Phase 8 travel lifecycle; TRAVEL-02/03 emendati)
- ✓ Sezione Magie nel Diario: lista delle magie conosciute con carta, descrizione e riga compatta «Usi · Recupero/prossimo tra X · Attacco: Fuoco 12», slot guidati da `maxActiveSpells` con segnalibro e contatore a matita, tap = toggle ottimistico con rimbalzo e banner per codice, long-press = foglio di pergamena, countdown dal tempo server su `status.spellStates[].recoveries` (BE 9.1: il recupero non si interrompe mai), filtri a chip per `useType` (magie) ed `effect` (oggetti del Diario e negozio, solo i tipi presenti), label italiane di `EffectType` e riga «Cura: 12» sugli oggetti — Validated in Phase 8: Spells Section (device UAT 12/12 il 2026-10-27)
- ✓ Foglio esito missione: pergamena a schermo intero con titolo e tipo della quest, nemico, barra vita animata da `hpBefore` a `hpAfter` contro il massimo, ferite con label italiane, consumabili e magie usati, premi, XP, livello/titolo solo se cambiano, magia appresa e «Hai salvato N avventurieri»; un solo widget per i cinque esiti (inchiostro scuro e «Riposa in pace» per la morte), chiusura solo col bottone (scrim, back e swipe ignorati); presentato solo sulla Mappa libera (altrove il banner porta lì), coda FIFO per `resolvedAt` con «1 di N»; tre sorgenti deduplicate per id (subscription, tap del push `questEnd`, `unacknowledgedQuestResults` a cold start/resume/riconnessione) e ack alla chiusura, così nessun esito va perso; foglio di morte prima della pagina di creazione anche a cold start (il BE tiene `currentCharacter` sul morto fino all'ack); stato ferito sulla Mappa («In attesa di soccorso», pedina, Bacheca e Negozio disabilitati) e quest `aid` nella famiglia combattimento; quest avviata strappata fino alla conclusione (posti tenuti dal BE 9.2) — Validated in Phase 9: Combat Result Sheet (device UAT 12/12 il 2026-10-29 contro BE develop `8f30d1d` con la Phase 9.2)

### Active

**v1.0 Core Loop (in corso):**

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
| Sync utente via GraphQL subscription            | Real-time di punti canale/stato/progressione senza polling; backend source of truth | ✓ Good — Phase 3 (2026-10-14) |
| Progressione e apprendimento magie lato backend | Frontend puramente reattivo, riduce rischio desync e logica duplicata               | — Pending |
| Notifiche Firebase (FCM + APNs)                 | Stack standard cross-platform per push mobile; necessario per notifiche background  | ✓ Validated on Android by Phase 5 (2026-10-20): data-only FCM + local notifications; iOS/APNs deferred |
| Quest accept via gesture swipe-left             | Feedback tattile "strappa foglio" coerente con tema diario, evita tap accidentali; lo swipe è la conferma (nessun dialog, nessun undo), il BE resta il giudice e gli errori arrivano sul banner in-app per codice | ✓ Good — Phase 6 (2026-10-22): 12 plan + 3 quick task, 1350 test verdi, E2E 12/12 su device; strappo orizzontale deciso in UAT (D-06), worldMission legata alla città (D-11), visuali provvisorie (D-19) |
| Login Twitch mediato dal backend, sessione propria del BE | Twitch non supporta PKCE, richiede `client_secret` e non accetta redirect con custom scheme: l'app non può completare l'OAuth da sola. Il BE custodisce il secret ed emette access JWT + refresh token; l'app non vede mai un token Twitch | ✓ Good — Phase 11 (2026-10-06) |
| Dev bypass mantenuto accanto all'auth reale | Le chiavi Twitch non sono ancora disponibili: `DEV_AUTH_ENABLED=true` tiene l'app interamente utilizzabile; rimozione dai build release in Phase 12 | ✓ Good — Phase 11 (2026-10-06) |
| Creazione personaggio: pagina unica provvisoria, BE fonte di verità per età/razza e stato iniziale | L'utente ha chiesto un layout provvisorio subito dopo la login; la tabella età per razza (dal lore) e le patrie vivono nel BE ed arrivano via `raceTraits`, il FE non duplica regole | ✓ Good — Phase 2 + BE Phase 02.1 (2026-10-09) |
| Niente filtro NSFW e niente set curato di ritratti in v1 Phase 2 | Scelta esplicita dell'utente (2026-10-08): velocità del layout provvisorio; CHAR-06 rinviato all'hardening (Cloudinary AI moderation lato BE) | — Pending (debito tracciato in REQUIREMENTS e BE-HARD) |
| Impostazioni come utility screen: preferenze notifiche solo sul device, cancellazione personaggio come soft delete BE | I toggle sono non sensibili e per utente (`shared_preferences`, nessun contratto BE: la Phase 5 filtra lato client); l'eliminazione resta identity-bound e archiviata dal BE (Phase 03.1) così nome e storico restano consultabili e riutilizzabili | ✓ Good — Phase 4 + BE Phase 03.1 (2026-10-18) |
| Usi e recuperi delle magie appartengono alla magia conosciuta, non allo slot (BE 9.1); filtri di Diario e negozio solo sui tipi presenti | Regola dell'utente «il timer di recupero non si interrompe mai»; equip/disequip neutri; chip senza risultati vuoti, base per una fase futura | ✓ Good — Phase 8 (2026-10-27) |
| Esiti mai persi: ack esplicito alla chiusura e `currentCharacter` sul morto fino all'ack (BE 9.2); foglio solo sulla Mappa | Push persi, notifiche disattivate e force-stop non devono far perdere un esito; il foglio di morte deve precedere la creazione anche a cold start senza hold lato FE; la Mappa è il solo luogo sicuro per un foglio a schermo intero | ✓ Good — Phase 9 (2026-10-29): device UAT 12/12; banner sulla Mappa occupata confermato dall'utente |

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

_Last updated: 2026-10-22 — after Phase 6 completion (quest accept with the tear gesture, per-type info sheets, lanes and torn-for-everyone rules, server-driven state label on the Map; device E2E 12/12; FE PR to develop opened after the security audit)_ · _Last updated: 2026-10-26 — after Phase 7 completion (travel with the pawn drag, parchment confirmation, server-time interpolation, restart-safe reconstruction; device E2E steps 1-11 pass)_ · _Last updated: 2026-10-27 — after Phase 8 completion (spells section with backend-driven slots, optimistic toggle, server-time recovery countdown, use-type and effect filters, item effect lines; device UAT 12/12; FE PR to develop opened after the security audit)_ · _Last updated: 2026-10-29 — after Phase 9 completion (combat result sheet on the Map with FIFO queue, never-lost results through the BE 9.2 ack, death sheet before creation, wounded state and aid as combat; device UAT 12/12; FE PR to develop after the F1 fix)_
