# Phase 16: Travel Ambushes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-06
**Phase:** 16-travel-ambushes (FE), discussed together with the BE Phase 15 from this repo
**Areas discussed:** Foglio del report, Mappa durante la deviazione, Arrivo e ordine dei fogli (the user also ticked «Lascio i default a Claude»: everything not asked stays Claude's discretion)
**Mode:** interactive, 7 `AskUserQuestion` calls shared with the BE discuss; facts read before the questions (two Explore agents on the FE and BE code, read-only DB inventory of enemies, POIs, cities, roads, characters and results, world-building level table, BE Phase 8 handoff §8 for the distances). The BE side of the Q&A (probability, enemies, outcome, delivery) is in `../Klimmeck-Guide-BE/.planning/phases/15-imboscate-in-viaggio/15-DISCUSSION-LOG.md`.

---

## Area selection

User selected all four BE areas and the three FE areas plus «Lascio i default a Claude»; the two foundation questions (soft calibration, Phase 13 composition in the [Facile, Medio] band) are recorded in the BE log.

## Foglio del report

| Option | Description | Selected |
|--------|-------------|----------|
| Stesso foglio, intestazione «Imboscata presso X» (Recommended) | Same parchment: outcome, «Imboscata presso <città del POI>» with date, enemies with portraits, HP bar, injuries; won: coins and XP; lost: «Portato a <città più vicina>»; «Continua» confirms | ✓ |
| Foglio dedicato più cupo | Own darker variant with the same data | |

## Mappa durante la deviazione

| Option | Description | Selected |
|--------|-------------|----------|
| Nessun avviso: solo la rotta che cambia (Recommended) | Coherent with «tutto all'arrivo» | |
| Banner in-app al cambio di rotta | «Imboscata! La via torna verso X» when `activeTravel` changes destination, no push | |
| Other (user) | «Nel caso in cui tu venga sconfitto (e quindi deviato verso un paese diverso da quello della metà) vorrei una notifica e un banner nuovo» | ✓ |

Follow-up reading (new push category + banner only when the nearest city differs from the destination, tap → Map, settings entry, no notice on victories):

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, così | Push + banner only on a defeat with a detour | |
| Sì, ma anche quando la città più vicina è la meta | Every defeat notifies | ✓ |
| Spiega meglio | | |

## Arrivo e ordine dei fogli

Push at arrival (asked twice: the user first answered «Spiega meglio», then with the explanation of today's `travelEnd` / silent marker arrival / `questEnd` flow):

| Option | Description | Selected |
|--------|-------------|----------|
| Solo `travelEnd` come oggi (Recommended) | No push of their own for the reports; after a won ambush towards a quest marker no push, the report waits in the app | ✓ |
| `travelEnd` + un push per report | 1 + N pushes, also at the marker | |
| Push dedicato «Imboscate» | One new push replacing `travelEnd` on ambushed travels; new settings category | |

Closing question (order of the sheets: ambush reports carry the ambush instant as date, so the existing queue shows them chronologically before any quest result; anything else?):

| Option | Description | Selected |
|--------|-------------|----------|
| No, scrivi i CONTEXT | | |
| Sì, aggiungo una regola | | |
| Other (user) | «invece di mettere tutto sullo stesso foglio, fai un carosello con un foglio per ogni imboscata, così è più pulito e chiaro» | ✓ |

Carousel reading (one carousel per travel, one parchment per ambush, horizontal pages with indicator, chronological; «Continua» closes and acknowledges all; one ambush = one page without indicator; quest results one at a time after the carousel):

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, così | One carousel per travel, acknowledgement of all on close | ✓ |
| Sì, ma conferma pagina per pagina | Each parchment has its own «Continua» | |
| Spiega meglio | | |

## Claude's Discretion

Copy of the non-user strings, page indicator and transition, whether the carousel reuses `QuestResultSheet` as a page, the cubit group API, fixture names, how the city name travels in the push data, the reroute test harness.

## Deferred Ideas

Client-derived reroute banner, darkened unknown enemies (Phase 17), HP on the Map, loot from ambushes, dedicated darker sheet, per-page acknowledgement.
