# BACKEND-NOTES — FE Phase 7 Travel (handoff per l'agent backend)

- **Fase FE:** 07-travel (TRAVEL-01..04). Contesto in `07-CONTEXT.md` (D-01..D-20).
- **Data:** 2026-10-24 (discuss); aggiornato il 2026-10-26 con l'esito della UAT su device.
- **Contratto consumato:** BE Phase 8 Travel Lifecycle, **già su BE `develop`** (PR #11 merged 2026-10-22, PR #12 timeout scheduler merged 2026-10-24). Nessuna PR BE richiesta per questa fase.

## 1. Cosa consuma il FE (verbatim dal handoff BE Phase 8)

- `CharacterStatus.activeTravel { road { coordinates distance } startTime endTime duration to }` sul fragment del personaggio e su `characterUpdated`.
- Query `travelPreview(request: { id, poiId })` → `{ distance, duration, road { coordinates distance } }` (owner-only, nessuna scrittura) per il foglio di conferma e la rotta disegnata.
- Mutation `startTravel(request: { id, poiId })` → `CommonResponse` (owner-only); il viaggio arriva su `characterUpdated`.
- Query `serverTime` al bootstrap e al resume per l'offset device↔server (interpolazione e countdown).
- Push `travelEnd` (`id` = characterId) solo per i viaggi liberi: il tap ricentra la camera sulla pedina (nessun popup).
- Codici mappati per `extensions.code` nel banner: `TRAVEL_IN_PROGRESS`, `TRAVEL_SAME_LOCATION`, `TRAVEL_DESTINATION_NOT_ALLOWED`, `TRAVEL_NO_PATH`, `QUEST_IN_PROGRESS`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`.
- `assets.pet` **non** viene mai selezionato (handoff §11 b).

## 2. Decisioni FE che riguardano il BE

1. **Negozio e Bacheca solo in città** (07-CONTEXT D-12): il FE disabilita entrambi quando il personaggio non è su un `City.markerLocation` o ha un `activeTravel`. **Richiesta al BE (accolta nel discuss della BE Phase 9, D-18):** `doTransaction` deve rifiutare con un codice stabile (es. `SHOP_NOT_IN_CITY`) quando `status.location` non è il marker di una città o `activeTravel` è presente. Il FE resta il primo filtro e mapperà il codice nel banner quando arriverà (Phase 9 FE o quick task).
2. **Nessun costo del viaggio**: il FE non mostra alcun costo; se un giorno il BE ne introducesse uno, il foglio di conferma andrà esteso (nuova decisione, non in questa fase).
3. **Il FE non chiama mai `startTravel` dalla città in cui si trova** (D-02): `TRAVEL_SAME_LOCATION` resta solo una difesa del BE.
4. **Nessuna richiesta di cancel/cambio meta** (escluso by design, BE Phase 8 D-05).

## 3. Domande aperte per il BE — esito della UAT su device (2026-10-26)

Nessuna domanda aperta. UAT su device eseguita il **2026-10-26** (Samsung SM-S938B via USB, `adb reverse tcp:3000`) con FE `feat/07-travel` @ 596e6c7 contro il **BE locale dal branch `feat/09-combat-result-admin-outcomes` @ c4582b9** (contiene `origin/develop` 3df1b37 più la BE Phase 9, PR #13), non `origin/develop`. Dettaglio passo per passo in `07-HUMAN-UAT.md`.

Esito per i passi del handoff BE §11 d — **tutti verificati, nessun difetto BE emerso**:

| §11 d | Esito | Note |
|-------|-------|------|
| d.1 anteprima + conferma | pass | Foglio con distanza, durata ed ETA da `travelPreview`, poi `startTravel`. Probe C1: la rotta tratteggiata parte dalla pedina, nessuna anomalia segnalata dall'utente. |
| d.2 interpolazione sull'ora server | pass | Orologio del telefono spostato: pedina e tempo residuo invariati. |
| d.3 kill a metà viaggio | pass | Al rilancio la pedina riprende sulla rotta nel punto giusto. |
| d.4 arrivo con push | pass | Background: push "Viaggio completato", tap → Mappa. Primo piano: scatto sulla città su `characterUpdated` e banner. In gioco `endTime` è sempre `startTime + duration` (un primo tentativo con il solo `endTime` accorciato a mano nel DB non è valido, vedi `07-HUMAN-UAT.md`). |
| d.5 viaggio automatico da quest | pass | Foglio "In viaggio" → "Cacciando…" all'arrivo, nessuna push. |
| d.6 rifiuti | pass | `TRAVEL_IN_PROGRESS` → "Sei già in viaggio"; `QUEST_IN_PROGRESS` → "Non puoi partire durante una missione in corso" (copy di dominio, mai testo tecnico). |
| d.7 teleport a mano | pass | Su viaggio libero: viaggio cancellato dal BE, pedina sul nuovo POI. Con quest in corso: `QUEST_IN_PROGRESS` ("Non puoi muoverti durante una missione in corso"). |
| d.8 pet | pass | Pet `speedModifier: 2`: durata attesa 9 h 4 min col pet, doppia senza; l'utente ha confermato il pass senza riportare i numeri letti. |

- **Osservazione Pitfall 10 (regola della città più vicina):** a zoom basso il foglio ha nominato "Ulby". Non è un difetto (D-01).
- **Follow-up solo FE:** colore del tratteggio della rotta all'oro principale (quick task).

Da riportare in BE .planning/phases/08-travel-lifecycle-travel-01/08-HUMAN-UAT.md a cura del lato BE (questo repo non modifica il BE).

## 4. Dati per la UAT (usati il 2026-10-26)

Preparati dall'orchestratore nel DB di sviluppo (nessun id di utenti reali né segreti):

- **Pet:** "Cavallo da viaggio" con `speedModifier: 2`, inserito ed equipaggiato (`assets.pet` come ObjectId, §11 b).
- **Quest:** una hunt della corsia standard con marker diverso dalla città (passi 7, 8, 9B), chiusa poi retrodatando `startDate` (sweep del BE); registrazioni fantasma di personaggi non attivi rimosse da `enemy` e `boss`.
- **Città:** 12 lore delle capitali collegate alle città omonime (`relatedLore`) per l'immagine sul foglio; Bellport come meta dei passi 8 e 9A; "Resta" verificato da Mirwen.
- **Viaggi:** accorciati nel DB con `startTime`/`endTime` coerenti (durata intatta) per arrivare a metà strada o quasi in fondo.
- **Chiamate a mano:** `acceptQuest`, `startTravel`, `teleportCharacter` tramite il bypass di sviluppo del BE legato all'identità dell'utente; nessun token registrato.

Checklist §11 d di riferimento: preview + conferma, interpolazione sull'ora server, kill a metà viaggio, arrivo con push, viaggio automatico da quest senza push, rifiuti `TRAVEL_IN_PROGRESS`/`QUEST_IN_PROGRESS`, teleport (dal pannello admin: FE Phase 10, qui eseguito via GraphQL a mano), pet che dimezza la durata.
