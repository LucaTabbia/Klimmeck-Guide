# Phase 15: Travel Food - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-05
**Phase:** 15-travel-food (FE), discussed together with the BE Phase 14 from this repo
**Areas discussed:** Foglio di conferma viaggio, Foglio quest: riga del viaggio, Banner e ricomposizione, Feedback dopo la partenza
**Mode:** interactive, 5 `AskUserQuestion` calls shared with the BE discuss; facts read before the questions (two Explore agents on the FE and BE code, read-only DB inventory of food items, roads, pets and characters, BE Phase 8 handoff §8 for the duration scale). The BE side of the Q&A is in `../Klimmeck-Guide-BE/.planning/phases/14-viaggio-e-cibo/14-DISCUSSION-LOG.md`.

---

## Area selection

User selected all four FE areas and all four BE areas; the two foundation questions (3 minutes per power, triangular HP on the uncovered km) were confirmed with the real numbers (recorded in the BE log).

## Foglio di conferma viaggio

| Option | Description | Selected |
|--------|-------------|----------|
| Due righe sotto Arrivo (Recommended) | «Cibo» = «1x Razione da viaggio, 1x Mela selvatica» (or «nessuno»), «Vita» = «−136 HP» (or «nessuna perdita»); red row + «Parti» disabled when not arriving alive | ✓ (with the user's phrase: «al posto di "Non arriveresti vivo" mettiamo "Non hai cibo a sufficienza per il viaggio"») |
| Elenco di righe oggetto | One row per food with icon and quantity like the shop, then the «Vita» row | |
| Solo i totali | «Cibo: 55 power · Vita: −136 HP» on one line | |

## Foglio quest: riga del viaggio

| Option | Description | Selected |
|--------|-------------|----------|
| Una riga compatta nel blocco costi (Recommended) | «Viaggio: 1x Razione da viaggio · nessuna perdita» / «Viaggio: nessun cibo · −136 HP», red when starving; absent without travel or until the preview answers (no spinner) | ✓ |
| Due righe come il foglio di conferma | «Cibo» and «Vita» rows on the quest sheet too | |
| Solo quando c'è un costo | Line only when something is eaten or lost | |

## Banner e ricomposizione

| Option | Description | Selected |
|--------|-------------|----------|
| Resta così: foglio chiuso + banner (Recommended) | No change to the Phase 7 behaviour; starvation banner enters the catalogue | |
| Foglio aperto con anteprima rinfrescata | On the starvation refusal the sheet stays open, re-requests the preview and shows the new numbers | ✓ |

Confirmation asked after the choice: «solo sul rifiuto per fame; gli altri rifiuti chiudono il foglio come oggi» → **Sì, solo per la fame**.

## Feedback dopo la partenza

| Option | Description | Selected |
|--------|-------------|----------|
| Nessuno (Recommended) | The sheet already said what is eaten and lost; no banner, no animation | ✓ |
| Banner alla partenza | «Hai mangiato 1x Razione da viaggio» (and «−136 HP») | |
| Nota sull'etichetta della pedina | The floating travel label shows the food eaten for a few seconds | |

## Closure

- Reading confirmed: «Non hai cibo a sufficienza per il viaggio» used everywhere (both sheets' red lines and both banners), «Parti» and the swipe disabled → **Sì, ovunque**.
- «C'è altro da aggiungere?» → **No, scrivi i CONTEXT**.

## Claude's Discretion (recorded)

Non-user copy («nessuno», «nessuna perdita», labels), food list formatting, exact position of the «Viaggio» line, whether the red rows also show the numbers, cubit/model/fixture names, how the Board hands the preview to the sheet.

## Deferred

HP on the Map, food icons / item rows, departure banner, manual food choice, ambush report (Phase 16), `QUEST_IN_PROGRESS` missing from `QuestAcceptanceFailure`.
