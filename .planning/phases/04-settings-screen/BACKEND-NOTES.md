# BACKEND-NOTES — Phase 4 Settings Screen (handoff FE → BE)

- **Fase FE:** 04-settings-screen (requisiti SET-01..SET-05; decisioni D-01..D-21 in `04-CONTEXT.md`)
- **Data:** 2026-10-15
- **Stato:** contratto implementato da BE Phase 03.1 (PR #6 su develop) — fonte per il FE: Klimmeck-Guide-BE/.planning/phases/03.1-character-deletion-contract/BACKEND-NOTES.md
- **Consumatori:** FE Phase 4 (voce "Elimina personaggio" nel tab Impostazioni); indirettamente FE/BE Phase 9 (la morte in combattimento riusa lo stesso percorso di archivio, Phase 3 D-09); BE Phase 5 solo a titolo informativo (§4: le preferenze notifiche restano locali al device).

---

## 0. TL;DR per il BE

1. **Mutation `deleteCharacter: User!` senza argomenti.** Identità dal bearer (`@CurrentUser()`), come `createCharacter`: agisce sul `currentCharacter` del chiamante. Archivia il personaggio, azzera `User.currentCharacter` **atomicamente** e restituisce lo `User` aggiornato (`currentCharacter: null`, stessa forma di `me`).
2. **Soft delete, non cancellazione fisica** (decisione utente 2026-10-15): il documento `Character` resta a DB marcato come archiviato (es. `deletedAt`, più un motivo `user_request` oggi, `death` in Phase 9) e scollegato dallo User. Storico quest, audit e meccaniche future restano consultabili.
3. **Codici stabili** in `errors[0].extensions.code`: `CHARACTER_NOT_FOUND` quando il chiamante non ha un personaggio corrente (secondo tap, chiamata concorrente perdente, stato stantio); `UNAUTHENTICATED` dalla pipeline auth. Il FE mappa i codici, mai i messaggi.
4. **Effetti real-time:** l'aggiornamento di `users` fa emettere `userUpdated` con `currentCharacter: null` dal change stream esistente (BE Phase 3); **nessun `characterUpdated` per documenti archiviati**. Il FE adotta lo `User` restituito dalla mutation e usa `userUpdated` come backup.
5. **Il personaggio archiviato è invisibile ai percorsi giocatore** (`character(id)`, `characterUpdated(id)`, mutation sotto ownership rispondono come per un id inesistente/altrui) e **il suo nome torna disponibile** per `createCharacter`.
6. **Nessun contratto per le preferenze notifiche:** i tre toggle (fine viaggio, streamer live, fine quest) vivono in `shared_preferences` per utente sul device; Phase 5 filtra lato client. Vedi §4 per cosa deve sapere BE Phase 5.

---

## 1. Flusso lato app

1. Il giocatore apre il tab **Impostazioni** (settima voce della borsa), sezione **Account**, tocca **"Elimina personaggio"**.
2. Dialog di conferma a due pulsanti ("Sei sicuro di voler eliminare *<nome>*? L'azione è irreversibile." — Annulla / Elimina).
3. **`mutation { deleteCharacter { ...UserFields } }`** con il bearer di sessione (`UserFields` = `id twitchId twitchPoints role currentCharacter { id }`).
4. **Risposta `User`** con `currentCharacter: null` → `AuthCubit.adoptUser(user)` → `SessionHome` porta alla pagina di creazione (Phase 2 D-01, Phase 3 D-09); la shell di gioco chiavata per `characterId` viene smontata e la subscription `characterUpdated` del vecchio id si chiude (Phase 3 D-08).
5. **Backup:** se `adoptUser` rifiuta lo User o la risposta si perde, `userUpdated` (snapshot su subscribe + evento live) porta lo stesso `currentCharacter: null`.
6. Lo stesso utente può poi chiamare `createCharacter` (claim su `currentCharacter: null`, BE 02.1 D-03) anche riusando il nome del personaggio archiviato.

Errori: `CHARACTER_NOT_FOUND` → il FE si riallinea con `me` (stessa gestione di `CHARACTER_ALREADY_EXISTS` in Phase 2); errore transitorio → messaggio inline nella sezione Account, l'utente può riprovare. Il FE **non** controlla viaggi o quest attivi prima di chiamare la mutation (§3, domanda 1).

---

## 2. Contratto proposto

```graphql
type Mutation {
  deleteCharacter: User!
}
```

Documento FE previsto (`lib/graphql/mutations/character_mutations.dart`):

```graphql
mutation DeleteCharacter {
  deleteCharacter {
    ...UserFields
  }
}
```

Nessun input: un argomento `id` sarebbe ridondante e aprirebbe un percorso di ownership da proteggere; l'identità del bearer basta (stessa scelta di `createCharacter`, BE 02.1 D-01). Un'eventuale cancellazione admin di personaggi altrui è fuori scope (Phase 9/10 BE, con `@Roles(innkeeper)` e audit).

| Caso | Risposta |
|---|---|
| Chiamante con `currentCharacter` valorizzato | `User` aggiornato, `currentCharacter: null`; `Character` archiviato |
| Chiamante senza `currentCharacter` (doppio tap, già eliminato) | `errors[0].extensions.code = CHARACTER_NOT_FOUND` |
| Due chiamate concorrenti dello stesso utente | esattamente un archivio; la perdente riceve `CHARACTER_NOT_FOUND` |
| Bearer assente/invalid | `UNAUTHENTICATED` (pipeline Phase 2) |

---

## 3. Semantica proposta e domande aperte per il BE

Decisioni che il FE dà per scontate (fissate in BE 03.1 CONTEXT; il BE le può raffinare):

- **Atomicità:** stesso pattern transazionale di `createCharacter` (claim su `users` con filtro `currentCharacter: <id>` → `$set: null`; poi `characters` `$set: { deletedAt, deletionReason }` con filtro `deletedAt: null`). Nessuno stato parziale.
- **Visibilità:** gli archiviati sono esclusi da `character(id)`, `characterUpdated(id)` (nessuna emissione dal change stream per `deletedAt != null`), dalle mutation sotto ownership e dai percorsi di gioco futuri (job viaggio Bull, Phase 8). La lista innkeeper `characters` può includerli con flag: scelta BE.
- **Nome riutilizzabile:** l'indice unico case-insensitive `character_name_ci_unique` oggi copre tutti i documenti; va reso parziale sugli attivi (o spostato su una chiave dedicata rimossa all'archivio) e il verifier di boot aggiornato. Il nome resta leggibile sul documento archiviato.
- **Audit:** `deletedAt` + `deletionReason` sul documento sono la traccia; nessun record in `admin_audit_logs` (non è un'azione admin).

Domande aperte (risposta attesa nel `BACKEND-NOTES.md` BE 03.1):

1. **Viaggio/quest in corso al momento della cancellazione:** rifiuto con un codice dedicato oppure archivio comunque con pulizia dello stato pendente? Proposta FE: archiviare comunque (oggi non esiste `activeTravel`, `quests.pendingQuest` resta nel documento archiviato); Phase 7/8 devono ignorare i personaggi archiviati.
2. **Quest di gruppo / riferimenti incrociati** (`aid` generate dalla morte, Phase 9): il documento archiviato resta referenziabile per id — confermare che nessun job o resolver lo "resusciti".
3. **Cooldown o limite** di ricreazione dopo la cancellazione? Proposta FE: nessuno in v1.
4. **Punti canale:** `twitchPoints` è sullo `User`, non sul personaggio: confermare che la cancellazione **non** li tocca (il FE li mostra invariati).

---

## 4. Preferenze notifiche — informativo per BE Phase 5

- I toggle **fine viaggio / streamer live / fine quest** sono salvati **solo sul device**, per `user.id`, default tutti attivi (FE D-09..D-13). Il BE non li conosce e **non deve esporre** mutation o campi per ora.
- Il **filtro è lato client**: il BE invia i data message a tutti i device registrati dell'utente (BE-NOTIF-03) e il FE decide se mostrare la notifica nei tre app state. Perché funzioni **anche con app uccisa**, il payload deve restare un **data message con il tipo dell'evento** (`travelEnd` / `streamerLive` / `questEnd`) oltre all'id, così il background handler FE può applicare la preferenza prima di mostrare la notifica locale. Da fissare nel contratto BE Phase 5.
- Sync server-side delle preferenze (soppressione lato BE, coerenza multi-device) è **differita**: se servirà, il FE proporrà un campo `notificationPreferences` sullo `User` più una mutation dedicata.

---

## 5. Verifica prima della PR FE

- Documenti GraphQL verificati con `tool/schema_check` contro `Klimmeck-Guide-BE/src/schema.gql` rigenerato dalla fase BE 03.1 (stessa disciplina di Phase 2 D-33 / Phase 3 D-04).
- E2E manuale su device: elimina → pagina di creazione → nuovo personaggio con lo stesso nome → shell di gioco.
- **PR BE 03.1 merge-ata prima della PR FE.**

---

## 6. Esito verifica (schema + E2E)

- **Data:** 2026-10-16
- **Schema:** `src/schema.gql` di BE `origin/develop` @ `d578ad2` (Merge pull request #6, feat/03.1-character-deletion-contract); riga 289 `deleteCharacter: User!`. PR BE 03.1 gia' su `develop`.
- **Strumento:** `tool/schema_check` (`dump_documents.dart` + `validate_documents.js`), 25 documenti.

| Documento | Esito |
|---|---|
| DeleteCharacter.graphql | OK |
| CreateCharacter.graphql | OK |
| ExchangeLoginTicket.graphql | OK |
| GetMe.graphql | OK |
| GetRaceTraits.graphql | OK |
| Logout.graphql | OK |
| OnUserChanged.graphql | OK |
| RefreshSession.graphql | OK |
| character.graphql | OK |
| characterUpdated.graphql | OK |
| cities.graphql | OK |
| doTransaction.graphql | OK |
| equipItem.graphql | OK |
| equipSpell.graphql | OK |
| equipment.graphql | OK |
| equipmentAssetsQuantity.graphql | OK |
| equipmentItems.graphql | OK |
| equipmentItemsByIds.graphql | OK |
| lootAssetsQuantity.graphql | OK |
| lootItems.graphql | OK |
| lootItemsByIds.graphql | OK |
| lore.graphql | OK |
| lores.graphql | OK |
| quests.graphql | OK |
| unequipSpell.graphql | OK |

- **Drift pre-esistente:** nessuno (25/25 OK).
- **Gate FE:** `flutter test` 759 verdi; `flutter analyze` 57 issue / 0 errori (nessuna nei file Phase 4); file Dart Phase 4 formatter-clean; 0 trailer Co-Authored-By.

E2E: approvato dall'utente il 2026-10-18 su device Android fisico contro BE develop @ d578ad2 (dettagli in 04-HUMAN-UAT.md); passi 1-10 pass, 11-12 non eseguiti/non riportati; campi di archivio e ricreazione con lo stesso nome coperti dai passi 8-9 come approvati.
