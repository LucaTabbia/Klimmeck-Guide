---
phase: 09-combat-result-sheet
reviewed: 2026-10-28T12:00:00Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/fragments/quest_result_fragment.dart
  - lib/graphql/queries/quest_result_queries.dart
  - lib/graphql/subscriptions/quest_result_subscriptions.dart
  - lib/models/character/awaiting_aid.dart
  - lib/models/character/character_status.dart
  - lib/models/enums/quest_type.dart
  - lib/models/notification_category.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/models/quest_result/quest_end_event.dart
  - lib/models/quest_result/quest_outcome.dart
  - lib/models/quest_result/quest_result.dart
  - lib/models/quest_result/quest_result_quest.dart
  - lib/models/quest_result/quest_rewards.dart
  - lib/models/quest_result/spell_usage.dart
  - lib/repository/quest_acceptance_failure.dart
  - lib/repository/quest_result_delivery_ports.dart
  - lib/repository/quest_result_failure.dart
  - lib/repository/quest_result_repository.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/sync/connection_restored_events.dart
  - lib/repository/transaction_failure.dart
  - lib/repository/travel_failure.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart
  - lib/screens/auth/session_sync_scope.dart
  - lib/screens/auth/syncCubit/session_sync_cubit.dart
  - lib/screens/mainScreen/characterCubit/character_cubit.dart
  - lib/screens/mainScreen/characterCubit/character_state.dart
  - lib/screens/mainScreen/components/notification_popup_registry.dart
  - lib/screens/mainScreen/components/quest_result_presenter.dart
  - lib/screens/mainScreen/components/satchel_availability.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
  - lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart
  - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
  - lib/screens/mainScreen/questResultsCubit/quest_results_state.dart
  - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
  - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart
  - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_state.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/tabs/shop/components/transaction_outcome_listener.dart
  - lib/screens/mainScreen/tabs/shop/shop.dart
  - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart
  - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart
  - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_state.dart
  - lib/screens/mainScreen/travelCubit/travel_notice.dart
  - lib/shared/components/hp_delta_bar.dart
  - lib/shared/components/popup/quest_result_sheet.dart
  - lib/theme/kg_theme.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 4
  info: 6
  total: 10
critical_count: 0
warning_count: 4
info_count: 6
status: issues_found
---

# Phase 9: Code Review Report

**Reviewed:** 2026-10-28
**Depth:** standard
**Files Reviewed:** 51 file di produzione (piani 09-01..09-11) piu' lettura degli helper di test (`test/helpers/mocks.dart`, `fakes/fake_pending_quest_results.dart`, `fakes/recording_quest_result_acknowledger.dart`) per la copertura
**Status:** issues_found

## Summary

Nessun problema critico. Il nucleo della fase (coda FIFO, presenter, flusso morte, availability, classificatori) e' corretto sui percorsi principali; i 4 warning sono casi limite reali (un buco di consegna dopo la risottoscrizione, la geometria del foglio su telefoni verticali, un vicolo cieco al cold start, l'assenza di timeout sulle porte che la catena seriale e il single-flight rendono bloccanti).

**Verificato corretto (non sono finding):**

