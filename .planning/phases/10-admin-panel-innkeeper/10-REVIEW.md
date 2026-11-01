---
phase: 10-admin-panel-innkeeper
reviewed: 2026-10-29T12:00:00Z
depth: standard
files_reviewed: 54
files_reviewed_list:
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/fragments/pending_request_fragment.dart
  - lib/graphql/mutations/pending_request_mutations.dart
  - lib/graphql/mutations/travel_mutations.dart
  - lib/graphql/queries/pending_request_queries.dart
  - lib/graphql/subscriptions/pending_request_subscriptions.dart
  - lib/models/pending_request/participant_presence.dart
  - lib/models/pending_request/pending_request.dart
  - lib/models/pending_request/queued_travel.dart
  - lib/models/pending_request/request_card.dart
  - lib/models/request/complete_pending_request_input.dart
  - lib/models/request/participant_draft.dart
  - lib/models/request/participant_override.dart
  - lib/models/travel/teleport_target.dart
  - lib/repository/innkeeper_failure.dart
  - lib/repository/innkeeper_repository.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/innkeeper/components/completion_recap.dart
  - lib/screens/innkeeper/components/injury_chips.dart
  - lib/screens/innkeeper/components/participant_override_section.dart
  - lib/screens/innkeeper/components/participant_row.dart
  - lib/screens/innkeeper/components/presence_label.dart
  - lib/screens/innkeeper/components/quantity_stepper.dart
  - lib/screens/innkeeper/components/request_card_view.dart
  - lib/screens/innkeeper/components/results_recap_dialog.dart
  - lib/screens/innkeeper/innkeeper_access.dart
  - lib/screens/innkeeper/innkeeper_panel_route.dart
  - lib/screens/innkeeper/innkeeper_panel_screen.dart
  - lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart
  - lib/screens/innkeeper/pendingRequestsCubit/pending_requests_state.dart
  - lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart
  - lib/screens/innkeeper/requestCompletionCubit/request_completion_state.dart
  - lib/screens/innkeeper/request_completion_route.dart
  - lib/screens/innkeeper/request_completion_screen.dart
  - lib/screens/mainScreen/components/teleport_mode_landing.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/map/components/city_marker.dart
  - lib/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart
  - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
  - lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart
  - lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart
  - lib/screens/mainScreen/tabs/map/layers/pawn_visuals.dart
  - lib/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart
  - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart
  - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_state.dart
  - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart
  - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_state.dart
  - lib/screens/mainScreen/tabs/map/utils/map_utils.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/tabs/settings/components/innkeeper_section.dart
  - lib/screens/mainScreen/tabs/settings/settings.dart
  - lib/shared/components/modal/destructive_confirmation_dialog.dart
  - lib/theme/kg_theme.dart
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-10-29
**Depth:** standard
**Files Reviewed:** 54
**Status:** issues_found

## Summary

La fase aggiunge il pannello «Locanda» del GM (coda `pendingRequests` viva via
subscription, carte per quest, form di completamento con override per
partecipante, riepilogo esiti) e la modalità teletrasporto sulla Mappa
(`TeleportModeCubit` a livello di shell, pedina trascinabile, atterraggio dal
pannello e riapertura al successo). Il refactor di `CharacterMarkerLayer` verso
`PawnDragging`/`PawnVisuals` conserva il comportamento.

Verdetto: struttura solida e coerente con le regole dei layer. I Cubit sono
Flutter-free, non si chiamano tra loro, usano `SafeEmit`; timer e
subscription sono cancellati in `close()`; il parsing difende dalle voci
malformate; i codici di errore sono mappati solo su `extensions.code`; la
Mappa in teletrasporto non ha AppBar, Chip Material né SnackBar. Nessun
problema critico o di sicurezza (il ruolo è verificato dal BE, nessun secret).

