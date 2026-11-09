# Phase 18: Heal Quests by City Size - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-09
**Phase:** 18-heal-quests-by-size (FE), discussed together with the BE Phase 18 from this repo (worktrees from `develop` in both repos: the Phase 12 Hardening occupies the main FE working tree and another session was planning the BE Phase 17)
**Areas discussed:** Vita (HP), Ferite, Lore, Ore (BE rules); Scheda quest, Descrizioni, Ordine delle fasi (FE and planning); one confirmation of a free-text answer
**Mode:** interactive. The design came out of an advisory conversation earlier in the same session (current rule BE Phase 9 D-15, 166 identical heals at DB, size derived by `citySizeOf`, injury severity only on the FE) where the user fixed the product rules: HP and injuries healed separately with explicit lists per place, free heals, hours by size; the Journal item use was put on stand-by and the whole travel-food rework was deferred. Then 2 `AskUserQuestion` calls (4 + 3 questions) and 1 confirmation. Facts read before the questions: FE quest/prizes/result models and fragments, the two sheets, `item_lines.dart`, `InjuryType` severities; BE models, outcome plan, injury rules, level table, eligibility, city size; three read-only DB inventories. The BE side is in `../Klimmeck-Guide-BE/.planning/phases/18-quest-heal-per-taglia/18-DISCUSSION-LOG.md` (tables of the BE areas).

---

## Scheda quest

Data in the question: lists of 19 / 28 / 37 injuries; the life row always; the result sheet lists the injuries actually healed; declared default: the cure applies to every won quest carrying `prizes.cure`.

| Option | Description | Selected |
|--------|-------------|----------|
| Le tue ferite curabili + conteggio (Recommended) | «Cura le tue ferite: …» plus «guarisce 19 tipi di ferite»; capital «guarisce ogni ferita» | |
| Lista completa | Every injury of the list, as on shop items | |
| Solo etichetta per taglia | «Cure leggere» / «Cure del tempio» / «Cure complete» + life row | |
| Other: «Dice solo le tue ferite curabili» | Only the character's injuries present in the list, no count | ✓ |

Confirmation: no cure line when the character has no curable injury there, only the life row (Recommended) ✓; «Qui non curano le tue ferite» rejected.

## Descrizioni

| Option | Description | Selected |
|--------|-------------|----------|
| Tre varianti per taglia (Recommended) | Small clinic by the temple / temple infirmary / great temple with expert healers; titles unchanged; reviewed on a file before the DB write | ✓ |
| Lasciare le descrizioni attuali | Only lists, HP and hours change | |
| Le scrivo io | User-written variants | |

## Ordine delle fasi

Data in the question: FE 12 Hardening discussed and researched on its branch («last phase of v1.0»), BE 17 being planned in another session.

| Option | Description | Selected |
|--------|-------------|----------|
| 18 prima della 12, Hardening resta ultima (Recommended) | Heals land before the final hardening | |
| 12 Hardening prima, poi la 18 | Planned now, executed after the Hardening merge | ✓ |

## BE areas (answers recorded here for the FE reader)

- Vita: ceiling 50 / 80 / 100 % of the maximum (Recommended) ✓ — not «100 % everywhere», not «increment».
- Ferite: ≤20 / ≤40 / all (19 / 28 / 37) ✓ — not the recommended ≤20 / ≤50 / all, not ≤15 / ≤40 / all.
- Lore: yes, with the proposed table (Recommended) ✓.
- Ore: 2 / 5 / 8 hours (Recommended) ✓.

## Decisions taken before the questions (advisory conversation, same session)

- Separate HP from injuries: `prizes.cure { lifePointsShare, canHeal }` with explicit lists per place (user).
- Heals stay free (user). Hours vary by size (user).
- Heal items used from the Journal: stand-by (user).
- Travel food (gradual HP, progressive meals, hunger debt): deferred (user).
- Cures stay in combat, in the user's engine; recommended loot untouched (user).