- `QuestResultsCubit`: dedup per id su coda, `showing`, chiusi, conferme pendenti e confermate (`_isKnown`); ordinamento stabile per `resolvedAt` poi `id` (`_byResolution`); `presented/closed/dismissedExternally` aggiornano `position`/`total` in modo coerente (reset a 0 a coda vuota, `-1` al rientro in coda); single-flight di `refetchPending` (`??=` + `whenComplete` e' sicuro perche' `_performRefetch` e' `async`); `silentRetry` non lancia mai e rispetta `isClosed`; `close()` cancella timer e subscription e ogni `emit` post-chiusura e' assorbito da `SafeEmit`; la catena `_serialised` non si avvelena su errore (`catchError` sulla coda, errore propagato al chiamante); `acknowledgeDeath` e' idempotente su `inFlight/done`, ritentabile su `failed` (anche al resume), e `closed()` non riconferma una morte gia' confermata (`_acknowledgedIds`).
- `isAcceptingSheets` dopo `done`: scenari di gara tra `userUpdated(null)` e risposta della mutation verificati. Se l'evento utente arriva per primo, `AuthGate` (`_changesCharacter` -> `popUntil(isFirst)`) chiude il dialog e il cubit chiuso assorbe tutto; se arriva per ultimo, il `BlocConsumer` fa `pop(true)` prima del `me` forzato. Nessun dialog orfano sopra la pagina di creazione.
- Presenter: dialog su Navigator radice, `PopScope(canPop:false)`, `barrierDismissible:false`, pop esterno -> `dismissedExternally` senza conferma (anche il `popUntil(isFirst)` di `NotificationIntentLanding` rimette in coda e riapre); `_isPresenting` impedisce doppie aperture; `routeCoveredChanged` scritto post-frame con guardia `mounted` e azzerato in `dispose` (i figli si smontano prima dei provider, quindi il cubit e' ancora vivo); `ModalRoute.isCurrentOf` sottoscrive l'aspetto `isCurrent`, quindi `didChangeDependencies` scatta davvero; `CharacterUnavailable` -> un solo refetch; nessun `BuildContext` usato dopo un gap asincrono (`context` solo prima del primo `await`, post-frame protetto da `mounted`).
- `MapAvailabilityCubit`: i tre scrittori azzerano il proprio flag in `dispose` (`MainScreen`, `WorldMap`, presenter), nessun flag resta acceso dopo lo smontaggio.
- `InAppNotificationsCubit.suppress`: la chiave `questEnd|<id>` e' la stessa di `PushEvent.dedupKey` per il push in foreground; la finestra personale da 2 minuti copre la gara push/subscription nei due ordini; rimozione del banner in coda o visibile corretta.
- `SessionSyncCubit`: `false -> true` emesso solo dopo la prima connessione (`_hasConnected`), duplicati `true` ignorati (`!_isConnected`).
- `CharacterCubit`: nessuna regressione del trattamento FORBIDDEN/NOT_FOUND esistente (load, refetch, stream passano tutti da `_markCharacterGone`, un solo `requestUserRefresh` per vita); `CharacterUnavailable` e' quieto al cold start.
- Confini di parsing: `QuestResult.tryFromJson` e' l'unico ingresso (`_questResultFrom` lo converte in `FormatException`, che sullo stream non chiude la subscription e nel cubit viene saltata), orfani (`item: null`) scartati, enum sconosciuti -> `null` (tipo quest, titolo, ferite) tranne `outcome` che scarta il risultato per scelta documentata, `acknowledgedAt` opzionale, `AwaitingAid.tryFromJson` fail-open.
- Classificatori: solo `extensions.code`, mai i messaggi; `AWAITING_AID` presente in viaggio e accettazione; `TransactionCubit` annulla il timer su nuova richiesta e in `close()`.
- `QuestResultSheet` non possiede controller (la barra usa `TweenAnimationBuilder`, nulla da smaltire); regola #4 rispettata: la sheet rende solo numeri BE (le uniche derivazioni sono `isLoss/isGain` per il colore, `toCopper() == 0` per la sezione vuota); regola #1 (nessuna AppBar/chrome, scrim) e #2 (nessun loader; il pulsante disabilitato durante la conferma della morte e' un'azione esplicita) rispettate.
- I file DIRTY (`character_marker_layer.dart`, `quest_type.dart`): le modifiche della fase sono additive e corrette (etichetta e `_canStartTravel` con `awaitingAid`; `QuestType.label` esaustivo sugli enum).
- Coerenza con `BACKEND-NOTES.md`: codici, nomi, dedup `questEnd|<id>`, terminalita' NOT_FOUND/FORBIDDEN sulla subscription e tolleranza al cold start dopo la morte corrispondono al contratto.

**Limiti dell'analisi:** nessuna esecuzione su device (UAT del piano 09-13 differita per design); non ho eseguito `flutter analyze`/`flutter test`; i punti marcati "da confermare in UAT" dipendono dall'asset Cloudinary `emptySheet`, non ispezionabile qui. Differiti per design e non finding: porte 9.2 come oggetti nulli, `acknowledgedAt` assente dal fragment (finche' non arriva 09-12 un tap su un vecchio push riapre un risultato gia' confermato, e `requestFromTap` non puo' distinguerlo), implementazione reale di `PendingQuestResults`/`QuestResultAcknowledger`.

## Warnings

### WR-01: Dopo ogni risottoscrizione i risultati risolti nel buco non vengono mai riletti

**File:** `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart:227-231, 263-273`
**Problema:** `questResultReceived` non ha snapshot (BACKEND-NOTES §1). Il cubit rilegge la lista non confermata alla riconnessione del socket (`_restoredSubscription`), ma la subscription vera viene riaperta solo allo scadere del backoff (`_scheduleResubscribe`, fino a `WsReconnectPolicy.maxReconnectDelay`). Sequenza: socket cade, subscription va in errore/`onDone`, parte il timer (es. 30 s); il socket torna a t0 e `restored` fa il refetch; un risultato risolto tra la fine del refetch e la `_subscribe()` tardiva non e' nella lista letta e non e' nella subscription (non ancora aperta). Resta perso fino al prossimo resume/riconnessione. Vale anche per un errore di solo stream senza caduta del socket (in quel caso `restored` non scatta affatto). Aggravante: `_attempt` torna a 0 solo su un evento live (`_onLiveResult`), quindi su un personaggio "quieto" il ritardo cresce a ogni flap senza mai ridursi.
**Perche' conta:** e' la garanzia centrale della fase ("nessun foglio perso"). Il push `questEnd` copre solo se le notifiche sono attive, e il banner in foreground non apre la sheet da solo.
**Fix:** rileggere subito dopo aver riaperto la subscription (il single-flight rende il costo trascurabile) e azzerare `_attempt` quando la subscription e' stata riaperta con successo:
```dart
_resubscribeTimer = Timer(
  exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay),
  () {
    _resubscribeTimer = null;
    if (isClosed || _isStreamTerminated) return;
    _subscribe();
    unawaited(refetchPending()); // copre il buco senza snapshot
  },
);
```
Un test con `fakeAsync`: errore sullo stream, risultato in `FakePendingQuestResults.results` durante il backoff, avanzare oltre il backoff, atteso il risultato in coda.

### WR-02: Il foglio esiti e' dimensionato su un riquadro con rapporto diverso da quello della pergamena (telefoni verticali)

**File:** `lib/shared/components/popup/quest_result_sheet.dart:101-131`
**Problema:** `sheetHeight = constraints.maxHeight` ma solo la larghezza e' clampata a `constraints.maxWidth`. Su qualunque telefono in verticale `altezza * 315/375` supera di molto la larghezza (es. 800 x 360: 672 > 360), quindi il clamp scatta sempre e il riquadro diventa 360 x 800 (rapporto 0.45 invece di 0.84). `CachedSvg` usa `BoxFit.contain` (`cached_svg.dart:13`): la pergamena viene disegnata 360 x ~428 centrata, mentre i padding frazionari (`top 0.167`, `bottom 0.13`) sono calcolati sul riquadro 360 x 800. Risultato atteso: contenuto e pulsante "Continua" che escono sopra/sotto l'arte (qui circa 50 px sopra e 80 px sotto), cioe' sullo scrim scuro, dove l'inchiostro `darkWood` quasi non si legge. `QuestInfoSheet` evita il problema con `height = screenHeight * 1.5` e larghezza derivata senza clamp. I test di widget non lo vedono (superficie di test 800x600). **Da confermare in UAT sul device**, ma il difetto segue dall'aritmetica, non dall'asset.
**Perche' conta:** e' la schermata principale della fase e l'unico modo di chiuderla e' il pulsante: se cade fuori dalla pergamena resta illeggibile.
**Fix:** derivare entrambe le dimensioni dal vincolo piu' stretto, cosi' il rapporto resta quello dell'asset:
```dart
final sheetWidth = math.min(constraints.maxWidth, constraints.maxHeight * _aspectRatio);
final sheetHeight = sheetWidth / _aspectRatio;
```
(la `SingleChildScrollView` gia' presente assorbe la minore altezza utile). In alternativa replicare il trucco di `QuestInfoSheet`. Aggiungere un test con superficie 360x800.

### WR-03: Cold start con `CharacterUnavailable`: spinner senza uscita se il foglio di morte non arriva

**File:** `lib/screens/mainScreen/main_screen.dart:77, 163-190`; `lib/screens/mainScreen/characterCubit/character_cubit.dart:74-78`
**Problema:** al cold start con personaggio morto non confermato `loadCharacter` emette `CharacterUnavailable` (quieto, D-13) ma `MainScreen` non carica mai `MainScreenCubit` (resta `isFirstLoading`), quindi mostra per sempre il `KGLoader`. Il foglio di morte deve arrivare da `fetchUnacknowledged`, che `silentRetry` tenta 8 volte (~2 min) e poi abbandona in silenzio; da li' in poi un nuovo tentativo parte solo a resume/riconnessione. Se la lettura fallisce (rete assente, BE 9.2 giu', risultato oltre il cap) il giocatore resta davanti a uno spinner senza pull-to-refresh, senza `KGError`, senza accesso a Impostazioni/logout. Il percorso esistente per `CharacterError` (KGError + pull-to-refresh, D-16) qui non esiste. Lo spinner e' ammesso solo al cold start e per un tempo breve (regola #2), non come stato terminale.
**Perche' conta:** vicolo cieco recuperabile solo uccidendo l'app, e proprio nel caso (morte con app chiusa) per cui D-13 esiste.
**Fix:** quando `QuestResultsCubit` ha finito un refetch senza foglio in coda e `CharacterCubit` e' ancora `CharacterUnavailable`, mostrare il `KGError` con retry che chiama `refetchPending()` (e `requestUserRefresh`); minimo: trattare `CharacterUnavailable` come `MainScreenError` nel builder, con `RefreshIndicator -> context.read<QuestResultsCubit>().refetchPending()`. Da coprire con un test (stato `CharacterUnavailable` + coda vuota -> non `KGLoader`).

### WR-04: Porte senza timeout: un `Future` appeso blocca per sempre refetch e conferma della morte

**File:** `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart:90-91, 196-206, 285-289`; `lib/repository/quest_result_delivery_ports.dart:6-14`
**Problema:** `refetchPending` e' single-flight (`_refetchInFlight ??=`) e `_serialised` mette in fila ogni mutation dietro la precedente. Nessuno dei due applica un timeout, e il contratto delle porte non lo richiede (`QuestResultRepository._guard` ha 15 s solo per `fetch`). Se l'implementazione di 09-12 (WS stalla, link senza risposta) lascia appeso un `fetchUnacknowledged`, `_refetchInFlight` non torna mai `null`: resume, riconnessione e `CharacterUnavailable` si fondono tutti su quel volo morto e nessun risultato viene piu' recuperato. Peggio per `_serialised`: una conferma non critica appesa blocca in coda `acknowledgeDeath`, lo stato resta `inFlight`, il pulsante e' disabilitato e la sheet non e' chiudibile (PopScope, nessuna barriera) - blocco totale dell'app sul foglio di morte.
**Perche' conta:** la robustezza della consegna dipende da una proprieta' che nessun test di questa fase puo' verificare (i fake rispondono sempre) e che il piano 09-12 potrebbe dimenticare.
**Fix:** imporre il timeout nel cubit, non nell'adattatore:
```dart
static const Duration _portTimeout = Duration(seconds: 15);

// in _performRefetch
() => _pending.fetchUnacknowledged().timeout(_portTimeout),

// in _serialised
final run = _acknowledgementTail.then((_) => mutation().timeout(_portTimeout));
```
(`TimeoutException` e' gia' trattata come fallimento dai `catch` / `shouldRetry`). Documentare il requisito nel commento delle porte.

## Info

### IN-01: Il refetch accetta i risultati uno alla volta: il FIFO dipende dall'ordine del BE

**File:** `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart:203-205, 293-302`
**Problema:** `_performRefetch` chiama `_accept` per ogni elemento, con un `emit` ciascuno. Il presenter reagisce al primo emit e, se la mappa e' libera, apre subito quel foglio e solo dopo arrivano gli altri: se la lista non fosse ascendente per `resolvedAt` (BACKEND-NOTES §2.1 lo "richiede" ma non e' un invariante verificato) il primo mostrato non sarebbe il piu' vecchio. Anche con ordine corretto sono N rebuild/emit inutili.
**Fix:** accettare il lotto in un solo passo (filtra con `_isKnown`/`acknowledgedAt`, unisci, ordina con `_byResolution`, un solo `emit`).

### IN-02: `isPawnDragging` puo' restare acceso se il `Draggable` si smonta durante il trascinamento

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:349-367`; `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart:60-66, 201-203`
**Problema:** il flag si accende al primo `onDragUpdate` e si spegne in `onDragEnd`, che Flutter non invoca se il `Draggable` e' smontato (es. un `characterUpdated` fa passare `_buildIdlePawn` a `_buildTravellingPawn` mentre si trascina). Il flag resta `true` fino al dispose di `WorldMap` e `availability.isFree` blocca tutti i fogli non-morte sulla Mappa. Raro, ma e' proprio il rischio T-9-14 che il commento di `dispose` dice di voler evitare.
**Fix:** in `_CharacterMarkerLayerState.dispose`, se `_dragPoint != null`, notificare `widget.onDragEnd(null, null)` (o far spegnere il flag a `WorldMap` quando `_canStartTravel` diventa falso).

### IN-03: Il banner dell'arrivo live si decide con `head == arrival`, non con "la mappa e' libera"

**File:** `lib/screens/mainScreen/components/quest_result_presenter.dart:110-122`
**Problema:** se il giocatore e' sulla Mappa libera e c'e' gia' un altro foglio in testa (o un foglio aperto, `state.showing != null`), l'arrivo live Y non e' la testa: `suppress` non scatta e parte `publish`, quindi compare un banner "Missione conclusa" sulla Mappa (D-07: nessun banner se si e' gia' sulla mappa) oppure, con un foglio aperto, un banner nascosto sotto il dialog che occupa la coda e la finestra di dedup per 5 s. Innocuo, ma incoerente con D-07.
**Fix:** separare la condizione "Mappa libera/morte in coda" da "e' il prossimo" (es. `_isMapReady` ignorando `showing/_isPresenting/head`) e sopprimere il banner in quel caso.

### IN-04: `malformed` viene ritentato 8 volte come se fosse transitorio

**File:** `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart:215-221`
**Problema:** `_isTransient` esclude solo `forbidden/unauthenticated/notFound`; un `QuestResultFailure.malformed` (parsing deterministico) fa girare `silentRetry` per ~2 minuti tenendo occupato il single-flight. Nota per 09-12: la lista non confermata deve saltare le voci malformate (`QuestResult.tryFromJson` per elemento) invece di far fallire tutta la lettura, altrimenti un solo documento sbagliato nasconde tutti i fogli.
**Fix:** aggiungere `QuestResultFailure.malformed` all'insieme dei non ritentabili e parsare la lista voce per voce.

### IN-05: `TransactionOutcomeListener` vive solo mentre `Shop` e' montato

**File:** `lib/screens/mainScreen/tabs/shop/shop.dart:254-260` (uso), `lib/screens/mainScreen/tabs/shop/components/transaction_outcome_listener.dart:9-21`
**Problema:** il `TransactionCubit` e' di shell, ma il banner di `SHOP_NOT_IN_CITY` e' pubblicato da un listener dentro `Shop`. Se il giocatore cambia tab prima della risposta il banner si perde (stessa motivazione per cui `QuestAcceptanceOutcomeListener` sta a livello `MainScreen`, vedi doc di `AuthenticatedShell`). Inoltre `Shop` nasconde il fumetto per i rifiuti con banner, quindi in quel caso non resta alcun feedback.
**Fix:** montare `TransactionOutcomeListener` accanto agli altri listener in `main_screen.dart` (sopra `SpellOutcomeListener`) e toglierlo da `Shop`.

### IN-06: `_isCharacterGone` e' per tutta la vita del cubit e disattiva il refetch al resume

**File:** `lib/screens/mainScreen/characterCubit/character_cubit.dart:60, 88, 145-149`
**Problema:** il comportamento voluto (un solo refresh utente) e' documentato, ma il flag blocca anche `refreshCharacter` al resume. Prima della fase un FORBIDDEN/NOT_FOUND transitorio sul refetch non impediva al resume successivo di rileggere il personaggio; ora, se il `me` richiesto restituisce lo stesso `currentCharacter` (falso positivo o conferma non ancora propagata), la shell resta con un `CharacterLoaded` vecchio e senza stream fino al riavvio. Il caso e' stretto (il BE risponde questi codici in modo deterministico) e `SessionSyncCubit` rilegge `me` a ogni resume, quindi lo segnalo solo come fragilita' accettata.
**Fix:** se si vuole recuperare, azzerare `_isCharacterGone` (e riaprire lo stream) quando il `me` successivo restituisce lo stesso id; altrimenti lasciare la nota nella doc di classe.

---

_Reviewed: 2026-10-28T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
