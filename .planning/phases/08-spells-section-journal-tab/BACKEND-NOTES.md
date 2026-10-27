# BACKEND-NOTES — FE Phase 8 Spells Section (handoff FE → BE Phase 9.1)

**Scritto:** 2026-10-27 (discuss FE Phase 8 + inserimento della BE Phase 9.1 nella stessa sessione)
**Destinatario:** la BE Phase 9.1 «Spell State and Recovery Contract» (`Klimmeck-Guide-BE/.planning/phases/09.1-spell-state-and-recovery-contract/`), che fissa il contratto nel proprio `09.1-CONTEXT.md` e lo restituisce nel proprio `BACKEND-NOTES.md`. Lo schema generato `src/schema.gql` su `origin/develop` vince su tutto ciò che è scritto qui.

---

## 0. TL;DR per il BE

1. **Regola dell'utente (2026-10-27, verbatim):** *«Il recupero vale sempre, che la magia venga equipaggiata o disequipaggiata. Il timer di recupero non si interrompe mai. Se io disequipaggio la magia e 10 secondi dopo dovrebbe recuperare un utilizzo, 10 secondi dopo recupererà un utilizzo».* Usi e recuperi sono **per magia conosciuta**, non per slot: la Phase 4 D-11 («equip riporta gli usi a `maxUsages`») è superata.
2. Il FE chiede **un solo campo nuovo, additivo:** `CharacterStatus.spellStates: [SpellState!]!` con `SpellState { spell: Spell!, usages: Int!, recoveries: [DateTime!]! }` (§2). `ActiveSpell { spell, usages }` resta sul filo per l'ordine degli slot; il FE legge usi e recuperi solo da `spellStates`.
3. `recoveries` è **ordinato crescente**: il primo istante è il prossimo uso che torna. Il FE lo confronta con l'ora del server (`serverTime`, Phase 7) e mostra «prossimo tra X».
4. Il FE continua a chiamare `equipSpell`/`unequipSpell` con `EquipSpellRequest { id, spellId }` e **non invia più `usages`**. Codici attesi: quelli di oggi (§5). Se la 9.1 ne aggiunge o ne toglie, scriverlo nel handoff.
5. Il FE sviluppa su fake finché la PR 9.1 non è su `develop`; il piano finale della FE Phase 8 esegue lo schema check contro `origin/develop`. **PR BE prima della PR FE.**

---

## 1. Cosa consuma il FE oggi

- `CharacterFragment` seleziona `status.maxActiveSpells`, `status.spells { …SpellFields }`, `assets.activeSpells { usages spell { …SpellFields } }`.
- `SpellFields`: `id name description useType maxUsages minXpToLearn recoveryTime requiredLearnTime energyDamage { type power }`.
- Mutation già nei documenti FE: `equipSpell(request: EquipSpellRequest!)`, `unequipSpell(request: EquipSpellRequest!)` → `CommonResponse { response successful }`.
- Subscription `characterUpdated(id)` porta l'intero `Character` dopo ogni scrittura (Phase 3).

## 2. Contratto proposto (SDL)

```graphql
type SpellState {
  spell: Spell!
  usages: Int!
  recoveries: [DateTime!]!
}

type CharacterStatus {
  # … campi esistenti …
  spellStates: [SpellState!]!
}
```

Semantica richiesta dal FE:

- Una voce per ogni id in `status.spells`, nello **stesso ordine** (il FE fa comunque il join per `spell.id`, l'ordine è una comodità).
- `usages` ∈ [0, `spell.maxUsages`]; `recoveries.length == maxUsages − usages` quando tutti i recuperi sono tracciati (il FE tollera liste più corte: per i job accodati prima del deploy mostra «in recupero» senza tempo).
- `recoveries` crescente; ogni istante è l'ora server (UTC) in cui un uso torna. Il FE non calcola `dueAt` da solo (`recoveryTime` in millisecondi serve solo per la riga informativa «Recupero: 2 h»).
- `equipSpell` **non** tocca lo stato; `unequipSpell` **non** tocca lo stato; i recuperi continuano a scadere anche fuori dagli slot.
- `ActiveSpell.usages` vale sempre quanto `spellStates[…].usages` della stessa magia (come garantirlo è una scelta BE: mirror atomico o risoluzione al confine di lettura); il FE non lo usa più per il countdown.

## 3. Flusso FE

1. Lista «Magie imparate»: per ogni `status.spells[i]` la riga mostra carta + descrizione + «Usi: `usages`/`maxUsages` · prossimo tra X» (X = `recoveries[0] − serverNow`, arrotondato per eccesso al minuto) oppure «Usi: 3 · Recupero: 2 h» a usi pieni.
2. Slot: `maxActiveSpells` box, riempiti con `activeSpells[i]`; il contatore sulla carta legge `spellStates`.
3. Tap su una riga inattiva → `equipSpell` (ottimistico, 15 s di timeout); tap su una riga attiva o su una carta nello slot → `unequipSpell`. Slot pieni o `maxActiveSpells == 0` → nessuna chiamata, banner.
4. Rifiuto → rollback + banner per `extensions.code`; `SPELL_ALREADY_ACTIVE` / `SPELL_NOT_ACTIVE` → solo riallineamento silenzioso.
5. Il nuovo stato arriva da `characterUpdated`; la risposta della mutation non costruisce stato.

## 4. Migrazione e compatibilità (richieste del FE)

- Il campo deve esistere per **tutti** i personaggi attivi dal primo deploy: lista vuota ammessa solo per chi non conosce magie. I personaggi esistenti con magie attive devono partire con `usages` uguale a quello di oggi in `activeSpells` e `recoveries: []` (i job legacy restituiranno gli usi senza timestamp: il FE mostra «in recupero» senza tempo finché non torna al massimo).
- Nessun campo esistente cambia tipo o significato; `EquipSpellRequest.usages` può restare deprecato o sparire (il FE non lo invia).

## 5. Codici di rifiuto che il FE mappa

| Codice | Mutation | Reazione FE |
|---|---|---|
| `SPELL_NOT_KNOWN` | `equipSpell` | rollback + banner, refetch implicito dalla subscription |
| `SPELL_ALREADY_ACTIVE` | `equipSpell` | riallineamento silenzioso |
| `MAX_ACTIVE_SPELLS_REACHED` | `equipSpell` | rollback + banner «Slot pieni» |
| `SPELL_NOT_ACTIVE` | `unequipSpell` | riallineamento silenzioso |
| `NOT_FOUND`, `FORBIDDEN` | entrambe | rollback + banner generico |
| `UNAUTHENTICATED` | entrambe | silenzio (il flusso di sessione agisce) |
| `BAD_USER_INPUT` | entrambe (dalla BE Phase 10) | rollback + banner generico |

## 6. Domande per il BE (da chiudere nel 09.1-CONTEXT / handoff)

1. `ActiveSpell.usages`: mirror atomico in `assets.activeSpells` o risoluzione dallo stato? Il FE è indifferente purché i due valori coincidano in ogni emissione.
2. Il recupero di una magia **non attiva** avviene lo stesso (regola dell'utente): confermare che processor e sweep non filtrano più su «attiva».
3. Sweep/reconciler per i recuperi scaduti (job Bull perso): il FE mostra «prossimo tra 0 min» finché il BE non emette; con uno sweep a 60 s l'attesa è accettabile. Confermare l'intervallo.
4. `SPELL_RECOVERY_UNAVAILABLE` (Phase 4 D-13) resta? Il FE non lo mappa oggi; se sparisce non cambia nulla, se resta va in banner generico.
5. Dati UAT: un personaggio `mage` con ≥ 2 magie conosciute, una attiva con `usages < maxUsages` e due istanti in `recoveries` (uno a ~2 min, uno a ~30 min), una non attiva anch'essa in recupero; un personaggio sotto `mage` con una magia conosciuta.

## 7. Stato

- 2026-10-27 — proposta scritta nel discuss FE Phase 8; BE Phase 9.1 inserita nel roadmap BE con CONTEXT scritto dalla stessa sessione; in attesa della PR BE.
- 2026-10-27 — **E2E su device Android superato 12/12** contro BE `develop` `10e5f43` (PR #14, Phase 9.1) in locale, sweep a 60 s di default; FE `ba7d866`. Esito rilevante per il BE:
  - countdown dal primo istante di `spellStates[].recoveries` sul tempo server corretto (passi 2 e 11: cambio orologio del telefono di ±2 h senza effetto);
  - ritardo dello sweep osservato: +28 s (passo 2, uso restituito alle 18:15:26 per l'istante 18:14:58, DB 2/3 con un istante residuo) e +19 s (passo 3, «1 usi restituiti» alle 18:19:26 per l'istante 18:19:07);
  - recupero con magia disequipaggiata confermato (passo 3: slot vuoto, uso restituito, riequip a 3/3 invariato, nessun reset);
  - mirror `activeSpells[].usages` coerente con `spellStates` (slot 2 a 2/3);
  - `equipSpell` via GraphQL con l'app in background consegnato live da `characterUpdated` (passo 9, ramo A: nessun `SPELL_ALREADY_ACTIVE` osservato perché la subscription è arrivata prima del tap);
  - il change stream MongoDB sulla collection characters consegna anche gli aggiornamenti diretti al DB (semine `mage`/`adventurer` e promozione a `mage` ricevute live).
  Dati UAT: un solo personaggio attivo nel DB dev, seminato prima come `mage` poi come `adventurer` da uno script in scratchpad (mai in repo); magie Palla di fuoco e Scurovisione. Nessun id utente, token o valore `.env` nelle note.
  Da riportare in BE .planning/phases/09.1-spell-state-and-recovery-contract/ (UAT) a cura del lato BE (questo repo non modifica il BE).
