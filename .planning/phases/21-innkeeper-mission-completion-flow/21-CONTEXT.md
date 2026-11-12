# Phase 21: Innkeeper Mission Completion Flow - Context

**Gathered:** 2026-11-12
**Status:** Ready for planning — BE companion: **BE Phase 22 «Completamento guidato delle missioni»** (BE-GMFLOW-01..07, branch `feat/22-completamento-guidato-missioni`); depends on FE Phase 20 / BE Phase 21 (rank blocks)

<domain>
## Phase Boundary

The innkeeper completes a `story` or `worldMission` request from the Locanda through a guided flow that replaces the single completion form of Phase 10: teleport → encounters (enemies chosen from a filtered list, one fight or several in sequence) → simulation on the backend engine without writing on the characters → manual corrections → prizes per character starting from the rank block → completion. The backend owns the enemy lists, the simulation, the draft and the final write; the app drives the steps. The Locanda stays a utility surface (Phase 10 D-01/D-22: Material controls allowed, provisional visuals, no UI phase).

</domain>

<decisions>
## Implementation Decisions

### Step 1 — Teleport
- **D-01:** The group is moved with the **Phase 10 Map drag** (pawn «Gruppo · N», «Modalità Locanda»), but the drop now accepts **city markers and inner POIs** (ruins, caves, forests…; supersedes Phase 10 D-16 «city markers only», whose inner POIs were deferred). The step is **skippable** when the group is already at the chosen place. The place sets the POI types used by step 2.

### Step 2 — Encounters and enemies
- **D-02:** The innkeeper builds **one fight or several fights in sequence**, each with one enemy or several (kind + quantity with a stepper) — user: «Posso decidere se avere uno scontro solo con più nemici/un nemico o più scontri in sequenza con più nemici/un nemico». Each fight starts from the HP/injuries/consumables/spells left by the previous one (after its corrections).
- **D-03:** The enemy list is **filtered by default** on the POI types of the place (+ habitat `city`, like the generator's zone pool) and on the **XP band of the mission's rank**; the **22 legendaries are available for worldMission** (they are reserved to the GM's missions); a toggle **«Mostra tutti»** shows the whole bestiary.

### Step 3 — Simulation
- **D-04:** The simulation runs the **backend combat engine** (today's placeholder, the user's engine later behind the same `CombatResolver`) with the characters' real state (equipment, companion, spells, consumables) and **writes nothing** on the characters. It returns per character: verdict, HP after, injuries added, consumables and spells used.
- **D-05:** On a simulated defeat the innkeeper can **re-run the simulation or change the enemies**, then correct by hand; the mission **always ends as completed** (today's rule: no reject, no failure, never an aid).

### Step 4 — Corrections
- **D-06:** Per character after each simulated fight: **remove the injuries in excess**, **set the life with a slider**, **correct consumables and spells used** reported by the engine; adding an injury stays possible (as in the Phase 10 form).

### Step 5 — Prizes
- **D-07:** Per character the list starts **prefilled with the rank block** of the character's title (FE/BE Phase 20: coins, xp, loot, pet, cure, spell by rank); the innkeeper removes entries or adds from the **catalogue filtered by the rank** (rarity ceiling of the rank's loot, pets with the same ceiling, spells only for ranks ≥ mage and with the required xp). Enemy xp, companion xp and the lore of a victory come from the chosen enemies as in any won fight (Phase 16/19 rules).

### Step 6 — Completion
- **D-08:** «Completa» sends the final corrected state of every character, the fights (enemies) and the prizes; the backend writes everything in one transaction (as `completePendingRequest` today) and the players get the usual result sheet with the enemies faced. Explicit confirmation with a recap, as in Phase 10 D-11.

### Draft and visibility
- **D-09:** The flow is a **draft saved on the backend** on the request (step reached, place, fights and enemies, simulation results, corrections, prizes): reopening the Locanda, also from another device, resumes it. The teleport is real as soon as it is done.
- **D-10:** Players see the teleport (their pawn moves), a **«Missione in corso» notice** and the final result; simulations, corrections and the draft stay invisible to them (user, 2026-11-12, overriding the first answer).
- **D-11:** From the moment the innkeeper **starts the flow** (draft created) until the **result arrives**, the participants are **locked**: no travel start and no quest acceptance (backend-enforced refusal with its own code, FE shows the notice and hides/disables the actions) — user: «Vorrei che avessero anche l'avviso "Missione in corso" e che fossero bloccati (così non rischio che inizino viaggi o quest mentre eseguo la loro quest) fino all'arrivo del risultato». The lock is released at completion or when the innkeeper discards the draft. **Shop purchases and sales, equipment and companion changes, spell equip and potions are locked too** (they change the state the simulation uses; user, 2026-11-12: «Blocchiamo anche quelle azioni»).

### Claude's Discretion
- Wizard layout (stepper, pages, back navigation between steps), copy, loaders (explicit actions: allowed), how the fights list is edited, recap content.
- Whether a corrected fight must be re-simulated after changing the enemies (recommended: changing the enemies of a fight invalidates its simulation and the following ones).
- Wire shape of the draft and of the mutations (decided with the BE companion).

</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` §Phase 21
- `.planning/phases/10-admin-panel/10-CONTEXT.md` (incl. «Amended (UAT 2026-11-01)»), `BACKEND-NOTES.md`, `10-HUMAN-UAT.md` — queue, form, teleport mode
- `.planning/phases/20-rank-specific-prizes-for-group-quests/20-CONTEXT.md` — rank blocks (D-05/D-05a/D-05c)
- `.planning/phases/09-combat-result-sheet/` — result sheet, enemies faced
- `.planning/phases/16-*/`, `.planning/phases/17-unlockable-lore/`, `.planning/phases/19-model-review/` — victory knowledge, lore, companion xp
- BE: `src/quests/outcomes/gm-completion.service.ts`, `src/quests/outcomes/combat/combat-resolver.ts`, `placeholder-combat-resolver.ts`, `combat-context.ts`, `src/quests/generation/enemy-pool.ts` (`zonePoolOf`), `generation-rules.ts` (`RANK_XP_BANDS`), `teleportCharacter` (Phase 8), BE `.planning/phases/22-completamento-guidato-missioni/22-CONTEXT.md`
- `lib/screens/innkeeper/` (request completion screen, participant override section, injury chips, quantity stepper, recap dialog), Map teleport mode

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `participant_override_section.dart`, `injury_chips.dart`, `quantity_stepper.dart`, `completion_recap.dart`, `results_recap_dialog.dart` — controls of step 4 and the final recap.
- Map teleport mode (Phase 10 D-15..D-20, group pawn) — step 1, drop targets widened to inner POIs.
- Prize rows of the quest sheet (`quest_sheet_details.dart`) — rendering of the rank block in step 5.

### Established Patterns
- Utility route on the root Navigator with repositories handed by `.value` (Phase 10 D-04); failure classifiers per code; TDD; schema gate + device E2E after the BE merge.

### Integration Points
- `request_completion_route.dart` / `request_completion_screen.dart` become the wizard; the queue card «Completa» opens it (resuming the draft).

</code_context>

<specifics>
## Specific Ideas
- Today at DB: 0 story and 0 worldMission (2026-11-12) — the device UAT needs a hand-written worldMission with rank blocks (FE/BE Phase 20) and a story.
</specifics>

<deferred>
## Deferred Ideas
- None beyond the user's own turn-based engine (it plugs into the same `CombatResolver`).
</deferred>

---

*Phase: 21-innkeeper-mission-completion-flow*
*Context gathered: 2026-11-12*
