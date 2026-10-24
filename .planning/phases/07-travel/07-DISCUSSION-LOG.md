# Phase 7: Travel - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-24
**Phase:** 07-travel
**Areas discussed:** Innesco e dialog di conferma, Viaggio in corso sulla mappa, Blocchi/rifiuti/viaggio da quest, Arrivo/popup/notifiche
**Mode:** interactive (AskUserQuestion, 4 questions per block), discussed in the same session as BE Phase 9

---

## Innesco e dialog di conferma

| Option | Description | Selected |
|--------|-------------|----------|
| Tap sul marker città → azione "Viaggia" nel foglio della città | CityModal gains an action; drag removed | |
| Drag della pedina sulla città (gesto esistente) | Release opens the confirmation; cancel springs back | ✓ |
| Entrambi | Both paths | |

**User's choice:** drag of the pawn.

| Option | Description | Selected |
|--------|-------------|----------|
| Foglio di pergamena con città, distanza, durata, ETA, "Parti"/"Resta" (Recommended) | Parchment sheet, no cost | ✓ |
| Solo durata e ETA, minimale | One line + button | |
| Mostra anche il bonus del pet | Needs FE inference, fragile | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sì: foglio in basso e rotta tratteggiata sulla mappa dietro, camera su partenza e meta (Recommended) | Bottom sheet + preview polyline | ✓ |
| No: solo i numeri nel foglio | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Dopo "Parti" andato a buon fine (Recommended) | Prompt after `startTravel` ok | ✓ |
| Al tap su "Parti", prima della mutation | | |
| All'apertura del foglio di conferma | | |

Follow-ups:

| Option | Description | Selected |
|--------|-------------|----------|
| Solo dentro l'area di una città (o vicino al marker); altrove la pedina torna indietro (Recommended) | | |
| Città più vicina al punto di rilascio, sempre | Current behaviour | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| No: pedina non trascinabile; il BE resta il giudice (Recommended) | With `activeTravel`/`pendingQuest` the drag does not start | ✓ |
| Sì: trascinabile, al rilascio banner col motivo | | |

| Option | Description | Selected |
|--------|-------------|----------|
| La pedina torna indietro in silenzio, nessuna chiamata (Recommended) | Same-city release | ✓ |
| Banner "Sei già in questo luogo" | | |

**Notes:** after "Resta" or a BE rejection the pawn returns to the real location.

---

## Viaggio in corso sulla mappa

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, intera, con il tratto già percorso in un tono diverso (Recommended) | | ✓ |
| Sì, ma solo il tratto che resta da percorrere | | |
| No: solo la pedina in movimento | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Foglio di viaggio in alto come il foglio quest: "Verso <città>" + countdown; tap → dettagli (Recommended) | | |
| Etichetta flottante sopra la pedina con il tempo residuo | | ✓ |
| Nessun countdown | | |

| Option | Description | Selected |
|--------|-------------|----------|
| No follow: inquadra la pedina una volta; il tap sul foglio di viaggio ricentra (Recommended) | | ✓ (without the travel paper, see follow-up) |
| Follow continuo finché l'utente non tocca la mappa | | |
| Nessun ricentraggio automatico | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Pedina ferma sull'ultimo punto, countdown → "In arrivo…"; snap solo all'evento (Recommended) | | ✓ |
| Come sopra, più un'animazione di attesa sulla pedina | | |

Follow-ups:

| Option | Description | Selected |
|--------|-------------|----------|
| Nessun ricentraggio esplicito oltre l'inquadratura iniziale (Recommended) | | ✓ |
| Piccolo sigillo/pedina in un angolo che ricentra | | |
| Doppio tap sulla mappa ricentra | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Solo il tempo residuo, poi "In arrivo…" (Recommended) | | ✓ |
| Meta e tempo: "Verso <città> · 1 h 12 min" | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sì: lo stesso foglio della conferma in sola lettura (Recommended) | Tap on the pawn opens details | |
| No: l'etichetta basta | | ✓ |

---

## Blocchi, rifiuti e viaggio da quest

| Option | Description | Selected |
|--------|-------------|----------|
| Tutto leggibile; disabilitati solo drag della pedina e Bacheca (Recommended) | | |
| Disabilitare anche il negozio durante il viaggio | | ✓ |
| Solo la Bacheca disabilitata; pedina trascinabile col banner | Contradicts the earlier choice | |

| Option | Description | Selected |
|--------|-------------|----------|
| Identico al viaggio libero: rotta, pedina, etichetta; il foglio quest resta "In viaggio" (Recommended) | | ✓ |
| Pedina ed etichetta, senza rotta | | |
| Solo il foglio quest "In viaggio" | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Copy FE per codice, partendo dai messaggi del BE (Recommended) | | ✓ (after a change of mind) |
| Mostrare il messaggio del BE così com'è | First pick, then reverted: "Ho cambiato idea, fai un catalogo anche in questo caso" | |

| Option | Description | Selected |
|--------|-------------|----------|
| Solo il banner; il BE logga già un WARN per il GM (Recommended) | | ✓ |
| Banner con invito "Segnalalo al locandiere" | | |

Follow-up:

| Option | Description | Selected |
|--------|-------------|----------|
| Sì: negozio solo in città, come la Bacheca (Recommended) | Shop disabled also on a quest POI | ✓ |
| No: chiuso solo durante il viaggio | | |

---

## Arrivo, popup e notifiche

| Option | Description | Selected |
|--------|-------------|----------|
| Camera sulla pedina + foglio della città di arrivo (Recommended) | | |
| Solo camera sulla pedina, nessun popup | | ✓ |
| Popup dedicato "Sei arrivato a <città>" con riepilogo | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Nulla in più: snap + banner (Recommended) | Foreground arrival | ✓ |
| Apri anche il foglio della città se la Mappa è visibile | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Nulla in più: snap e il foglio quest cambia etichetta (Recommended) | Quest travel arrival | ✓ |
| Banner in-app generato dal FE "Sei giunto sul posto" | | |

**Closing:** "FE chiara: scrivi il CONTEXT e passa alla BE Phase 9".

## Claude's Discretion

Route/label styling, ETA formatting for multi-day travels, pawn animation, in-sheet loading during the preview, optional refetch at progress 1, clock-offset service, file/class names, drag threshold details.

## Deferred Ideas

BE shop guard (`SHOP_NOT_IN_CITY`, BE Phase 9); details sheet on pawn tap; recenter control; arrival popup; "Segnalalo al locandiere" copy; pet bonus line; travel cost; cancel/re-route; push for quest travel; return-to-city and "awaiting aid" (Phase 9); admin teleport UI (Phase 10).
