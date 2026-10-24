# Phase 6: Quest Accept & Info Sheets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-21
**Phase:** 06-quest-accept-info-sheets
**Areas discussed:** Conferma/costo/rollback, Gesto strappo e post-accept, Layout per tipo, Board/corsie/countdown (+ chiarimenti con impatto BE)

---

## Conferma, costo, rollback

| Option | Description | Selected |
|--------|-------------|----------|
| Lo swipe è la conferma | Nessun dialog, costo visibile sullo sheet | ✓ |
| Dialog solo per quest con costo | Dialog per story/worldMission | |
| Dialog sempre | Dialog per ogni accettazione | |

| Option | Description | Selected |
|--------|-------------|----------|
| Riga 'saldo / costo' evidenziata | Sostituisce il 3000 hard-coded, rosso se insufficiente | ✓ |
| Solo il costo | Saldo altrove | |
| Decidi tu | In UI phase | |

| Option | Description | Selected |
|--------|-------------|----------|
| Strappo subito, navigazione al successo | Animazione col gesto, Mappa solo dopo l'ok del BE | ✓ |
| Tutto subito, rollback completo | Strappo e navigazione immediati | |
| Nessun ottimismo | Strappo solo al successo | |

| Option | Description | Selected |
|--------|-------------|----------|
| Banner in-app di Phase 5 | Strip pergamena, auto-dismiss | ✓ |
| Dialog modale di dominio | Dialog a un pulsante | |
| Messaggio inline sullo sheet | Testo nel foglio | |

---

## Gesto strappo e post-accept

| Option | Description | Selected |
|--------|-------------|----------|
| Due metà che si separano | Clip del foglio esistente, nessun asset nuovo | ✓ |
| Asset del foglio strappato | SVG strappato su Cloudinary | |
| Decidi tu in UI phase | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Foglio strappato centrato, poi via | Overlay temporaneo, mappa centrata sul marker | |
| Foglio strappato persistente | Badge finché la quest è attiva, apribile | ✓ |
| Decidi tu in UI phase | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Solo board | Lo sheet nella Mappa resta informativo | ✓ |
| Board e Mappa | Gesto in entrambi i contesti | |

---

## Layout per tipo

| Option | Description | Selected |
|--------|-------------|----------|
| Tre famiglie | Combattimento / Narrativa / Servizio | ✓ |
| Una variante per tipo | Dieci layout | |
| Decidi tu in UI phase | | |

| Option (multi) | Description | Selected |
|--------|-------------|----------|
| Titolo richiesto | minTitle con evidenza | ✓ |
| Posti per rango | party + registrati | ✓ |
| Già affrontata | non ripetibili in completedQuests | ✓ |
| Loot consigliato | recommendedLoot display-only | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Lore dentro lo sheet | relatedLore leggibile e scrollabile | ✓ |
| Solo rimando al diario | | |
| Decidi tu in UI phase | | |

---

## Board, corsie, countdown

| Option | Description | Selected |
|--------|-------------|----------|
| Nascondi corsia occupata e già fatte | Il resto visibile con swipe bloccato | |
| Nascondi tutto il non accettabile | Solo quest accettabili ora | |
| Mostra tutto, blocca solo lo swipe | | |

**User's choice (free text):** "Si mostrano tutte le quest accettabili nella città dove ci si trova. La board non è accessibile durante il viaggio (si disabilita il pulsante sul menù e si rende la casella più scura…). Mostri quindi tutte le quest relative al posto (job, hunt e dungeon ripetibili e presi da più persone in contemporanea), mentre le missioni story e worldMission sono accettabili in tutte le città. Le missioni con una caccia (boss, enemy, aid) una volta accettate da qualcuno sono visibili come strappate sulla board finché sono ancora pending; completate con successo scompaiono, se falliscono possono essere riprese da qualcun altro (eccetto aid) e si vede di nuovo l'asset intero."

| Option | Description | Selected |
|--------|-------------|----------|
| Sul foglio strappato della Mappa | Un foglio per corsia attiva | ✓ |
| In testa alla board | | |
| In entrambi | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Testi di stato dedicati | In viaggio / In attesa dell'oste / Tempo scaduto | |
| Solo il countdown | | |
| Decidi tu in UI phase | | |

**User's choice (free text):** "Quando si arriva a 0 di viaggio allora compare la dicitura (In combattimento… lavorando… guarendo… esplorando… cacciando…) più azzeccata per il tipo di quest. Il foglio di worldMission e di story non compare mai sulla mappa. La dicitura resta attiva finché non arriva il risultato del combattimento." Poi: "Il countdown del waitingTime non si vede, per il resto va bene la prima opzione" (In viaggio → dicitura per tipo).

