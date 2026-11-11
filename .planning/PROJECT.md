# Klimmeck Guide

## What This Is

Un'app mobile Flutter (Android) che trasforma i punti canale Twitch di un singolo canale in un RPG persistente: il viewer entra con il login Twitch mediato dal backend, crea il personaggio, accetta quest con il gesto «strappa foglio», viaggia sulla mappa in tempo server consumando cibo e rischiando imboscate, legge gli esiti dei combattimenti su una pergamena che non va mai persa, equipaggia magie, compra nei negozi di città e sblocca le lore del mondo. Il backend NestJS + MongoDB è la fonte di verità di ogni regola (progressione, combattimento, economia, viaggi, generazione delle quest); l'app è reattiva alle subscription GraphQL. Lo streamer (ruolo `innkeeper`) è il game master dalla Locanda.

## Core Value

I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.

_Confermato alla chiusura della v1.0 (2026-11-10): il loop regge sul device senza lo streamer presente (quest generate dal server, viaggi, imboscate, lore) e la Locanda copre la parte live._

## Current State: v1.0 Core Loop — SHIPPED 2026-11-10

- **17 fasi, 180 piani, 131 task**, 10 quick task; archivio in `.planning/milestones/v1.0-ROADMAP.md` e `v1.0-REQUIREMENTS.md`, riepilogo in `.planning/MILESTONES.md`.
- **Requisiti:** 110/111 completi; CHAR-06 (pre-screen NSFW lato client) rinviato per scelta dell'utente — la moderazione autoritativa è server-side (BE Phase 10) e i suoi codici sono mappati dalla FE.
- **Codebase:** ~36 000 righe Dart in `lib/` (491 file), ~65 000 righe di test (394 file), 3 704 test verdi, analyzer 0 errori / 0 warning, CI GitHub Actions verde sulla PR #45.
- **Release:** entry point di produzione `lib/main.dart` senza bypass dev (`lib/main_dev.dart` + `--flavor dev` per lo sviluppo), bundle senza `.env`, firma con keystore fuori VCS, solo TLS, log spenti; esercitata su Samsung + emulatore con il login Twitch reale attraverso un tunnel TLS.
- **Backend companion:** milestone BE v1.0 chiusa lo stesso giorno (21 fasi, 261 piani, `develop` `9973fcb1`).

## Current Milestone: v1.1 Healing & Models

**Goal:** le quest di cura smettono di essere tutte uguali e le pozioni si bevono dal Diario, mentre l'app segue i modelli ripuliti del backend senza cambiare ciò che il giocatore vede, tranne l'esperienza del compagno.

**Target features:**

- **Phase 18 — Heal quests by size** (↔ BE Phase 18): foglio della quest con le sole ferite del personaggio che la quest cura e la riga della vita («Vita: almeno il N%»), «Guarite: …» sul foglio esito; pozioni bevute dal Diario con conferma in-world, ricarica globale del backend (conto alla rovescia «pronta fra …», riga «Ricarica: …») e lore «Il limite del corpo».
- **Phase 19 — Model review** (↔ BE Phase 19): `Enemy.weaknesses`, compagni posseduti con esperienza e «Il tuo compagno guadagna N PE», `Pet.attack`/`Pet.defense`, `wornEquipment`/`feet`, una sola lista di magie con `active`, via `PointOfInterest.quest`, `Lore.imagePath`, parser fragili sistemati.
- La BE Phase 20 (cibo e vita progressivi in viaggio) non ha una fase FE: nessun cambio sul filo.

