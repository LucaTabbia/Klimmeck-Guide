# Phase 8: Spells Section (Journal Tab) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-27
**Phase:** 8-spells-section-journal-tab
**Areas discussed:** Recupero magie (SPELL-05), Gesto equip/disequip e limiti, Slot bloccati sotto il titolo Mago, Riga magia e stato ottimistico
**Mode:** interactive (AskUserQuestion, recommended option first); the BE Phase 10 discuss ran in the same session (see the BE repo, `10-DISCUSSION-LOG.md`).

---

## Recupero magie (SPELL-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Statico, solo FE (Recommended) | `usi / maxUsages` + segno «in recupero» + tempo di recupero del catalogo; nessun countdown, nessuna modifica BE | |
| Countdown reale (fase BE 9.1) | Fase BE decimale con il timestamp di recupero su schema; il FE disegna il countdown dal tempo server | ✓ |
| Statico ora, countdown dopo | FE statico, contratto del countdown nel backlog v1.1 | |

**User's choice:** Countdown reale (fase BE 9.1).

### Forma del contratto 9.1

| Option | Description | Selected |
|--------|-------------|----------|
| `recoveries: [DateTime!]!` (Recommended) | Un istante per ogni uso in recupero, ordinato; il processor rimuove il più vecchio | ✓ |
| `nextRecoveryAt: DateTime` nullable | Solo il prossimo istante, ricalcolato dal BE | |

**User's choice:** `recoveries: [DateTime!]!`.

### Scorciatoia disequip → equip (BE Phase 4 D-11 azzera gli usi)

| Option | Description | Selected |
|--------|-------------|----------|
| Blocca il disequip in recupero (Recommended) | `SPELL_RECOVERING` finché `recoveries` non è vuoto | |
| Lascia com'è | Riequipaggiare ridà tutti gli usi | |
| Il recupero segue la magia | Usi e recuperi per magia anche fuori dagli slot | ✓ (free text) |

**User's choice (verbatim):** *«Il recupero vale sempre, che la magia venga equipaggiata o disequipaggiata. Il timer di recupero non si interrompe mai. Se io disequipaggio la magia e 10 secondi dopo dovrebbe recuperare un utilizzo, 10 secondi dopo recupererà un utilizzo».*
**Notes:** this turns the 9.1 companion into a per-spell state (`CharacterStatus.spellStates`) rather than a field on `ActiveSpell`; CONTEXT D-01/D-02.

### Posizione del countdown

| Option | Description | Selected |
|--------|-------------|----------|
| Sulla carta nello slot (Recommended) | Tempo residuo accanto al contatore degli usi sulla `SpellCard` | |
| Nella riga della lista | «Usi: 1/3 · prossimo tra 12 min» nella riga compatta | ✓ |
| In entrambi i posti | Carta e riga | |

**User's choice:** Nella riga della lista.

---

## Gesto equip/disequip e limiti

### Tap su una magia già attiva

| Option | Description | Selected |
|--------|-------------|----------|
| Toggle: la disequipaggia (Recommended) | Equip se inattiva, disequip se attiva; anche il tap sullo slot disequipaggia | ✓ |
| Nessun effetto, solo evidenza | Si disequipaggia solo dallo slot | |

**User's choice:** Toggle.

### Slot pieni

| Option | Description | Selected |
|--------|-------------|----------|
| Bloccato lato client + banner (Recommended) | Nessuna chiamata quando il client sa che gli slot sono pieni; il BE resta il giudice per le gare | ✓ |
| Sempre al BE, rifiuto a banner | Mutation sempre inviata, `MAX_ACTIVE_SPELLS_REACHED` a banner | |

**User's choice:** Bloccato lato client + banner.

### Dettaglio della magia

| Option | Description | Selected |
|--------|-------------|----------|
| No, basta la riga arricchita (Recommended) | Nessun foglio di dettaglio | |
| Sì, long-press apre il foglio | Foglio laterale con `SpellInfo` come l'`EquipmentInfoSheet` | ✓ |

**User's choice:** Sì, long-press apre il foglio.

---

## Slot bloccati sotto il titolo Mago

### `maxActiveSpells == 0`

| Option | Description | Selected |
|--------|-------------|----------|
| Lista + riga neutra (Recommended) | Nessuna riga di slot, copy neutro senza numeri, lista visibile, tap bloccato | ✓ |
| Solo la lista, nessun avviso | Nessuna spiegazione | |
| Slot sigillati con lucchetto | Richiede di conoscere nel FE il numero di slot futuri (contraddice SPELL-07) | |

**User's choice:** Lista + riga neutra.

### Nessuna magia imparata

| Option | Description | Selected |
|--------|-------------|----------|
| Resta, con stato vuoto (Recommended) | `Dropdown` presente con copy «Non hai ancora imparato nessuna magia» | |
| Sparisce del tutto | Sezione non costruita finché non c'è una magia o uno slot | ✓ |

**User's choice:** Sparisce del tutto.

---

## Riga magia e stato ottimistico

### Contenuto della riga (SPELL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Riga compatta sotto la descrizione (Recommended) | «Usi: 3 · Recupero: 2 h · Danno: fuoco 12» | ✓ |
| Solo usi e recupero | Il danno resta solo sulla carta | |
| Tutto nel foglio, riga invariata | Contraddice SPELL-02 | |

**User's choice:** Riga compatta sotto la descrizione.

### Magie attive nella lista

| Option | Description | Selected |
|--------|-------------|----------|
| Restano, marcate (Recommended) | Segno sulla riga, posizione invariata, tap = toggle | ✓ (free text) |
| Attive in testa alla lista | Riordino a ogni equip | |
| Escono dalla lista | Vivono solo nello slot | |

**User's choice (verbatim):** *«Sono marcate con il segnalibro come accade per gli oggetti equipaggiati e restano nella lista al loro posto».*
**Notes:** the marker is the red bookmark of `EquipmentItemCard` (`CloudinaryAssets.bookmarkRed`), to be shared (CONTEXT D-14).

### Stato ottimistico (SPELL-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Subito, con aspetto «in attesa» (Recommended) | Carta attenuata finché la subscription conferma; rollback con rimbalzo + banner | ✓ |
| Subito, indistinguibile | Spostamento definitivo all'occhio, rollback solo su rifiuto | |
| Nessun ottimismo | Contraddice SPELL-06 | |

**User's choice:** Subito, con aspetto «in attesa».

---

## Claude's Discretion

- Ticker and sub-minute wording of the countdown; haptic pattern; pending look, resist/shake and spring-back geometry; detail sheet layout and its toggle affordance; names and location of the shared duration formatter and bookmark widget; model join of `spellStates`; banner copy per code; layer of the mutation methods.

## Carried forward without re-asking

- No UI phase / no UI-SPEC, everything visual provisional (Phase 6 D-19, Phase 7).
- Banner by `extensions.code`, never by message (Phase 6 D-04); 15 s client timeout (Phase 6 D-03).
- Server-time anchoring and duration formatting of Phase 7.

## Deferred Ideas

- FE mapping of `BAD_USER_INPUT` and of the image moderation codes of BE Phase 10 — quick task / Phase 12.
- «Spells used» lines — Phase 9.
- Spell learning UI, slot unlock — backend only.
