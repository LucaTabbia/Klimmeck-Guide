# BACKEND-NOTES — Phase 3 Real-Time Sync Foundation (handoff FE → BE)

- **Fase FE:** 03-real-time-sync-foundation (requisiti SYNC-01..07; decisioni D-01..D-19 in `03-CONTEXT.md`)
- **Data:** 2026-10-14 (contesto raccolto; aggiornare man mano durante la fase)
- **Fase BE di destinazione:** **BE Phase 3 "Autorizzazione: Ownership, Ruoli, Audit"** (decisione utente 2026-10-14: nessuna fase companion decimale). La sua SC#3 già prevede "`characterUpdated` (e lo user stream) emette solo al proprietario/innkeeper".
- **Fonte di verità:** `Klimmeck-Guide-BE/src/schema.gql` rigenerato dalla BE Phase 3 vince su questo documento. Il FE verifica i propri documenti GraphQL nome per nome prima della PR; **PR BE prima della PR FE**.
- **Consumatori FE:** la sessione autenticata (`AuthTokenService.adoptUser`, `AuthGate`/`SessionHome`) per lo User; `CharacterCubit` per il Character. Nessuna UI nuova in questa fase.

---

## 0. TL;DR per il BE

1. **Nuova subscription `userUpdated: User!` senza argomenti.** Identità dal bearer del `connection_init`; emette lo `User` completo (`id twitchId twitchPoints role currentCharacter { id }`) a ogni modifica del documento dell'utente autenticato (oggi: `twitchPoints`, `role`, `currentCharacter`). Un client non può ascoltare un altro utente.
2. **`characterUpdated(id: String!)` resta identica nel contratto**, ma emette solo se il bearer è il proprietario del character (o innkeeper) — BE-AUTHZ-03. **Allineamento 2026-10-14 (BE Phase 3 D-04):** un id altrui viene **rifiutato alla sottoscrizione** con `extensions.code = FORBIDDEN` (messaggio graphql-ws `next` con `errors`, poi `complete`); il FE non ritenta e fa un solo refetch di `me`.
3. **Snapshot su subscribe:** a ogni (ri)sottoscrizione il BE emette **subito** il documento corrente, poi i cambiamenti. Vale per entrambe le subscription. È il meccanismo con cui il FE recupera gli eventi persi durante le riconnessioni WS (4401 ogni ~15 min, cadute di rete): il client Dart ri-invia le operazioni al reconnect e lo snapshot chiude il gap. **Nessun replay/cursore richiesto.**
4. **Cancellazione del personaggio:** il FE la apprende da `userUpdated` con `currentCharacter: null`. Il change stream attuale su `characters` filtra solo `update`/`replace`, quindi un documento cancellato non emette `characterUpdated`: va bene così, purché il documento `users` venga aggiornato (e quindi emesso) alla cancellazione.
5. **Nessun admin-swap:** l'admin non riassegna personaggi (chiarimento utente 2026-10-14); `currentCharacter` cambia solo per creazione (`null → id`) e cancellazione (`id → null`, da Impostazioni FE Phase 4 o per morte in combattimento, BE Phase 9).

---

## 1. Contratto proposto

```graphql
type Subscription {
  # esistente, argomento mantenuto, filtro per identità aggiunto lato BE
  characterUpdated(id: String!): Character!
  # nuova: identità dal bearer, nessun argomento
  userUpdated: User!
}
```

Selezione FE (fragment `UserFields` già esistente):

```graphql
subscription OnUserChanged {
  userUpdated {
    id
    twitchId
    twitchPoints
    role
    currentCharacter { id }
  }
}
```

`characterUpdated` continua a usare `CharacterFragment.fullFields` (infos, status, assets, quests) **senza** `activeTravel` / `activeStoryQuest` / `activeWorldMissionQuest`: quei campi arrivano con le BE Phase 7/8 e il FE li aggiunge nelle proprie Phase 6/7.

### Comportamento atteso

| Evento | `userUpdated` | `characterUpdated(id)` |
|---|---|---|
| Apertura/riapertura della subscription | snapshot immediato dello User | snapshot immediato del Character (se il bearer è proprietario/innkeeper) |
| Redemption punti canale (BE Phase 6) | emette con `twitchPoints` aggiornato | — |
| Cambio ruolo (admin) | emette con `role` aggiornato | — |
| `createCharacter` | emette con `currentCharacter { id }` | il FE apre poi la subscription sul nuovo id |
| Cancellazione / morte | emette con `currentCharacter: null` | nessuna emissione (delete non è nel change stream): accettato |
| Qualsiasi update del character (equip, quest, HP, location…) | — | emette il documento completo |
| Subscriber con id altrui (non innkeeper) | — | rifiuto `FORBIDDEN` alla subscribe (`next` con errors + `complete`), nessun evento |