**Scope (decisione dell'utente, 2026-11-10):** solo le fasi già discusse il 2026-11-09; il resto del backlog resta dopo la v1.1. Requisiti in `.planning/REQUIREMENTS.md` (HEAL-01..06, MODEL-01..04), fasi in `.planning/ROADMAP.md`.

## Requirements

### Validated

- ✓ Modelli dati personaggio, equipaggiamento, ferite, quest; architettura BLoC/Cubit con repository; GraphQL (query, mutation, subscription) + REST; mappa `flutter_map`; enum completi; navigazione a 6 tab; SVG caching multi-livello; UI negozi, lore e lista quest — existing (brownfield mappato in `.planning/codebase/`)
- ✓ Contratto `AuthTokenService` + stub dev backed da `.env` — v1.0 Phase 1 (2026-04-15)
- ✓ Sessione reale contro il backend: login Twitch via browser di sistema mediato dal BE (ticket monouso + challenge S256), refresh in storage cifrato, refresh single-flight e proattivo, retry trasparente, ri-autenticazione WebSocket, logout atomico, `AuthGate` — v1.0 Phase 11 (2026-10-06; login reale su device provato il 2026-10-20 e sulla release firmata il 2026-11-09)
- ✓ Creazione personaggio: pagina post-login con sesso, ritratto facoltativo caricato su Cloudinary, nome, pronome, razza, classe, età per razza da `raceTraits`, background; `createCharacter` e passaggio alla shell — v1.0 Phase 2 (2026-10-09; CHAR-06 pre-screen NSFW e set curato di ritratti rinviati)
- ✓ Sync utente e personaggio in tempo reale: `userUpdated` e `characterUpdated`, keep-alive con token corrente, riconnessione silenziosa con backoff, refetch su resume, watchdog del tempo degradato, FORBIDDEN/NOT_FOUND terminali, teardown pulito — v1.0 Phase 3 (2026-10-14)
- ✓ Impostazioni come utility screen: toggle notifiche per categoria persistiti per utente, logout con conferma, eliminazione del personaggio via `deleteCharacter` (soft delete BE) — v1.0 Phase 4 (2026-10-18)
- ✓ Notifiche push FCM data-only + banner in-app per fine viaggio, streamer live, fine quest (poi quest annullata e sconfitta in imboscata), permesso chiesto in contesto, tap verso la Mappa o Twitch — v1.0 Phase 5 (2026-10-20; Android, iOS rinviata)
- ✓ Accettazione quest con lo swipe-left «strappa foglio», schede per famiglia (combattimento / narrativa / servizio) con eleggibilità, saldo/costo in punti canale, bacheca solo da un marker di città, corsie story e worldMission in parallelo, foglio della quest standard sulla Mappa con etichetta di stato server-driven — v1.0 Phase 6 (2026-10-22)
- ✓ Viaggio: drag della pedina su una città → pergamena con distanza, durata, ETA, cibo consumato e vita persa dal backend, rotta tratteggiata; pedina interpolata sull'ora del server, ricostruzione dopo kill, arrivo con push o banner, rifiuti per codice (`TRAVEL_IN_PROGRESS`, `QUEST_IN_PROGRESS`, `TRAVEL_STARVING` con requote), bacheca e negozio mai in viaggio — v1.0 Phase 7 (2026-10-26) + Phase 15 Travel Food (2026-11-06)
- ✓ Sezione Magie nel Diario: magie conosciute con usi e recupero in tempo server (`spellStates`, BE 9.1), slot da `maxActiveSpells` con toggle ottimistico e rollback, filtri a chip per `useType`/`effect`, riga «Cura: …» sugli oggetti — v1.0 Phase 8 (2026-10-27)
- ✓ Foglio esito missione: pergamena a schermo intero per i cinque esiti con barra vita animata, ferite, consumabili e magie usati, premi, XP, livello/titolo, magia appresa, avventurieri salvati, lore sbloccate; solo sulla Mappa libera, coda FIFO per `resolvedAt` deduplicata da tre sorgenti, ack alla chiusura, foglio di morte prima della creazione; stato ferito e quest `aid` — v1.0 Phase 9 (2026-10-29) + Phase 17 righe lore (2026-11-09)
- ✓ Locanda dell'innkeeper da Impostazioni: coda live delle richieste story/worldMission come carte per quest (corsia standard occupata nascosta), form di completamento con override per partecipante (nessun rifiuto, nessuna scelta di mostri/premi), teleport dalla coda sulla Mappa, `QUEST_IN_PROGRESS`, «Genera missioni» — v1.0 Phase 10 (2026-11-01) + Phase 14 (2026-11-05)
- ✓ Negozi per città: il negozio di un marker vende solo il pool della città per taglia via `cityShop(cityId)` (equipaggiamento, loot, compagni; mai leggendari; Necrorian senza negozio), `ITEM_NOT_IN_SHOP` nel fumetto del negoziante, compagni equipaggiati dal dropdown «Compagno» del Diario — v1.0 Phase 13 (2026-11-03)
- ✓ Companion della generazione quest: contratto multi-nemico `infos.enemies`, quest fisse crime/guard/dungeon con i layout di famiglia, annuncio sulla scheda, use type dei gioielli, tabellone per area riletto al cambio di posizione/titolo/corsia — v1.0 Phase 14 (2026-11-05)
- ✓ Imboscate in viaggio: categoria push `ambushDefeat` con switch «Imboscate», pedina che riparte dal punto dell'imboscata verso la città più vicina, report delle imboscate di un viaggio in carosello all'arrivo (`QuestResult.kind/ambush`, quest nullable) — v1.0 Phase 16 (2026-11-09)
- ✓ Lore sbloccabili per personaggio: Biblioteca filtrata su `unlockedLore` con refetch silenzioso e segnalibri «Nuovo» per libro, sagoma nera dei nemici sconosciuti (`known: false`), scheda col solo nome per le città sconosciute, pagina del libro a sliver — v1.0 Phase 17 (2026-11-09)
- ✓ Hardening: bypass dev solo in `lib/main_dev.dart`, release senza `.env` e senza `DEV_AUTH_` (grep in CI sul bundle), firma con `android/key.properties` e fallback debug, `InsecureTransportScreen` per URL in chiaro, log spenti, CI GitHub Actions (analyze, test, guard grep, build release), harness leak-tracking shell → logout, test di logout atomico, refresh concorrente, transizioni di identità e doppia sessione (`4409`, `SESSION_REVOKED` + reason → avvisi «sostituito da un nuovo login» / «ruolo cambiato»), `BAD_USER_INPUT` e codici di moderazione in tutti gli 11 classificatori, `City.size` per la visibilità dei marker con Talmvere sempre visibile — v1.0 Phase 12 (2026-11-10; E2E su Samsung + emulatore con release firmata e login Twitch reale)

### Active

**v1.1 Healing & Models (in corso):**

- [ ] Quest di cura per taglia e pozioni dal Diario con ricarica globale — HEAL-01..06 (Phase 18 ↔ BE 18)
- [ ] Companion della revisione dei modelli: debolezze, compagni con esperienza, `attack`/`defense` dei pet, equipaggiamento indossato, una sola lista di magie, parser fragili — MODEL-01..04 (Phase 19 ↔ BE 19)

**Backlog (dopo la v1.1):**

- [ ] CHAR-06: decidere se mantenere il pre-screen NSFW lato client o chiudere il requisito sulla moderazione server-side
- [ ] «Esci da tutti i dispositivi» (voce Impostazioni + mutation BE che revoca ogni sessione)
- [ ] Live share della posizione con altri giocatori: le pedine degli altri sulla Mappa in stanze (circa 50 per stanza), con la possibilità di creare una stanza propria (FUT-05)
- [ ] Log round-per-round degli esiti di combattimento (FUT-01)
- [ ] iOS: push APNs, firma e pubblicazione sugli store
- [ ] Pass di accessibilità (FUT-04)

### Out of Scope

- Gilde e arena — v2, richiede sistema sociale complesso
- Blog gilde — v2, dipende da sistema gilde
- Negozi per categoria (fabbro, alchimista…) — v2; i pool per città e taglia sono stati consegnati dalla Phase 13
- Villaggio visuale con case cliccabili — v2, refactor UI significativo (FUT-03)
- Descrizioni delle quest tramite LLM — v2; la generazione server-side delle quest enemy/boss è stata consegnata (BE 13 ↔ FE 14) con titoli a template
- Upload e playback audio quest story/worldMission — v2, richiede storage media
- Speech-to-text per quest audio — v2, dipende da upload audio
- Sistema allineamento buono/cattivo (crime/guard) — v2; le quest fisse crime/guard esistono senza logica di allineamento
- Lore con link ipertestuali navigabili — v2
- Riepilogo quest completate con dettagli — v2
- Logica di progressione, apprendimento magie, slot, ETA, cibo, imboscate, prezzi lato client — mai: il backend è la fonte di verità, il frontend è reattivo (confermato da tutte le 17 fasi)
- Validazione della sessione a ogni richiesta sul BE (JWT stateless 15 min accettato: il device sostituito perde l'HTTP alla scadenza) — scelta della BE Phase 17
- Diagnostics badge / log di sync dedicati nell'entry point dev — rifiutati due volte (Phase 12 D-15)

## Context

- **Stato del codice (2026-11-10):** ~36 000 righe Dart in `lib/` (491 file), ~65 000 righe di test (394 file), 3 704 test, analyzer pulito, CI verde. 1 610 commit, 22 PR mergiate su `develop`.
- **Stack:** Flutter stable (3.35.x), `flutter_bloc` + `equatable`, `graphql_flutter` 5.2.1 (HTTP + WS con `connection_init` autenticato), `dio`, `flutter_secure_storage`, Firebase Core + Messaging (data-only) + `flutter_local_notifications`, `flutter_map` + `latlong2`, `shared_preferences`, `flutter_cache_manager`, `flutter_dotenv` solo nell'entry point dev.
- **Backend:** NestJS 11 + MongoDB (Mongoose 8) + Apollo code-first + Bull/Redis; GraphQL HTTP + WS e REST per l'OAuth; repo `Klimmeck-Guide-BE`, handoff per fase in `.planning/phases/NN-<slug>/BACKEND-NOTES.md`.
- **Dati:** il mondo vive solo nel DB (BE D-36): città, POI, strade, nemici, pet, magie, oggetti, lore e pool dei negozi seminati al boot e curati a DB; asset su Cloudinary (equipaggiamento, ferite, pedine, ritratti dei nemici con pipeline Gemini → BiRefNet → SVG chiusa il 2026-11-08).
- **Piattaforma:** Android (Samsung fisico + emulatore); iOS non ancora esercitato.
- **Canale Twitch:** singolo, lo streamer è l'unico `innkeeper`.
- **Titoli personaggio:** rookie → adventurer → paladin → mage → hero (legend è solo un titolo); progressione via quest story lato backend.
- **Debito tecnico noto:** baseline non `dart format`-clean (mai formattare directory), semantica degli stream di `graphql_flutter` 5.2.1 al dispose coperta solo dai test (Rule 4), firma dipendente da `android/key.properties` fuori VCS, `adb reverse` e Doze dei device in UAT (note in memoria, non difetti dell'app).

## Constraints

- **Tech stack:** Flutter (mobile) + NestJS + MongoDB — già in uso, non negoziabile
- **Auth:** Solo OAuth Twitch mediato dal backend, nessun account proprio — l'identità è l'ID Twitch; l'app non vede mai un token Twitch
- **API Twitch:** dipendenza esterna per i punti canale (EventSub lato BE), soggetta a rate limit e disponibilità
- **Mappa:** POI e sfondo gestiti manualmente dallo streamer, non generati
- **Single channel:** l'app è legata a un solo canale Twitch
- **Regole invalicabili (CLAUDE.md):** nessun chrome app fuori dalle utility screen, nessun loading bloccante in sessione, branch + PR per ogni fase, backend fonte di verità, nessun secret in repo

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
  - `docs/` — chiusure di milestone e sole modifiche a `.planning/`
- **Slug del branch:** usare lo stesso slug della directory di fase (`.planning/phases/NN-<slug>/`), così Phase 1 → `feat/dev-auth-stub`.
- **Fine fase:** aprire una **PR verso `develop`** (non verso `main`). La PR è il punto di review prima del merge — ogni fase si chiude con una PR aperta che lo streamer/dev può controllare.
- **Niente push diretti su `develop` o `main`** durante una fase.
- **Fasi companion:** ogni fase FE che consuma un contratto BE nuovo ha un gate (`tool/schema_check`) sulla merge della PR BE prima dei piani che selezionano i campi e prima della UAT su device.

## Key Decisions

| Decision                                        | Rationale                                                                           | Outcome   |
| ----------------------------------------------- | ----------------------------------------------------------------------------------- | --------- |
| Conversione punti 1:1                           | Semplicità, trasparenza per i viewer                                                | ✓ Good — BE Phase 6 EventSub accredita 1:1 (2026-10-21); la FE mostra `Punti canale: saldo / costo` sulle schede |
| Backend NestJS + MongoDB                        | Stack già esistente e funzionante                                                   | ✓ Good    |
| Stats solo da equipaggiamento (no stats innate) | Semplifica bilanciamento, le classi sono solo flavor narrativo                      | ✓ Good — `CombatResolver` BE (Phase 9, 13.1); i non-arma mostrano la protezione, solo le armi sono «consigliate» |
| Magie sbloccate dopo 3a quest story             | Gate di progressione narrativa, evita overload iniziale                             | — Pending (regola BE sui titoli; non esercitata in una UAT su device) |
| Morte genera quest aid                          | Meccanica sociale emergente tra giocatori                                           | ✓ Good — Phase 9: quest `aid` nella famiglia combattimento, stato «In attesa di soccorso» sulla Mappa, soccorso visto nelle UAT 14 e 17 |
| Sync utente via GraphQL subscription            | Real-time di punti canale/stato/progressione senza polling; backend source of truth | ✓ Good — Phase 3 (2026-10-14) |
| Progressione e apprendimento magie lato backend | Frontend puramente reattivo, riduce rischio desync e logica duplicata               | ✓ Good — Phases 8, 9, 17 (quest study dal grado rookie, `spellStates` BE 9.1) |
| Notifiche Firebase (FCM + APNs)                 | Stack standard cross-platform per push mobile; necessario per notifiche background  | ✓ Validated on Android by Phase 5 (2026-10-20): data-only FCM + local notifications; iOS/APNs deferred |
| Quest accept via gesture swipe-left             | Feedback tattile «strappa foglio» coerente con tema diario, evita tap accidentali; lo swipe è la conferma, il BE resta il giudice | ✓ Good — Phase 6 (2026-10-22): strappo orizzontale deciso in UAT (D-06), worldMission legata alla città (D-11) |
| Login Twitch mediato dal backend, sessione propria del BE | Twitch non supporta PKCE, richiede `client_secret` e non accetta redirect con custom scheme; il BE custodisce il secret ed emette access JWT + refresh token | ✓ Good — Phase 11 (2026-10-06), provato con il login reale su device (2026-10-20) e sulla release firmata (2026-11-09) |
| Dev bypass mantenuto accanto all'auth reale | Le chiavi Twitch non erano disponibili: `DEV_AUTH_ENABLED=true` tiene l'app utilizzabile; rimozione dai build release in Phase 12 | ✓ Good — Phase 11 (2026-10-06); Phase 12 lo confina in `lib/main_dev.dart` e la CI prova che il bundle release non lo contiene |
| Creazione personaggio: pagina unica provvisoria, BE fonte di verità per età/razza e stato iniziale | Layout provvisorio subito dopo la login; età per razza e patrie vivono nel BE (`raceTraits`) | ✓ Good — Phase 2 + BE Phase 02.1 (2026-10-09) |
| Niente filtro NSFW e niente set curato di ritratti in v1 Phase 2 | Scelta esplicita dell'utente (2026-10-08): velocità del layout provvisorio | ⚠️ Revisit — la moderazione server-side è arrivata con la BE Phase 10 (Sightengine prima di Cloudinary) e la FE mappa i codici (HARDEN-10); CHAR-06 lato client resta un gap noto da decidere in v1.1 |
| Impostazioni come utility screen: preferenze notifiche solo sul device, cancellazione personaggio come soft delete BE | Toggle non sensibili e per utente; l'eliminazione resta identity-bound e archiviata dal BE (Phase 03.1) | ✓ Good — Phase 4 + BE Phase 03.1 (2026-10-18) |
| Usi e recuperi delle magie appartengono alla magia conosciuta, non allo slot (BE 9.1); filtri solo sui tipi presenti | Regola dell'utente «il timer di recupero non si interrompe mai»; equip/disequip neutri | ✓ Good — Phase 8 (2026-10-27) |
| Esiti mai persi: ack esplicito alla chiusura e `currentCharacter` sul morto fino all'ack (BE 9.2); foglio solo sulla Mappa | Push persi, notifiche disattivate e force-stop non devono far perdere un esito; «prima il foglio, poi la creazione» anche a cold start | ✓ Good — Phase 9 (2026-10-29) |
| Estensione v1.0 del 2026-10-29: sei fasi di contenuto e regole (BE 11–16 ↔ FE 13–17) prima dell'hardening | L'utente vuole un mondo che si sostiene da solo con molti giocatori prima dell'audit finale; ogni regola resta server-side | ✓ Good — Phases 13–17 consegnate fra il 2026-11-03 e il 2026-11-09, Hardening il 2026-11-10 |
| Locanda: coda live come carte per quest, form di completamento con override, nessun rifiuto, teleport dalla coda | Lo streamer completa in diretta ciò che ha narrato; mostri, grado e premi restano al BE (Phase 10 discuss) | ✓ Good — Phase 10 (2026-11-01, E2E 10/10 con sei regole fixate in UAT) |
| Il mondo vive solo nel DB (BE D-36): semina al boot + cura a DB, «la mano vince» | I file di contenuto nel repo erano rumore; lo streamer cura i dati direttamente | ✓ Good — BE 11/12 (2026-11-02); i pool di Ferrion/Necrorian non vengono rigenerati dopo il cambio di taglia |
| Negozi per città e taglia, Necrorian senza negozio, compagni acquistabili solo per lore | Pool backend-owned; il negozio è un luogo della città, non un catalogo globale | ✓ Good — Phase 13 ↔ BE 12 (2026-11-03) |
| Generazione quest server-side: boss = nemico singolo di fascia superiore, enemy singolo o branco di deboli, nessuna scadenza, animali fuori, tabellone per area | Quest sempre disponibili senza lo streamer; correzioni dalla UAT (BE 13.1) | ✓ Good — Phase 14 ↔ BE 13 + 13.1 (2026-11-05) |
| Cibo e vita del viaggio decisi tutti alla partenza, rifiuto per fame con nuova quotazione, nessun costo in monete | Preview onesta prima di «Parti»; il BE sceglie il cibo a scarto minimo | ✓ Good — Phase 15 ↔ BE 14 (2026-11-06); ⚠️ Revisit in BE Phase 20 (consumo progressivo) |
| Imboscate: rischio per km giorno/notte, più imboscate con risorteggio, report trattenuti all'arrivo in carosello, deviazione senza imboscate | Il viaggio resta silenzioso fino all'arrivo salvo la sconfitta (push); carosello invece di una pila di dialog | ✓ Good — Phase 16 ↔ BE 15 (2026-11-09; affordance del carosello fixata in UAT, D-19) |
| Lore sbloccate per personaggio (geografia alla nascita e all'arrivo, nemici alla vittoria, studio al 50 %), sagome per i nemici sconosciuti, «Nuovo» su baseline del device | La Biblioteca cresce con il viaggio del personaggio; nulla di «visto» vive sul BE | ✓ Good — Phase 17 ↔ BE 16 (2026-11-09) |
| «L'ultimo login caccia l'altro» (BE 17): close WS `4409`, `SESSION_REVOKED` + `reason`, JWT stateless 15 min accettato | Niente riconciliazione multi-device lato client; avvisi specifici al sign-in | ✓ Good — Phase 12 ↔ BE 17 (2026-11-10, provato con Samsung + emulatore) |
| Hardening: entry point splittati, release senza `.env`, firma con `key.properties`, solo TLS, CI con guard grep e build release, review per aree | Il bundle release deve essere dimostrabilmente privo del bypass dev; la CI è il guardiano | ✓ Good — Phase 12 (2026-11-10) |
| Talmvere villaggio sempre visibile; Ferrion e Necrorian capitali (UAT 12, DB-1) | Regola dell'utente: «Talmvere non è una capitale, ma è sempre visibile»; Necrorian con sole quest enemy/boss/dungeon | ✓ Good — FE flag `CityType.alwaysVisible`, BE PR #28 (2026-11-10); regola delle heal quest per la BE Phase 18 |

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

_Last updated: 2026-11-10 — milestone v1.1 Healing & Models started (Phases 18–19; scope: only the phases discussed on 2026-11-09)_
