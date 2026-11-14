# Phase 21: Innkeeper Mission Completion Flow - Context

**Gathered:** 2026-11-12
**Status:** Ready for planning — BE companion: **BE Phase 22 «Completamento guidato delle missioni»** (BE-GMFLOW-01..07, branch `feat/22-completamento-guidato-missioni`); depends on FE Phase 20 / BE Phase 21 (rank blocks)
**Amended:** 2026-11-14 after `21-RESEARCH.md`, the BE `22-RESEARCH.md` and the user's answers (D-13..D-30; D-01, D-03, D-06, D-07, D-10 and D-12 are revised by the new decisions: where they differ the new ones win)

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

### Same lock for every mission (added 2026-11-12)
- **D-12:** Gap found in the discuss: in normal missions the BE reads the character **only at resolution** (`resolution-loader.service.ts:382`), and `equipItem`/`equipPet`/`equipSpell`, `useItem` (refused only while awaiting aid) and the shop (only «in the city») have no guard on a mission in progress — a player can swap to a better weapon or drink a potion one minute before the fight. User's choice (option 1 of 2, snapshot at start rejected): **reuse the D-11 lock for every mission**: from the **effective start** (standard lane: arrival at the quest, i.e. the waiting time; boss/registered quests: party started) **until the result**, no equipment/companion/spell changes, no spell use outside combat, no potions, no shop, with the same «Missione in corso» notice; travel and quest acceptance are already blocked by the occupied lane. One backend rule and one FE notice for both the guided flow and the normal missions.

### Added after the research (2026-11-14)

Same numbering as the BE `22-CONTEXT.md` (D-13..D-27 shared, D-28..D-30 FE only). File:line evidence in `21-RESEARCH.md`; the wire is the BE `22-RESEARCH.md` §Q9 plus D-16/D-17.

**User's answers (2026-11-14, AskUserQuestion):**
- **D-13 (revises D-12, conflict C-3):** «travel and quest acceptance are already blocked by the occupied lane» is false for story and worldMission (separate lanes, `quest_lane.dart:5-11`). User: «Sì, blocca tutto» — while a mission is in progress **every acceptance or registration is blocked** (`QuestAvailability` blocked line for every quest type; BE refusal `MISSION_IN_PROGRESS`).
- **D-14 (refines D-06, C-2):** user: «Solo quelle della missione» — the innkeeper removes only the injuries **added in this mission** (by the engine or by hand); the injuries the character already had (`injuriesBefore`, served) are shown and not removable. On the wire `corrections[].injuries` is the full list of injuries the fight adds after the correction.
- **D-15 (refines D-07, against the recommendation):** user: «Liberi, senza tetto» — **coins and xp of the prizes are free numbers** (integers ≥ 0, no ceiling tied to the block): numeric inputs prefilled with the block's values. Items, pets and spells still come only from the served catalogue (the BE revalidates); item quantity `1..99`.
- **D-16 (refines D-10):** user: «Pedina solo per la guidata» — the pawn label «Missione in corso» shows **only during the innkeeper's guided flow** (`CharacterStatus.guidedMissionInProgress`); the disabled Journal actions and the Board line show in **every** mission in progress (`CharacterStatus.missionInProgress`, true for guided and normal missions). The FE reads the two served booleans and never derives one from lanes.

