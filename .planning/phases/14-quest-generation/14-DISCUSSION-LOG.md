# Phase 14: Quest Generation (frontend companion) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-04
**Phase:** 14-quest-generation (FE), discussed together with the BE Phase 13 from this repo
**Areas discussed:** Nemici sul foglio quest, Foglio esiti, Genera missioni in Locanda, Annuncio e tipi fissi, Gioielli `accessoryUseTypes` (new area raised by the user)
**Mode:** interactive, 9 `AskUserQuestion` calls shared with the BE discuss; facts read before the questions (two Explore agents on the FE and BE code, read-only DB inventory, BE Phase 11 handoff). The BE side of the Q&A is in `../Klimmeck-Guide-BE/.planning/phases/13-generazione-quest/13-DISCUSSION-LOG.md`.

---

## Area selection

User selected all four FE areas (Nemici sul foglio quest, Foglio esiti, Genera missioni in Locanda, Annuncio e tipi fissi) and all four BE areas.

## Nemici sul foglio quest

| Option | Description | Selected |
|--------|-------------|----------|
| Un ritratto + righe con quantità (Recommended) | One portrait (strongest enemy), «Nx nome» lines per type | ✓ |
| Un ritratto per tipo con badge | Horizontal row of portraits with quantity badges | |
| Solo testo | No portraits | |

| Option | Description | Selected |
|--------|-------------|----------|
| Caricamento da rete, nascosto se manca (Recommended) | Cloudinary path, cached, hidden on failure | ✓ |
| Lascia com'è | Name only until Phase 17 | |
| Ritratto di famiglia | Generic bundled image per quest type | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, sotto i nemici (Recommended) | «Consigliati» in the combat body, left column | ✓ |
| Sì, nella colonna destra | After time/title/slots | |
| No | Combat layout without recommendations | |

## Foglio esiti

| Option | Description | Selected |
|--------|-------------|----------|
| Lista + tappe della dungeon (Recommended) | Enemy list with quantities, «Esplorazione: tappa k di N» from BE counters | ✓ |
| Solo la lista | No stage detail | |
| Lista dei soli nemici battuti | Hide the stages not reached | |

## Genera missioni in Locanda

| Option | Description | Selected |
|--------|-------------|----------|
| In testa alla lista (Recommended) | Button above the request cards, always visible | ✓ |
| Azione nell'AppBar | Icon action, SnackBar outcome | |
| Sezione «Mondo» in coda | Block at the bottom | |

| Option | Description | Selected |
|--------|-------------|----------|
| Dialog + riga di esito (Recommended) | Shared confirmation dialog, outcome line under the button | |
| Dialog + SnackBar | Shared confirmation dialog, outcome in SnackBar, FORBIDDEN closes the panel | ✓ |
| Senza conferma | Immediate call | |

## Annuncio e tipi fissi

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, sotto il titolo (Recommended) | `infos.description` under the title in every family | ✓ |
| Sì, solo combat e servizio | Not on narrative sheets | |
| No, rinviato | Deferred | |

`crime`/`guard`/`dungeon` family mapping: stated as a fact (already correct), no question; the empty `imagePath` of the crime/guard pawn goes to the research (D-11).

## Gioielli `accessoryUseTypes` (new area, user)

Rule dictated by the user at the closing question (verbatim in the BE CONTEXT D-23/D-25; FE consumes the field).

| Option | Description | Selected |
|--------|-------------|----------|
| Riga sul foglio dell'oggetto (Recommended) | Model + fragment, «Uso: attacco / difesa / attacco e difesa» on rings and necklaces only | ✓ |
| Solo modello e fragment | No UI | |
| Riga + sigla nelle liste | Also a badge in Journal/shop rows | |

## Closing

«Scrivi i CONTEXT (Recommended)» ✓ (after the jewels area was added and discussed).

## Claude's Discretion

Copy of the new lines and SnackBars, spacing of the combat body, cubit/widget names, fixtures, Cloudinary URL mapping of `imagePath`, pet prize line placement.

## Deferred Ideas

Darkened unknown enemies (Phase 17), live board refresh on inserts, companion prize beyond a line, crime/guard state labels, alignment mechanic (v2).
