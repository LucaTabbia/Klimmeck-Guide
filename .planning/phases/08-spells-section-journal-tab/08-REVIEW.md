---
phase: 08-spells-section-journal-tab
reviewed: 2026-10-27T12:00:00Z
depth: standard
files_reviewed: 38
files_reviewed_list:
  - lib/graphql/mutations/character_mutations.dart
  - lib/models/character/character_status.dart
  - lib/models/request/equip_spell_request.dart
  - lib/models/spell/spell_recovery_status.dart
  - lib/models/spell/spell_state.dart
  - lib/models/spell/spellbook.dart
  - lib/models/travel/travel_time_format.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/spell_equip_failure.dart
  - lib/repository/spells_repository.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/components/spell_outcome_listener.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/journal/components/known_spell_row.dart
  - lib/screens/mainScreen/tabs/journal/components/spell_resist.dart
  - lib/screens/mainScreen/tabs/journal/components/spell_slot_row.dart
  - lib/screens/mainScreen/tabs/journal/components/spellbook_content.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/journal/sections/spells_section.dart
  - lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart
  - lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_state.dart
  - lib/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart
  - lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart
  - lib/screens/mainScreen/tabs/journal/spellsCubit/spells_state.dart
  - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
  - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
  - lib/shared/components/bookmark_ribbon.dart
  - lib/shared/components/cards/equipment_item_card.dart
  - lib/shared/components/cards/spell_card.dart
  - lib/shared/components/popup/equipment_info_sheet.dart
  - lib/shared/components/popup/spell_info_sheet.dart
  - lib/shared/components/spell_info.dart
  - lib/shared/components/spell_row.dart
  - lib/shared/components/usages_pencil_counter.dart
  - lib/theme/kg_theme.dart
  - lib/utils/game_duration_format.dart
  - lib/utils/spell_lines.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
critical_count: 0
warning_count: 2
info_count: 4
status: issues_found
---

# Phase 8: Code Review Report

**Reviewed:** 2026-10-27
**Depth:** standard
**Files Reviewed:** 38
**Status:** issues_found

## Summary

Il codice della fase e solido. Nessun problema critico.

Punti verificati e corretti:

- **Overlay ottimistico:** il token per magia scarta le risposte tardive. `close()` svuota token e timer. `SafeEmit` rende innocui gli emit dopo la chiusura. `sync` e `_succeed` chiudono l'operazione solo se il personaggio riflette davvero l'esito (match per stato attivo/non attivo, non per evento), quindi un `characterUpdated` non correlato non chiude un'operazione in volo.
- **Doppio tap a slot pieni (D-07):** `Spellbook.intentFor` lavora sulla vista ottimistica, quindi il secondo tap diventa `blockedSlotsFull`.
- **`SpellRecoveryCubit`:** il ticker parte solo con almeno un countdown. Si ferma con `Arriving`/`Unknown`/`Full`. `close()` cancella timer e subscription. Il cubit e creato e chiuso dalla sezione, che muore con la pagina del Diario (D-16).
- **`SpellOutcomeListener`:** `listenWhen` e deduplicato sulla `sequence`. La tabella D-17 e rispettata: refresh silenzioso per `alreadyActive`/`notActive`, banner piu refresh per `notKnown`/`slotsFull`/`notFound`, silenzio per `unauthenticated`. Il dedup del banner e per chiave.
- **Parse boundary:** `SpellState.tryFromJson` scarta le voci malformate. `CharacterStatus._spellStatesFrom` torna `null` se il campo manca.
- **`AnimationController` condiviso:** `_selectEquipment` e `_selectSpell` azzerano l'altra selezione. Il listener `dismissed` azzera tutto. Il `removeStatusListener` in `dispose` e presente.
- **Duplicazione:** `BookmarkRibbon`/`CardBookmark` e `UsagesPencilCounter` hanno un'unica implementazione, usata da `SpellCard`, `EquipmentItemCard` e dai due fogli. `SpellRow` e rimosso e non resta alcun riferimento in `lib/` o `test/`.
- **Regola #4:** il solo calcolo client e `recoveries.min - serverNow`. Non si incrementano usi e non si calcolano soglie di slot o titoli. Il pre-controllo slot (D-07) usa `maxActiveSpells` del BE, e il BE resta giudice.
- **Regola #2:** nessuno spinner e nessun loading. Il refresh e silenzioso.
- **Altro:** `flutter analyze` sulle directory toccate non segnala import inutilizzati. I tre file controllati con `dart format --output=none` (`spells_cubit`, `spellbook`, `spell_info`) sono puliti.

**Limiti dell'analisi:**

- Il repo BE non e stato consultato. Il contratto `spellStates` e verificato dal piano gate 08-12.
- I test sotto `test/` sono stati usati solo per verificare l'assenza di riferimenti a `SpellRow`. Non e stata fatta una revisione di flakiness.

## Warnings

### WR-01: Nessuna rilettura quando l'operazione si chiude per timeout, con vista potenzialmente stantia

**File:** `lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart:138-145`
**File:** `lib/screens/mainScreen/components/spell_outcome_listener.dart:18-24`

**Problema:** due percorsi lasciano l'overlay vuoto e il personaggio non riletto.

1. **Timeout con richiesta riuscita.** Se la mutation e riuscita ma `characterUpdated` non e arrivato entro 15 s, `_onSettleTimeout` chiama `_settle`, che rimuove l'overlay in silenzio e non emette alcun esito. La UI torna alla vista del `CharacterCubit`, che e quella vecchia. Quando l'evento arriva davvero in ritardo, la UI si allinea. Se l'evento e perso (WS in riconnessione), la vista resta stantia fino al prossimo evento.
2. **`SpellEquipFailure.timedOut`.** Non e in `_staleViewFailures`. Il banner dice «controlla le magie prima di riprovare», ma il client non rilegge. La richiesta potrebbe essere stata eseguita dal BE, e il Diario mostrerebbe lo stato sbagliato.

