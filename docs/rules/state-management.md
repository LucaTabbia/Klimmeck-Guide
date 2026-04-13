# State management (BLoC / Cubit)

Libreria: `flutter_bloc` + `equatable`. Il progetto usa **prevalentemente Cubit**; BLoC solo quando serve.

## Cubit vs BLoC — quando usare cosa

**Cubit (default):**
- La feature ha un insieme di azioni dirette (`loadCharacter()`, `acceptQuest(id)`, `equipSpell(id)`).
- Non serve tracciare o trasformare flussi di eventi.
- La maggior parte dei casi in questo progetto.

**BLoC (eccezione):**
- Servono operatori Rx su eventi (debounce, throttle, distinct, switchMap) — es. ricerca con input rapido.
- Il flusso di eventi è parte essenziale del comportamento e va testato come sequenza.
- **In dubbio: Cubit.** Si può promuovere a BLoC dopo, raramente si torna indietro.

## Struttura file

```
<feature>Cubit/
├── <feature>_cubit.dart     # class <Feature>Cubit extends Cubit<<Feature>State>
└── <feature>_state.dart     # sealed/abstract + sottostati
```

Per BLoC aggiungere `<feature>_event.dart`.

## State — regole

- **Immutabile sempre.** Campi `final`. Modifiche via `copyWith`.
- **Estende `Equatable`** con `props` completo. Senza Equatable, `emit` di stati "uguali" triggera rebuild inutili.
- **Sottostati nominati per dominio**, non per tecnologia:
  - Buono: `QuestInitial`, `QuestLoading`, `QuestLoaded`, `QuestAccepting`, `QuestAcceptError`.
  - Scarso: `State1`, `QuestState2`, `ErrorState`.
- **Un solo `Loaded` con flag se servono sotto-stati frequenti** (`isRefreshing`, `isSubmitting`) per evitare esplosione di classi.
- **Errori come stato**, non come exception non gestita. Include messaggio + eventuale codice per UI.

## Cubit — regole

- **Non ha dipendenze da Flutter.** Solo repository e modelli.
- **Riceve Repository via costruttore** (DI esplicita). Niente singleton globali dentro il Cubit.
- **Metodi pubblici sono le "azioni"**, coerenti con eventi di dominio: `loadX`, `refreshX`, `acceptX`, `cancelX`.
- **`emit` solo da metodi pubblici del Cubit**, mai esposto fuori.
- **`close()` override** se servono cleanup (subscription WS, timer): cancellare tutto lì.
- **Subscription GraphQL (real-time):** tenere la `StreamSubscription` come campo private, cancellare in `close()`.

## UI — consumo

- **`BlocProvider`** per fornire: più vicino possibile al consumatore. Globale solo se davvero serve.
- **`BlocBuilder`** per ricostruire UI su cambio stato.
- **`BlocListener`** per side-effect (snackbar, navigazione, dialog) — **mai** dentro `BlocBuilder`.
- **`BlocConsumer`** solo quando listener+builder condividono lo stesso scope.
- **`buildWhen` / `listenWhen`** per filtrare rebuild quando pertinente.
- **Mai** chiamare `context.read<X>()` per leggere stato e fare render: usare `BlocBuilder`/`BlocSelector`. `read` è per triggerare azioni.

## Anti-pattern

- State mutabile (`List` modificata in-place): rompe diff di Equatable. Sempre `List.unmodifiable` o nuovi oggetti.
- Logica di business in widget (`onPressed: () { ... chiamate API ... }`): va nel Cubit.
- Cubit che costruisce widget o dipende da `BuildContext`: vietato.
- Condividere stato via singleton globali invece di `BlocProvider`: vietato.
- Cubit che chiama altri Cubit direttamente: orchestrazione va in un cubit "di livello superiore" o nella UI via `BlocListener`.

## Testing

Vedi `docs/rules/testing.md`. Regola: **`bloc_test` per ogni Cubit/BLoC non triviale.**
