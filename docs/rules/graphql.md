# GraphQL & networking

Client principale: `graphql_flutter` (HTTP + WS). REST residuale via `dio`.

## Organizzazione documenti

```
lib/graphql/
├── queries/          # <domain>_queries.dart
├── mutations/        # <domain>_mutations.dart
├── subscriptions/    # <domain>_subscriptions.dart
└── fragments/        # frammenti riusabili
```

- Un file Dart espone costanti `String` (o `DocumentNode`) per ciascuna operazione.
- **Una operazione = un nome esplicito** (es. `GetCharacter`, non query anonima). Serve per logging, cache key, debug.
- **Frammenti per campi riusati** in ≥2 operazioni. Definiti una volta in `fragments/`, inclusi via string interpolation o composizione.

## Naming operazioni

Vedi `docs/rules/naming.md`:
- Query: `GetXxx`, `ListXxx`
- Mutation: verbo imperativo (`AcceptQuest`, `EquipSpell`, `CancelTravel`)
- Subscription: `OnXxxChanged`, `OnXxxReceived`

## Service layer

- **`repository/services/graphql/graphql_client_provider.dart`** — unico punto di creazione del `GraphQLClient` (auth link, WS link, cache).
- **`repository/services/rest/`** — client Dio con interceptor per auth e logging.
- I Repository consumano i client, **non** creano istanze proprie.

## Error handling

- **Mai** propagare `OperationException` crudo fino alla UI. Mapparlo in un errore di dominio nel Repository/Cubit.
- Distinguere nel mapping:
  - **Network / offline** → tipo `NetworkError`
  - **Auth scaduta / 401** → trigger refresh silenzioso; se fallisce → `AuthError` (logout)
  - **GraphQL errors (`result.hasException` con `graphqlErrors`)** → `DomainError` con codice server
  - **Validation** → `ValidationError` con campi
- Il Cubit emette uno stato errore con messaggio leggibile per la UI. La UI **non** interpreta exception.

## Subscription (WebSocket)

- **Sync utente** (punti canale, stato personaggio) è via subscription. Vive per tutta la sessione.
- **Riconnessione invisibile** (vedi regola invalicabile #2): reconnect/backoff gestito nel client provider, **nessun spinner bloccante** durante WS reauth.
- **Cleanup obbligatorio:** ogni `StreamSubscription` cancellata in `Cubit.close()`.
- Ogni subscription deve avere **un solo consumer** (Cubit dedicato). Non iscrivere più widget alla stessa stream GraphQL.

## Refresh token / auth

- Refresh deve essere **invisibile**: il link auth intercetta 401, refresha, ripete la richiesta. Se refresh fallisce → stato globale di auth passa a unauthenticated → navigazione a login.
- Token in `shared_preferences` / secure storage (vedi `repository/storage/`). **Mai** in stato del Cubit in chiaro.

## Cache GraphQL

- Policy di cache decisa per operazione, non globale. Tipica:
  - `GetCharacter` → `cacheAndNetwork` (stale-while-revalidate)
  - `AcceptQuest` → nessuna cache, sempre network
  - `GetLoreList` → `cacheFirst` con invalidazione manuale
- Invalidare cache esplicitamente dopo mutation correlata.

## Anti-pattern

- Stringa GraphQL inline in un widget o Cubit → vietato, deve stare in `lib/graphql/`.
- `dio` usato per chiamate che sono già esposte in GraphQL → usa GraphQL.
- Retry loop infinito su errori → sempre con backoff e max tentativi.
- `print` di payload GraphQL completi → usa logger con livello, rispetta privacy token.