**Perche conta:** regola #4 (il BE e la fonte di verita) e D-17 (nessuna vista stantia dopo un esito incerto). Il costo del fix e una chiamata silenziosa e idempotente, e `refreshCharacter` e gia protetto da `_eventCount`/generation.

**Fix:**

```dart
// spell_outcome_listener.dart
static const Set<SpellEquipFailure> _staleViewFailures = {
  SpellEquipFailure.alreadyActive,
  SpellEquipFailure.notActive,
  SpellEquipFailure.notKnown,
  SpellEquipFailure.slotsFull,
  SpellEquipFailure.notFound,
  SpellEquipFailure.timedOut, // esito incerto: rilettura silenziosa
};
```

Per il caso 1, `_onSettleTimeout` con `_succeeded` puo emettere un esito `settledByTimeout` che il listener tratta come rilettura senza banner. In alternativa, `SpellsCubit` riceve un callback `onUncertain` che il listener collega a `CharacterCubit.refreshCharacter`.

### WR-02: Equip e unequip concorrenti partono in parallelo senza ordine garantito

**File:** `lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart:88-108`

**Problema:** `_start` invia la mutation con `unawaited` per ogni magia, senza coda. Con slot pieni e magie A attiva e C non attiva, l'utente tocca A (unequip) e subito C (equip). Il secondo tap e legittimo sulla vista ottimistica, perche A e gia liberata. Le due mutation partono in parallelo, e il BE potrebbe elaborare `equipSpell(C)` prima di `unequipSpell(A)`. Il risultato e `MAX_ACTIVE_SPELLS_REACHED` per C: banner e rimbalzo spuri, pur avendo fatto l'utente un'azione valida.

**Perche conta:** e una race realistica sul canale mobile (due tap ravvicinati nel flusso «scambia magia») e il BE rifiuta un'azione corretta. Non corrompe i dati, perche lo stato finale e riallineato dal refresh di `slotsFull`.

**Fix:** serializzare le mutation per personaggio con una coda `Future`:

```dart
Future<void> _tail = Future.value();

void _enqueue(Future<void> Function() job) {
  _tail = _tail.then((_) => job()).catchError((_) {});
}
// in _start: unawaited(_enqueue(() => _send(...)));
```

Il timer di 15 s deve partire all'invio effettivo e non al tap, oppure il timeout va portato a 15 s moltiplicato per la profondita di coda. Se si preferisce non cambiare nulla, documentare in CONTEXT che il rifiuto spurio e accettato (D-07).

## Info

### IN-01: `toggle` sovrascrive `_latest` con il personaggio catturato dal widget

**File:** `lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart:42-43`

**Problema:** `_latest = character` usa il personaggio della closure del widget. Tra l'arrivo di un `characterUpdated` (che chiama `sync` e aggiorna `_latest`) e il rebuild successivo, un tap passerebbe un personaggio piu vecchio. `_latest` regredirebbe, `_succeed` potrebbe non riconoscere l'esito gia riflesso e l'overlay resterebbe fino al timeout di 15 s, per poi chiudersi in silenzio. La finestra e di un frame e l'effetto e solo visivo.

**Fix:** aggiornare `_latest` solo se non e piu recente. In alternativa, iniettare un `Character? Function()` letto da `CharacterCubit` invece di passare il personaggio a `toggle`.

### IN-02: Timeout duplicati tra repository e cubit

**File:** `lib/repository/spells_repository.dart:18`, `lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart:20`

**Problema:** entrambi valgono 15 s. Il timer del cubit parte per primo, quindi vince sempre. Il `TimeoutException` del repository diventa di fatto irraggiungibile dal percorso del cubit e l'esito `timedOut` e prodotto in due punti.

**Fix:** tenere un solo proprietario del timeout. Ad esempio, il repository con 15 s e il cubit con un margine (`settleTimeout = repositoryTimeout + 2 s`) usato solo per aspettare `characterUpdated`.

### IN-03: Il foglio puo tenere un `SpellRecoveryCubit` gia chiuso

**File:** `lib/screens/mainScreen/tabs/journal/journal.dart:40`, `280-288`

**Problema:** `_selectedSpellRecovery` e un riferimento a un cubit posseduto da `SpellsSection`. Se la sezione viene distrutta mentre il foglio e aperto (per esempio il Diario ricostruisce `Placeholder()` con `CharacterState` non `CharacterLoaded`), il foglio usa un cubit chiuso. Non c'e crash: `BlocBuilder` legge l'ultimo stato. Pero il countdown del foglio resterebbe fermo.

**Fix:** azzerare `_selectedSpell` e `_selectedSpellRecovery` quando il personaggio non e caricato, oppure far leggere il foglio dal `BlocProvider` della sezione invece di passarne il cubit.

### IN-04: Unita di `requiredLearnTime` non confermata

**File:** `lib/utils/spell_lines.dart:59-71`

**Problema:** `spellLearnLabel` assume millisecondi (assunzione A3, commento nel codice). Se il BE usa un'altra unita, il foglio mostra una durata di studio sbagliata di ordini di grandezza. E solo display e il commento lo segnala.

**Fix:** confermare l'unita nell'handoff BE 9.1 durante il gate 08-12 e chiudere l'assunzione. Se serve, aggiungere un test che fissa l'unita.

---

_Reviewed: 2026-10-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