### Autenticazione WS (già in essere, BE Phase 2)

Invariata: `connection_init` con `{ "Authorization": "Bearer <jwt>" }` letto a ogni connect, chiusura 4401 alla scadenza del JWT, 4403 su token assente/invalido. Il FE fa refresh e riconnette; con lo snapshot su subscribe il gap si chiude da solo.

---

## 2. Come il FE usa il contratto

1. Cold start / login → `AuthAuthenticated(user)` → il FE apre `userUpdated` per tutta la sessione (un solo consumer).
2. Con `currentCharacter != null` → `character(id)` query + `characterUpdated(id)` come oggi (`CharacterCubit`), ricreati se l'id cambia.
3. Ogni evento `userUpdated` passa da `adoptUser`: un evento con `id` diverso dall'utente di sessione viene scartato (difesa in profondità lato FE; il filtro autoritativo è il vostro).
4. **Resume dell'app** (background → foreground): il FE ri-interroga sempre `me` e `character(id)` (il socket può essere vivo e non ri-sottoscrivere). Le due query restano quindi parte del contratto consumato.
5. **Watchdog FE ≈ 3 minuti:** se per ~3 minuti nessuna subscription riceve dati/si riconnette e nessun refetch riesce, il FE chiude la sessione localmente (storage svuotato, sign-in con "Connessione persa, accedi di nuovo"). **Nessuna chiamata `logout` al BE in questo caso** (non c'è rete): la sessione server muore per scadenza come già previsto per il logout offline.

---

## 3. Note di implementazione (suggerimenti, decide il BE)

- `userUpdated` può seguire il pattern di `characters.service.ts`: change stream su `users` (`update`/`replace`, `fullDocument: 'updateLookup'`) → `pubSub.publish('userUpdated', { userUpdated: user })`, con filtro `payload.userUpdated._id === context.identity.userId` nel resolver. In alternativa publish esplicito nei service che toccano `twitchPoints` / `role` / `currentCharacter`.
- Snapshot su subscribe con `@graphql-yoga/subscription`: `Repeater.merge([snapshotRepeater, pubSub.subscribe(...)])` oppure un async generator che `yield` il documento corrente e poi delega al `pubSub.subscribe`. Lo snapshot va emesso **dopo** l'autenticazione del connect e **solo** se il filtro identità passa.
- `PubSubEvents` in `src/pubsub.module.ts` va esteso con `userUpdated: [user: User]`.
- Il filtro identità su `characterUpdated` richiede l'identità WS nel `context` del resolver (già disponibile dalla BE Phase 2 via `onConnect`).
- Volume: durante una live le redemption possono far emettere molti `userUpdated` (uno per redemption): accettabile per il FE (payload piccolo).

---

## 4. Domande aperte per il BE

1. **Snapshot su subscribe:** confermare fattibilità con `@graphql-yoga/subscription` + `graphql-ws` e che lo snapshot passi dal filtro identità. Se non fattibile, dirlo presto: il FE ripiegherebbe su refetch via query anche a ogni reconnect (già previsto come discrezione del planner).
2. **Cancellazione del personaggio:** confermare che la cancellazione (Impostazioni, BE fase da definire; morte, BE Phase 9) aggiorni `User.currentCharacter = null` sul documento `users` (così `userUpdated` lo emette). Sarebbe utile un'unica operazione atomica delete character + unset currentCharacter.
3. **Ordine degli eventi alla morte:** il FE Phase 9 mostrerà il Combat Result prima di tornare alla creazione; quando arriverà `CombatResult` (BE Phase 9), indicare se il `userUpdated(currentCharacter: null)` viene emesso prima o dopo l'evento di combattimento, così il FE sa cosa trattenere.
4. **`me` e `character(id)` restano** le query di refetch: nessuna modifica richiesta, ma `character(id)` dovrà rispettare lo stesso filtro di ownership della subscription (403 su id altrui) — già SC#1 della vostra Phase 3.
5. **Schema:** rigenerare `src/schema.gql` a fine BE Phase 3 e aggiornare il vostro `BACKEND-NOTES.md`; il FE farà il confronto nome per nome prima della PR (come Phase 2 §5).

---

## 5. Verifica schema (da compilare a fine fase)

_Da eseguire quando la BE Phase 3 è su `develop`: confronto tra `lib/graphql/subscriptions/*.dart`, `lib/graphql/fragments/user_fragment.dart` e `Klimmeck-Guide-BE/src/schema.gql` rigenerato; E2E manuale con BE reale (snapshot al connect, aggiornamento live di twitchPoints/role/status, reconnect dopo 4401, resume, teardown al logout)._
