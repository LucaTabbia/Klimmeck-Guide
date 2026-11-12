# Phase 20: Rank-Specific Prizes for Group Quests - Context

**Gathered:** 2026-11-12
**Status:** Ready for planning — BE companion: **BE Phase 21 «Premi per rango e soccorsi»** (BE-RANKP-01..06, branch `feat/21-premi-per-rango-e-soccorsi`)

<domain>
## Phase Boundary

Group quests reward every participant with a prize block suited to **their own rank**; solo quests keep one prize computed on the minimum rank. The backend owns the blocks (generation, storage, resolution per participant); the app shows each viewer only the block of their own rank on the quest sheet, and the result sheet keeps showing what was actually awarded. The phase also fixes the aid (rescue) flow found during the discuss: aid only from the listed quest types, the dungeon aid that walks the turns up to the one (exploration or fight) where the rescued character fell, prizes of a dungeon aid in proportion to the turns completed, and the lane release when the archiver concludes an aid. Phase 21 (innkeeper mission completion) reuses the rank blocks for its prize step.

</domain>

<decisions>
## Implementation Decisions

### Which quests carry rank blocks
- **D-01:** Rank blocks belong to **group quests**: `worldMission`, `boss` (including the new mixed-rank bosses, D-03) and the `aid` cloned from a group quest. Solo quests (`enemy`, `hunt`, `dungeon`, the aid of a solo quest, and the other unregistered types) keep **one prize computed on the minimum rank to accept the quest** (`requirements.minTitle`) — user: «nel caso delle missioni in solitaria il premio è calcolato sul rango minimo per accettare la quest (riflette anche la difficoltà del mostro, rendendo il tutto più bilanciato)».
- **D-02:** Group quests have **no «any rank» seats**: every seat names a title and a block exists for every title among the seats — user: «Le quest di gruppo hanno i blocchi di rango, senza posizioni libere a qualsiasi rango». A group quest with a seat whose `title` is null is invalid content (planner: decide refuse vs. report, as for the shop rule violations).
- **D-03:** The generator creates **mixed-rank bosses at random, not by a fixed rule**: a boss may include seats of the **rank below** its own, **never the rank above** («diventerebbe troppo facile»). Proportion and frequency are Claude's discretion within the existing seat formula (⌈PE / rank mean⌉, 2–6 seats).

### Which rank decides the prize
- **D-04:** The participant's **own character title** at resolution decides the block, wherever they sit (a mage in a mage seat gets the mage block; the seat title only gates acceptance).

