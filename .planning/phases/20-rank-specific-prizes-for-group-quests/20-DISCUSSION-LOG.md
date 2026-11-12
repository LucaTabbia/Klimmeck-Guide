# Phase 20: Rank-Specific Prizes for Group Quests - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-12
**Phase:** 20-rank-specific-prizes-for-group-quests
**Areas discussed:** Which quests, Rank key, Origin of blocks, Sheet, Mixed bosses, Block fields, Hand-written quests, Open seats, Aid flow, DB cleanup

## Round 1
| Question | Options | Selected |
|---|---|---|
| Which quests | worldMission+aid / only worldMission / worldMission+aid+mixed bosses | mixed bosses included, plus the aid explanation (aid = clone of enemy/boss/hunt/dungeon/aid lost; audit and fix the aid flow; clean wrong aids at DB) |
| Rank key | character's rank / seat's rank | character's rank |
| Origin | tables then hand edits / hand only / computed at win | tables then hand edits |
| Sheet | own rank only / all ranks highlighted | own rank only |

## Round 2
| Question | Selected / user's words |
|---|---|
| Mixed bosses | «Sono quest randomiche… Possono includere posti del rango inferiore, non di quello superiore» |
| Block fields | coins, xp, loot per rank; pet/spell/cure shared |
| Hand-written quests | «Se dovessi scrivere una quest a mano, allora deciderei io i premi per rango» |
| Open seats | «Il rango minimo vale solo per le quest in solitaria. Le quest di gruppo hanno i blocchi di rango, senza posizioni libere…» |

## Aid audit (subagent, read-only) and user's note
Findings: aid on any lost fight; dungeon aid fought as one battle; lost rescue kills the original wounded (D-09); archiver may not release rescuers' lanes. The 3 DB aids: real defeats, closed by hand at DB in UAT (user: «potrebbero essere state create e risolte dopo i miei test manuali» — confirmed: failure on the source, no QuestResult on the aid).

## Round 3
| Question | Selected |
|---|---|
| Lost rescue | as today |
| Dungeon aid | user describes the turn rhythm; save the encounter of the defeat; rescuer reaches and wins it; aid ends; dungeon available again |
| Aid types | only enemy, boss, hunt, dungeon, aid |
| DB cleanup | delete with backup (done: 3 deleted) |

## Round 4
| Question | Selected |
|---|---|
| Dungeon aid prize | proportional to the encounters cleared |
| «Dungeon available» | for the rescued character |
| Engine depth | structure + placeholder |

## Claude's Discretion
Wire shape of the viewer's block; mixed-boss frequency; rounding of the proportional prize; field names.

## Deferred Ideas
Turn-based dungeon engine (user); innkeeper prize step (Phase 21); BE companion phase to open.

## Note from the user (2026-11-12)
«Tieni da conto che in una quest dungeon puoi venire sconfitto anche in un turno di esplorazione, non necessariamente in uno scontro» → D-12..D-14 rewritten on turns (exploration or fight) instead of encounters.

## Notes from the user (2026-11-12, after the merges)
- Spells shared only for ranks ≥ mage; lower ranks lose the spell → D-05 amended; BE gap (no rank gate on learning) → D-05b.
- Crime defeat = 10 h prison, no aid (UAT memory) → verified in code (arrest event, no aid) → D-09b, no change.