### Chiarimenti con impatto BE

| Option | Description | Selected |
|--------|-------------|----------|
| Nella BE Phase 8 | Esenzione città per story/worldMission nella fase che tocca già l'accettazione | ✓ |
| Fase BE decimale 7.1 | | |
| Solo FE per ora | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Marcatura in BE 8, esiti in BE 9 | Stato sulla Quest + esclusività enemy/aid | (sostituita dal chiarimento) |
| Tutto in BE Phase 9 | | |
| Fase BE decimale 7.1 | | |

**User's clarification (free text):** "Quest ha registeredAdventurers. Quando il numero di registeredAdventurers raggiunge lo stesso numero di requiredAdventurers allora la quest risulta strappata. Se la quest accetta più di un avventuriero, se il tuo rango è completo allora vedrai la scheda strappata, altrimenti intera. Vedo che hai aggiunto un registrations… si poteva modificare registeredAdventurers in modo da essere un array di oggetti contenenti rango e ids. La quest aid viene creata in automatico quando una quest enemy, hunt, boss o dungeon fallisce per un utente. A quel punto la quest torna disponibile e compare anche la quest di aid. Se chi accetta la quest di aid fallisce, il personaggio che ha fallito la prima quest muore (e viene quindi cancellato), mentre il secondo che ha fallito farà scattare una nuova quest di aid e così via."

| Option | Description | Selected |
|--------|-------------|----------|
| In Phase 6, se BE 8 è su develop | Board disabilitata in viaggio già in Phase 6 | |
| Rinvia alla FE Phase 7 | | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| In viaggio → dicitura + countdown quest | | ✓ (senza il countdown) |
| Solo la dicitura, nessun countdown quest | | |
| Decidi tu in UI phase | | |

| Option | Description | Selected |
|--------|-------------|----------|
| worldMission, boss, enemy, aid | Registrazione con capienza; hunt/dungeon/job/heal/study no | ✓ |
| Solo worldMission e boss | Come Phase 7 | |
| Tutti i tipi con requiredAdventurers > 0 | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Oggetti { character, title } | registeredAdventurers con rango, registrations rimosso | ✓ |
| Tenere gli id, esporre registrations | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Stato per tipo, offset in Phase 7 | Nessun countdown né serverTime in Phase 6 | ✓ |
| Stato per tipo + offset già in Phase 6 | | |

---

## Follow-up (stessa sessione): asset, Mappa, story, board

| Option | Description | Selected |
|--------|-------------|----------|
| Mantieni, estendi isFull al rango | Stessi asset per tipo, regola 'pieno' per somma dei count o rango esaurito | ✓ |
| Cambia la mappatura | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Asset strappato della board | Foglietto strappato del tipo | |
| Sheet grande in due metà | | |
| Decidi tu in UI phase | | |

**User's choice (free text):** "Asset intero della board. Quando lo clicchi ha la stessa presentazione della missione nella board, ma si aggiunge anche lo stato."

| Option | Description | Selected |
|--------|-------------|----------|
| Solo la story del mio titolo | Una sola story visibile | ✓ |
| Tutte e 5, una sola accettabile | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Strappata per me | | |
| Nascosta | | |
| Intera, swipe bloccato | | |

**User's choice (free text):** "Questa situazione è possibile solo con le missioni di tipo story e worldMission, perché negli altri casi saresti o in viaggio o in un altro POI dopo aver accettato la quest e potresti tornare in città solo a quest finita […]. Nel caso di worldMission e story le vedi strappate."

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, solo in città | Board disabilitata fuori dal marker di una città | ✓ |
| No, accessibile ovunque | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Strappate per me | QUEST-04 emendato: story/worldMission attive restano in lista strappate | ✓ |
| Nascoste (QUEST-04 com'è) | | |

## Nota finale dell'utente

"Per quanto riguarda la fase ui di FE: non è necessaria. Ogni cosa sviluppata da te è provvisoria e verrà rivista da me." → nessun `/gsd-ui-phase 6`; dettagli visivi a discrezione, provvisori.

## Claude's Discretion

Haptic pattern e geometria dello strappo; posizione del foglio strappato sulla Mappa e centratura; come lo sheet blocca lo swipe; forma di Repository/Cubit; fallback della regola "strappata per gli altri" prima della merge BE 8; copy del banner per codice.

## Deferred Ideas

Board disabilitata in viaggio e offset serverTime (FE Phase 7); esiti delle quest, quest aid automatiche e morte (Phase 9 BE/FE); indicatore "in attesa del GM" per story/worldMission; swipe dalla Mappa; undo; layout crime/guard; countdown della quest.