### Content of a block
- **D-05:** **Everything in a block goes by rank**: coins and xp (generator tables × the rank multiplier: rookie 1, adventurer 2, paladin 5, mage 12, hero 25; legend as in the existing pools), loot (the rank's rarity pool, `LOOT_POOLS`), **pet, cure and spell too** — so nobody gets a pet, a cure or a spell too strong for their rank (user, 2026-11-12, correcting the first answer: «anche quelle vanno in base al rango. Così non rischiamo che qualcuno ottenga un pet troppo forte/ una cura troppo forte / una magia troppo forte per il suo livello/rango»).
- **D-05a:** The **pet is drawn with the usual rule** (BE Phase 19 D-28: one roll with summed bands — 10 % pet of the same enemy, 5 % zone pet, 5 % (boss only) any non-sellable pet; rarity ceiling from the rank's loot; legendary only from hero bosses) **once per rank block**: the mage block may carry a pet while the paladin block does not. Today's generator gives at most one pet per quest; with blocks, at most one per block.
- **D-05c:** Cures and spells in practice appear **only in the dedicated solo types** — `heal` for cures, `magic` (and the Valantar `study`) for spells — so generated group quests carry none; the per-rank fields still exist for hand-written group quests. A spell can be learnt **only by ranks ≥ mage** (no block below mage carries a spell).
- **D-05b:** Gap found in the BE: `canLearnSpell`/`drawLearnableSpell` (`src/quests/outcomes/rewards/quest-rewards.ts`) gate only on `minXpToLearn`, while the rank rule lives in `isSpellCaster` (`src/models/character/active-spell-slots.ts`, used only for the slots). The BE must refuse to teach a spell to a non-caster in every path (solo quests and the Valantar study included), pinned RED-first.
- **D-06:** Blocks come **from the tables, then hand-editable at DB** for generated quests («la mano vince»). For a **hand-written quest** (worldMission, story, anything written at DB) the user writes the rank blocks himself: no seeding, no table fallback — user: «Se dovessi scrivere una quest a mano, allora deciderei io i premi per rango».

### What the app shows
- **D-07:** The quest sheet shows the viewer **only the block of their own rank** (same rows as today: coins, xp, item/loot, pet line, spell, cure). The innkeeper's view of all blocks belongs to Phase 21 (prize step).
- **D-08:** The result sheet is unchanged in shape: it already shows the rewards actually awarded per participant (`QuestResult.rewards`).

### Aid flow (fixes folded into this phase, user request in the discuss)
- **D-09:** An aid is created on defeat **only** for `enemy`, `boss`, `hunt`, `dungeon` and `aid` quests (today any lost fight creates one, also heal/job/study/magic/crime with enemies).
- **D-09b:** `crime` already behaves as the user remembers from the UAT: its «defeat» is the 20% arrest at conclusion (quick 261110-cgd: no prize, 10 h prison `CRIME_PRISON_MS`, a quarter of the coins, **no aid**); the lost guard encounter leaves the character at minimum HP, no aid. No crime at DB has enemies (34/34), so a crime lost in combat does not happen today; with D-09 it would create no aid either. No change to crime.
- **D-10:** A lost rescue keeps **today's rule** (BE Phase 9 D-09, confirmed by the user): the original wounded die, one new aid for the fallen rescuers cloned from the original quest, timer restarted.
- **D-11:** The aid of a group quest clones its **rank blocks** with the seats (same characteristics as the failed quest; the cure is still not inherited, BE Phase 18 D-23).
- **D-12:** **Dungeon aid by turns.** A dungeon is a sequence of turns «exploration → fight vs first enemy/group → exploration → fight vs second enemy/group → … until the enemies end». A character can be defeated **in any turn, exploration included, not only in a fight** (user, 2026-11-12). On defeat the backend **saves the turn where the character fell** (index and kind: exploration or fight); the dungeon aid walks the same sequence **up to that turn** and the rescuer must **complete it** (pass the exploration or win the fight) to save the wounded; then the aid ends. User: «se il personaggio viene sconfitto nel secondo scontro, il soccorritore dovrà arrivare fino al secondo scontro e poi completarlo, per poter salvare il personaggio. Dopodiché la quest aid finisce e la quest dungeon torna disponibile».
- **D-13:** The turn-based dungeon engine (exploration and combat turns) is the user's own work: this phase builds **the structure + the current placeholder** (saved turn on the aid, turn walk through the same dungeon door, turn counters in the result) so his engine plugs in without touching the flow; the door must already allow a defeat in an exploration turn.
- **D-14:** The rescuer of a dungeon aid gets the dungeon's prizes **in proportion to the turns completed** out of the dungeon's total (e.g. fell in the 4th of 8 turns → half of coins, xp and loot; exact unit — turns vs fights — and rounding are Claude's discretion, documented; recommended: turns, since a defeat can happen in exploration).
- **D-15:** «The dungeon returns available» means **for the rescued character** (freed from awaiting aid); no lock of the dungeon for others while the aid is open (today's behaviour).
- **D-16:** When the archiver concludes an aid whose rescuers had registered but not started, it **releases their lanes and PendingQuests** like the timeout does (inferred from code, not reproduced: pin it with a test first).

### DB cleanup (done in the discuss, 2026-11-12)
- **D-17:** The 3 concluded aid quests at DB were UAT leftovers (each born from a real defeat, closed by hand at DB, no `QuestResult` on them, not on the board): backed up to EJSON in the session scratchpad (`aid-cleanup-backup-2026-11-12.json`) and deleted on the user's order. 0 aid quests remain; nothing referenced them.

### Claude's Discretion
- Wire shape of the per-viewer prize (recommended: the BE resolves `Quest.prizes` for the viewer's rank, like `noEffect`, so the FE sheet keeps reading one block; plus a list of blocks for the innkeeper in Phase 21) — decided with the BE companion.
- Frequency and mix of the lower-rank seats in mixed bosses (D-03).
- Unit and rounding of the proportional dungeon-aid prize (D-14).
- Field names (`rankPrizes`/`prizesByRank`, saved turn on `rescue`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and phase
- `.planning/ROADMAP.md` §Phase 20, §Phase 21 — goal and the dependency of Phase 21 on the rank blocks
- `.planning/PROJECT.md`, `.planning/STATE.md`
- `.planning/phases/06-quest-accept-info-sheets/` — per-type quest sheets (prize rows)
- `.planning/phases/09-combat-result-sheet/09-CONTEXT.md` — aid rules D-08/D-09/D-10, result sheet; `BACKEND-NOTES.md`
- `.planning/phases/14-quest-generation/14-CONTEXT.md` and `BACKEND-NOTES.md` — generated boss/enemy, pools by rank, dungeon stages line («Ho superato N tappe di M»); `14-HUMAN-UAT.md:41-42` (dungeon aid closed by hand)
- `.planning/phases/18-heal-quests-by-size/` — `prizes.cure` (not inherited by the aid)
- `.planning/phases/19-model-review/BACKEND-NOTES.md` — pet in prize (D-28), cleaned models

### Backend (separate repo `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`)
- `src/models/quest/quest-prizes.model.ts` — today's single `QuestPrizes`
- `src/quests/outcomes/rewards/quest-rewards.ts` — `drawRewards` (per-winner loot roll)
- `src/quests/generation/generated-prizes.ts`, `loot-pools.ts`, `pet-prize.ts` — tables, multipliers, rarity pools
- `src/quests/acceptance/quest-capacity.ts`, `quest-eligibility.ts` — seats, `TITLE_RANK`, registered types
- `src/quests/outcomes/aid/aid-quest.ts` — aid clone; `combatant-plan.ts:127-136` (aid on any failure); `rescue-resolution.service.ts:395-479` (rescue fight, lost rescue); `quest-resolution.service.ts:183` (dungeon staged path); `character-archiver.ts:221-247` (aid concluded without lane release); `party-timeout.service.ts:137-155`
- `.planning/phases/09-*/09-CONTEXT.md` (BE) — D-08/D-09 aid

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- FE `lib/models/quest/quest_sheet_details.dart`: builds the prize rows of the sheet from `quest.prizes` (pet line «Compagno in premio: …»); keeps working if the BE resolves the viewer's block into `prizes`.
- BE `prizesOf` (generated-prizes) already computes coins/xp/loot for one rank: call it once per admitted rank.
- BE dungeon door with stage counters (`stagesCleared`/`stagesTotal` on `QuestResult`) — reuse for the aid walk.

### Established Patterns
- Per-viewer fields resolved by the BE (`Quest.noEffect`, Phase 18) — same pattern for the viewer's prize block.
- Non-additive SDL changes → FE plans gated on the BE merge, schema gate + device E2E (Phases 14, 19).
- «La mano vince»: rules seed, hand edits at DB win, read-only report of violations (shops, BE 12).

### Integration Points
- Quest fragment/selections in `lib/graphql/` for `prizes`; quest sheet rows; result sheet stage line for the dungeon aid.
- Phase 21 prize step reads the rank blocks.

</code_context>

<specifics>
## Specific Ideas

- Dungeon rhythm (user, verbatim intent): exploration → fight 1 → exploration → fight 2 → … ; a defeat can happen in an exploration turn too; the rescuer must reach and complete the turn where the wounded fell.
- DB snapshot 2026-11-12: 0 story, 0 worldMission, 12 bosses (5 paladin, 5 mage, 2 hero, single-rank seats), 40 dungeons without seats, 0 aid after the cleanup.

</specifics>

<deferred>
## Deferred Ideas

- The turn-based dungeon combat/exploration engine — the user writes it himself (D-13 only prepares the structure).
- Innkeeper's view and choice of prizes per character — Phase 21.

### Backend companion
- Opened on 2026-11-12 as **BE Phase 21 «Premi per rango e soccorsi»** (`Klimmeck-Guide-BE/.planning/phases/21-premi-per-rango-e-soccorsi/21-CONTEXT.md`, same decisions, BE-RANKP-01..06). FE plans that read the new wire shape are gated on its merge.

</deferred>

---

*Phase: 20-rank-specific-prizes-for-group-quests*
*Context gathered: 2026-11-12*
