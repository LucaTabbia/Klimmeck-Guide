# BACKEND-NOTES — FE Phase 7 Travel (handoff per l'agent backend)

- **Fase FE:** 07-travel (TRAVEL-01..04). Contesto in `07-CONTEXT.md` (D-01..D-20).
- **Data:** 2026-10-24 (discuss). Da aggiornare durante la fase.
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

## 3. Domande aperte per il BE

- Nessuna al momento del discuss. La UAT su device della BE Phase 8 (handoff §11 d) verrà eseguita nel piano finale di questa fase e l'esito riportato qui e in `08-HUMAN-UAT.md` del BE.

## 4. Dati per la UAT (dal handoff BE §11)

Da preparare a mano dall'utente prima dell'E2E: quest aggiornate al modello a slot (§11 a), un pet con `speedModifier: 2` (§11 b), strade con `speedFactor` > 0 e personaggio su un marker di città (§11 c). Checklist §11 d: preview + conferma, interpolazione sull'ora server, kill a metà viaggio, arrivo con push, viaggio automatico da quest senza push, rifiuti `TRAVEL_IN_PROGRESS`/`QUEST_IN_PROGRESS`, teleport (dal pannello admin: FE Phase 10, qui eseguibile via GraphQL a mano), pet che dimezza la durata.