**Orchestrator rulings on the research (recommendations accepted; the user may overturn them before the execution):**
- **D-17 (wire):** BE `22-RESEARCH.md` §Q9 verbatim plus `CharacterStatus.guidedMissionInProgress: Boolean!` and, on `MissionFightOutcome`, `consumablesAvailable: [MissionItemUsage!]!`, `injuriesBefore: [InjuryType!]!`, `spellsAvailable: [MissionSpellUsage!]!` (the bounds at the start of each fight are served, never computed). Additions accepted: query `missionDraft(pendingQuestId)`, `PendingRequest.missionDraftStartedAt` (the card reads «Riprendi» when set), `MissionPrizeOptions`.
- **D-18 (draft):** one draft per request (story) or per group of requests of the same worldMission, reached by any entry id of the card; last write wins (no version field); steps `teleport` / `fights` / `prizes` / `recap` saved by the wizard, order not enforced by the BE.
- **D-19 (enemies):** legendaries are offered for worldMission when they live in the zone, with no XP band filter; mixed worldMission band = union of the seats' bands; the list arrives sorted.
- **D-20 / D-21:** the companion enters the BE combat context (no FE effect); the verdict is one per fight (`MissionFight.verdict`), shown on the fight, not per character.
- **D-22 (prizes):** the BE prefills `MissionDraft.prizes` at the start with the whole rank block of each participant (the whole `randomLoot` pool and the pet included; the innkeeper removes); the FE never builds a prize list from `MissionPrizeOptions.block`.
- **D-23 (lock borders):** a wounded character awaiting aid is NOT «mission in progress»; the travel preview is refused too; the existing codes keep their precedence and their copy; the teleport of a participant stays allowed; the lock arrives live through `characterUpdated`.
- **D-24 (fights):** zero fights allowed (narrative story: prizes only); fight k cannot be simulated before fight k-1; changing the enemies of fight k voids simulation and corrections of k and the following ones (shown from the served draft: «Da simulare»).
- **D-25 (completion):** `completeGuidedMission(pendingQuestId)`; `completePendingRequest` stays alive on the BE until this phase is merged; the Phase 10 form is retired in the gated plan.
- **D-26 / D-27:** BE only (audit of the mutations; orphan PendingQuests of archived characters out of scope).
- **D-28 (wizard, C-5, C-6, F-3):** new files under `lib/screens/innkeeper/missionCompletion/`; the Phase 10 form keeps working until the gated plan wires «Completa» to the wizard and deletes it RED-first; an explicit **«Inizia la missione»** page creates the draft (no draft on open); after the Map round trip the landing reopens the panel **and the wizard of that card** (`TeleportModeCubit.resumeCardKey`), rebuilt from the served draft.
- **D-29 (inner POIs, C-4, PQ6, PQ7, LB-2):** one new document `ListPointsOfInterest`, a POI layer shown only in teleport mode, a drop rule the teleport pawn overrides (player travel unchanged); a place is named by its type label plus the nearby city («Rovine presso Talmvere»), with the Italian labels of every `PoiType` proposed in the plan (the user reviews the list at the UAT) and `demonicPortal` added to the enum; the card-level «Teletrasporta» stays.
- **D-30 (players' side, C-1, C-7, LB-1, Pitfall 2):** prize lists are built from the existing blocks (`CoinsDisplay`, `ItemRow`, item cards, `CompanionRow`, `SpellRow`), not extracted from the gameplay sheet; a small equipment repository + failure classifier makes an `equipItem` refusal visible (today silent, `journal_cubit.dart:29-36`); the two status booleans are modelled pre-gate (lenient, default `false`) and **selected in `CharacterFragment` only in the gated plan**. Copy (final unless the user amends it): pawn «Missione in corso»; Journal row status «Missione in corso»; Board line «Missione in corso: aspetta l'esito»; refusal banner description «Sei impegnato in una missione: aspetta l'esito» (titles per action as today); wizard copy as `21-RESEARCH.md` Open Question 8.

**Rulings after the plan check (2026-11-14):**
- **D-31:** the D-14 lock is **per fight** (same rule in the BE: an injury added by fight k-1 is removed by correcting fight k-1, which voids the following fights); `QuestAvailability.missionInProgress` comes AFTER the existing reasons (BE precedence of D-23); a failed inner-places read never blocks the city teleport; BE caps mirrored as UI bounds in one file (10 fights, 10 enemy entries per fight, enemy quantity 1..20; prize item quantity 1..99); the BE also refuses `questTravelPreview` with `MISSION_IN_PROGRESS`; the wizard always sends the full corrections list of a fight with `hpAfter` for every participant; the gate is split: 21-16 gate and wiring, 21-17 Phase 10 form retired, 21-18 device E2E.

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