Restano 3 warning, tutti sul flusso di completamento nel pannello: il riepilogo
esiti viene perso quando si completa l'ultima carta, la rimozione ottimistica
può nascondere una carta futura e il form si può chiudere con il back durante
l'invio. Nota: il path del BE (`Klimmeck-Guide-BE`) non esiste nel sandbox, il
contratto non è stato verificato contro `schema.gql` (lo fa lo schema check
dell'orchestratore).

## Warnings

### WR-01: Il riepilogo esiti sparisce quando si completa l'ultima carta della coda

**File:** `lib/screens/innkeeper/innkeeper_panel_screen.dart:79-88` (contesto
catturato a `:123`, `:132`; ramo vuoto a `:119`)
**Problem:** `_complete` riceve il `context` del builder di `BlocSelector`
(`:123`, che oscura il `context` esterno) e dopo `await openCompletion(...)`
controlla `context.mounted` (`:83`). Quando la coda diventa vuota `_buildQueue`
ritorna `_EmptyQueue` (`:119`) al posto del `BlocSelector`, quindi quel context
viene smontato.
**Scenario:** il GM completa l'unica carta. Il BE cancella le `PendingQuest` e
la subscription consegna lo snapshot vuoto mentre il form è ancora aperto (il
pannello sotto la route si ricostruisce comunque) e prima o insieme alla
risposta della mutation. Il form fa `pop(CompletionCompleted)`,
`context.mounted` è `false`, `_complete` esce: nessun `showResultsRecap` e
nessun `markCompleted`. Il GM non vede mai gli esiti (D-13). I test usano un
cubit mock e non coprono il caso «ultima carta».
**Fix:** usare il context stabile della schermata (quello di `build`), non
quello di un sotto-albero condizionale:
```dart
// build(BuildContext context): passarlo a _buildScaffold(context)
// e a _buildQueue(panelContext, state); nell'itemBuilder:
onComplete: (card) => _complete(panelContext, card),
```
Test (TDD): `PendingRequestsCubit` reale o `whenListen` che emette lista vuota
mentre il form è aperto e poi `CompletionCompleted`; atteso: il dialog
«Richiesta completata» compare.

### WR-02: `markCompleted` dopo lo snapshot già arrivato lascia un id nascosto per sempre

**File:** `lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart:79-80`
(potatura a `:114-117`)
**Problem:** `markCompleted` aggiunge sempre `questId` a `hiddenQuestIds`. La
potatura in `_applySnapshot` rimuove un id solo se lo snapshot non contiene più
la quest. Se lo snapshot che toglie la carta è arrivato PRIMA di
`markCompleted` (ordine normale, vedi WR-01; vale anche per `CompletionGone`
dopo il `refetch`), l'id resta in `hiddenQuestIds` senza più nulla da potare.
**Scenario:** il GM completa la quest Q; lo snapshot senza Q arriva, poi
`markCompleted(Q)`. Un altro viewer accetta di nuovo Q: il nuovo snapshot
contiene Q, `hiddenQuestIds` la trattiene, `requestCardsOf` la salta. Il GM non
vede la nuova richiesta finché non riapre il pannello. Oggi il bug è mascherato
da WR-01 (il ramo non viene raggiunto), ma emerge appena WR-01 è corretto.
**Fix:** nascondere solo se la quest è ancora nello stato:
```dart
void markCompleted(String questId) {
  if (!state.requests.any((request) => request.quest.id == questId)) return;
  emit(state.copyWith(hiddenQuestIds: {...state.hiddenQuestIds, questId}));
}
```
Test: `markCompleted` su una quest assente non cambia `hiddenQuestIds`; uno
snapshot successivo con la stessa quest mostra la carta.

### WR-03: Il form di completamento si può chiudere durante l'invio e l'esito va perso

**File:** `lib/screens/innkeeper/request_completion_screen.dart:31-43` (invio
a `lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart:66-87`)
**Problem:** durante `isSubmitting` solo il bottone «Conferma» è disabilitato
(`:168`). Back di sistema e freccia della AppBar restano attivi, non c'è
`PopScope`. La route esce con `null`, il cubit viene chiuso e la risposta della
mutation viene scartata da `SafeEmit`, mentre il BE ha già (o sta per aver)
chiuso la richiesta.
**Scenario:** il GM tocca «Conferma», poi back dopo un secondo (rete lenta, fino
a 15 s di timeout). La richiesta viene completata dal BE, ma il pannello non
riceve `CompletionCompleted`: niente riepilogo e niente `markCompleted`; la
carta resta finché lo snapshot non la toglie. Se il GM riapre la carta e
riconferma, ottiene `NOT_FOUND` («Richiesta non più disponibile») senza aver mai
visto gli esiti.
**Fix:** bloccare l'uscita mentre si invia:
```dart
PopScope(
  canPop: !(state is RequestCompletionEditing && state.isSubmitting),
  child: Scaffold(...),
)
```
(avvolgere il `Scaffold` in un `BlocSelector<RequestCompletionCubit, ..., bool>`
sull'`isSubmitting`). Test widget: con `isSubmitting: true` il back non fa pop.

## Info

### IN-01: Rilettura manuale e snapshot possono sovrapporsi con ordine invertito

**File:** `lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart:84-93`
**Issue:** `_performRefetch` applica il risultato della query anche se nel
frattempo è arrivato uno snapshot più recente dalla subscription; una risposta
lenta e più vecchia può sovrascriverlo finché non arriva il prossimo evento.
**Scenario:** resume dell'app: parte il refetch, la subscription riconnessa
consegna lo snapshot nuovo, poi la query (partita prima) risponde con la lista
precedente: una carta già sparita ricompare.
**Fix:** contatore di versione incrementato in `_onSnapshot`; in
`_performRefetch` scartare il risultato se la versione è cambiata durante
l'await.

### IN-02: `load()` non gestisce eccezioni diverse da `InnkeeperException`

**File:** `lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart:37-44`
**Issue:** il `try` cattura solo `InnkeeperException`. `ParticipantDraft.from`
(es. `Spellbook.of(character)` su dati inattesi) viene valutato fuori dal
repository, quindi un'eccezione lì resta non gestita: lo stato rimane
`RequestCompletionLoading` con il loader infinito (il `finally` azzera solo
`_isLoading`) e l'errore finisce nella zona globale.
**Fix:** `on Object { emit(const RequestCompletionLoadFailed(failure: InnkeeperFailure.malformed)); }`
dopo il ramo tipizzato, con test che inietta un `Character` che fa fallire il
draft.

### IN-03: Dopo un `cancel()` durante l'invio il teletrasporto atterra senza feedback

**File:** `lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart:85-88`
(guardia a `:76-81`)
**Issue:** il chip lascia «Annulla» attivo mentre `isTeleporting` è true;
`cancel()` incrementa `_generation` e la risposta viene ignorata, ma la mutation
è già partita. Il personaggio viene spostato dal BE mentre la UI è tornata
idle, senza riapertura del pannello né messaggio.
**Fix:** ignorare `cancel()` quando `state` è `TeleportActive(isTeleporting: true)`
(oppure disabilitare «Annulla» in `TeleportModeChip` con `isTeleporting`).

### IN-04: `isPawnDragging` può restare acceso se la modalità teletrasporto termina a metà trascinamento

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:387-393`
**Issue:** `_syncTeleportMode` con `isActive == false` azzera solo
`teleportModeChanged`. Se il layer viene smontato mentre il dito è giù (ruolo
perso → `cancel()` dal listener `AuthCubit`), `Draggable` non chiama
`onDragEnd` sul widget smontato (stessa premessa dell'IN-02 già citato nel
file) e `pawnDragChanged(false)` non arriva: `isFree` resta falso e blocca i
fogli esiti fino al prossimo trascinamento.
**Fix:** in `_syncTeleportMode`, ramo `!isActive`, chiamare `_endPawnDrag()`.

### IN-05: Uscire dal pannello durante la lettura del teletrasporto porta comunque alla Mappa

**File:** `lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart:27-59`
e `lib/screens/mainScreen/components/teleport_mode_landing.dart:48-55`
**Issue:** `prepare` non è legato alla vita del pannello. Se il GM esce con il
back mentre la riga mostra il progresso, la lettura finisce lo stesso, lo stato
diventa `TeleportActive` e `_landOnMap` lo porta alla Mappa; in caso di errore
il messaggio non compare (il listener del SnackBar vive nel pannello chiuso).
**Fix:** `PopScope` sul pannello che chiama `TeleportModeCubit.cancel()`
all'uscita quando lo stato è `TeleportPreparing` (o accettare e documentare il
comportamento nella CONTEXT).

### IN-06: Costanti duplicate e lacuna di test

**File:** `lib/screens/innkeeper/components/participant_override_section.dart:23-24`
e `lib/screens/innkeeper/components/completion_recap.dart:6-7`
**Issue:** `'Oggetto'` e `'Magia sconosciuta'` sono definite due volte
(`_unnamedItem`, `_unnamedSpell`) in file diversi; il copy provvisorio (D-22)
andrebbe cambiato in due punti. Inoltre `test/screens/innkeeper/innkeeper_panel_screen_test.dart`
usa un cubit mock: non copre WR-01 (ultima carta) né l'ordine snapshot/
`markCompleted` di WR-02.
**Fix:** estrarre le due stringhe in un solo posto (es. costanti pubbliche in
`completion_recap.dart` riusate dalla sezione) e aggiungere i test indicati in
WR-01/WR-02/WR-03.

## Deferred to plan 10-11

- Selezione di `pendingQuest` sotto `PendingRequestCharacter` nel fragment
  (BE-HARD-08) e verifica di `isBusy`/regola di nascondimento sul campo reale.
- Full gate (`flutter analyze`/`flutter test`), mappa VALIDATION, E2E su device e
  tracciabilità dei requisiti.
- Verifica del contratto contro `src/schema.gql` del BE (path non disponibile in
  questo sandbox): demandata allo schema check dell'orchestratore.

---

_Reviewed: 2026-10-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
