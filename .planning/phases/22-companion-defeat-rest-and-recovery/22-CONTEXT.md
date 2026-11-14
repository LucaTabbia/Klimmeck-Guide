# Phase 22: Companion Defeat, Rest and Recovery - Context

**Gathered:** 2026-11-14 (interactive discuss, joint with the BE Phase 23 «Sconfitta, riposo e recupero dei compagni»; this file is authoritative for both, same numbering D-01..D-21; D-22 is FE-only)
**Status:** Ready for planning — branch `feat/22-companion-defeat-rest-and-recovery` stacked on `feat/21-innkeeper-mission-completion` (FE PR #51 draft); BE branch `feat/23-sconfitta-riposo-recupero-compagni` stacked on `feat/mission-start-push` (BE PR #41). **No UI phase** (same rule as the previous phases: every visual Claude builds is provisional).
**Amended:** 2026-11-14 after the research and the user's answers (D-23..D-35; D-21 amended by D-31, the draft wire of `22-REPO-RULES.md` replaced by its last section)

<domain>
## Phase Boundary

The companions (pets) of a character can be defeated, rested, healed with potions and named. The backend owns every rule (defeat, recovery times, life regained, potion wait, travel recomputation, name validation); the app shows the state and drives the actions: companion life and countdowns in the Journal, potions given from the potion sheet, companion lines on the result sheet, ambush parchments while travelling, a companion life slider in the innkeeper's guided flow, the name prompt at acquisition and the rename from the Journal.

Scope added by the user during the discuss (2026-11-14): the **companion name** (D-18..D-21) and the **travel rules after an ambush** (D-13..D-16: residual road on foot, a push for every ambush, parchments shown mid-travel, redirection when the food no longer suffices).

Out of scope: the real combat engine and the floor engine of the dungeons (the user's own work; today's placeholder stays behind the same port), a companion portrait on the Profile, companion injuries (pets have life only), iOS.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- Roadmap rules of 2026-11-14 (user, verbatim in the BE roadmap): a defeated companion is unequipped at the end of the fight and can be equipped again only at full life; a hurt companion rests while unequipped and regains life in proportion to the time (example: 100 minutes from 1 to 100; put to rest at 20, after 20 minutes it has 40); potions on the companion work like the character's, wait included.
- Phase 21 D-11/D-12: the «Missione in corso» lock already covers equip/unequip of the companion and the potions.
- Phase 13 D-17: the «Compagno» slot is a dropdown of tappable parchments; never text rows opening a bottom sheet.
- Phase 18 D-17: every duration through `formatGameDuration`.
- The backend is the source of truth (rule 4); no blocking loading in session (rule 2); no app chrome (rule 1).

### Recovery times
- **D-01 (user: «Come risposta 1, ma tieni in considerazione anche la quantità di vita massima»):** each catalogue pet carries its own **full recovery time** at DB (time from the minimum to full life), like `recovery.time` of the potions. The orchestrator seeds a table computed from **rarity + `maxXp` + `maxLifePoints`** (44 pets today, from Falco common/100 hp/100 xp to Pegaso legendary/5900 hp/2350 xp), reviewed by the user on a file **before** the DB write; afterwards «la mano vince» (curated at DB, never hard-coded in the FE).
- **D-02 (user, «Stesso orologio»):** one clock. A defeated companion is a forced rest from the minimum: its wait is the full recovery time of the pet. The only difference from a hurt one: it cannot be equipped until it is at full life. Recovery is linear in time.
- **D-03 (user, verbatim: «il compagno non è mai a vita 0, il minimo è 1 (non può morire un pet)»):** the companion's life floor is **1**; a pet never dies. «Defeated» = it reached the floor in a fight. The roadmap wording «0 life» is superseded.
- **D-04 (user, «Ogni compagno non equipaggiato»):** «putting to rest» = taking it out of the slot. Every owned companion outside the slot recovers by itself; the equipped one never recovers with time. A hurt (not defeated) companion can be equipped again at any moment with the life it has reached.

### Potions on the companion
- **D-05 (user, «Un'attesa per ogni compagno»):** a potion given to a companion starts a wait **of that companion only** (the body that drank, lore «Il limite del corpo»); it does not block the character's potions nor the other companions', and the character's `potionRecoveryUntil` does not block the companions.
- **D-06 (user, «No, solo il tempo»):** a **defeated** companion refuses potions: the wait of the defeat is served in full.
- **D-07 (user):** targets = any owned companion below full life and not defeated, **equipped or resting**.
- **D-08 (user, «Dal foglio della pozione»):** the only entry point is the potion sheet of the Journal: «Bevi» for the character and, below, the companions that can receive it as tappable parchments («Dai a <nome>»); with no eligible companion the sheet is today's. The tap on a companion parchment stays equip/unequip.

### What the player sees
- **D-09 (user, «Testo con vita che sale dal vivo»):** the companion parchment in the Journal gains «Vita: 40 / 100» under the experience line; while it rests the **number rises live** on screen (interpolated by the app between the server's dates, as the pawn in travel) with «A riposo: in forze fra 1 h 20 min»; a defeated one shows «Sconfitto: torna fra 3 h», parchment faded and not tappable (pattern of the potions in recovery). Copy provisional.
- **D-10 (user):** the result sheet of a fight prints the companion's life when it took damage («Fenrir: 120 / 300 di vita») and the defeat line when it fell («Fenrir è stato sconfitto: riposa e tornerà fra 10 h»); nothing when unharmed. The xp line of Phase 19 stays.
- **D-11 (user):** one new push, only when a **defeated** companion is back to full life and can be equipped again (new category with its toggle in the settings); no push for the hurt ones that finish resting; the defeat itself is told by the result sheet (and by the ambush push, D-14).

### Fights in sequence, travel, innkeeper
- **D-12 (user):** in a dungeon a companion defeated on a floor is **out of the following floors**; the slot is emptied at the end of the mission.
- **D-13 (user, verbatim: «Resto del viaggio a piedi»):** when the equipped mount is defeated in an ambush the character wins, it leaves the slot at once and the **residual road from that point is recomputed on foot**: arrival date and food needed change (food depends on the duration: 1 power every 3 minutes). Supersedes «speed photographed at departure» for this case.
- **D-14 (user, verbatim: «mandiamo una notifica per segnalare che hai subito un'imboscata e che il pet è stato sconfitto. Mandiamo una notifica per ogni imboscata subita»; confirmed: every ambush, won or lost, with or without a companion):** a push for **every** ambush; when the companion falls the push says so. Supersedes Phase 16 «no extra push» (today only the defeat pushes).
- **D-15 (user, verbatim: «Quando apri l'app (e quindi la mappa) mostriamo il risultato dell'imboscata o delle imboscate subite, anche se sei ancora in viaggio»):** the ambush parchments (Phase 16 carousel) are shown at the opening of the Map for the ambushes not seen yet, **also mid-travel**; at the arrival only the ones still unseen. Supersedes Phase 16 «all reports at the arrival».
- **D-16 (user, verbatim: «Se il cibo non è più sufficiente per arrivare in vita alla meta impostata, allora il personaggio viene ridirezionato al villaggio/città/capitale più vicina»; confirmed):** after the recomputation of D-13, if with the food and life left the character would not arrive alive (same check as the departure), it is redirected to the nearest city by road, as after a defeat in an ambush; the quest it was travelling to follows the defeat rule (abandoned).
- **D-17 (user, «Proposta + correzione dell'oste»):** in the guided completion the simulation proposes each participant's companion life; the innkeeper corrects it with a slider next to the character's (minimum = defeated). At completion the same rules apply (defeated → out of the slot and resting).

### Companion name (added by the user during the discuss)
- **D-18 (user, verbatim: «Aggiungi a questa fase la possibilità di dare un nome all'animale quando lo acquisisci (comprato o ottenuto in una quest). Questo nome (se deciso e non skippato) sostituisce le diciture standard del pet. Se il pet è Worg invece di Dai a Worg -> Dai a "nome" e così via»):** when a companion is acquired (shop purchase or quest prize) the app asks for a name, skippable. A chosen name replaces the species in every standard wording.
- **D-19 (user, «Sì, dal Diario»):** the name can be given or changed later from the companion parchment in the Journal (this also covers the companions owned today).
- **D-20 (user):** sentences, buttons and pushes use the name alone («Dai a Fenrir», «Fenrir è stato sconfitto», «Fenrir è di nuovo in forze»); on the Journal parchment the name is the title and the species sits below, smaller («Worg»). Without a name everything reads the species as today.
- **D-21 (user):** the name follows the same rules as the character's name (length, allowed characters, the server-side content filter of the character creation); a refused name shows the notice and can be retried or skipped.

### Companion cards (added by the user at the end of the discuss)
- **D-22 (user, verbatim: «Rivedremo anche lo stile delle card pet nei menù, perché devono avere lo stesso stile delle altre (magie e quipaggiamenti) e al tocco prolungato aprire i dettagli (come equipaggiamenti e magie)»):** the companion cards in the menus (Journal list and slot, shop, prize lists) take the **same style as the spell and equipment cards**, and a **long press opens the details** as for equipment and spells (same gesture, same kind of sheet). The details sheet is the natural home of life, recovery, attack/defense and of the rename of D-19; the tap stays equip/unequip.

### Added after the research (2026-11-14) — rulings of the orchestrator and answers of the user

Evidence in `22-RESEARCH.md` (FE) and BE `23-RESEARCH.md`. Where these and the decisions above disagree, these win.

- **D-23 (research, both sides):** a companion is identified by the **catalogue pet id** everywhere (`equipPet`, `useItem`, `renamePet`); one owned entry per species is a BE invariant (purchase of an owned species refused, duplicate prize skipped). No owned-entry id on the wire.
- **D-24 (research):** the resting life is computed at read from a stored anchor (`currentLifePoints` at `lifeAsOf`), linear, speed `(max − 1) / T` rounded to the nearest point (the user's example gives 40; a defeated one is back exactly after `T`). `defeated` is resolved at read (true only while `fullLifeAt` is in the future) and `equipPet` is judged on the same rule; `characterUpdated` is published when a defeated companion recovers (sweeper, up to 60 s late: accepted, as for the prison).
- **D-25 (research):** `Pet.recoveryTime` is a nullable `Int` in milliseconds; a pet not curated yet recovers at once (BE warning at boot). The table of the 44 pets (formula `base(rarity) × √(hp/100) × (1 + xp/2000)`, bases 20/30/40/50/60 minutes, from 10 min to 17 h 55 min) is in `~/Downloads/klimmeck-tempi-recupero-compagni.md` for the user's review; the orchestrator writes it to the DB before the device UAT.
- **D-26 (research, technical default):** a companion that ends a fight at 1 is defeated, also when it entered at 1. D-12 extends to the fights in sequence of a guided mission.
- **D-27 (research):** `QuestResult.companion` is served **whenever a companion fought** (name shown, life before and after, max, defeated, full-life date); the sheet prints the life line only when the life dropped, the defeat line when defeated, and names the xp line. The defeat duration on the sheet is `fullLifeAt − resolvedAt` (a dated record, no ticker).
- **D-28 (research):** an ambush report is a `QuestResult` written at the ambush instant (today it is held until the arrival); «unseen» = not acknowledged. No new wire for D-15; the app already opens result sheets mid-travel. `AmbushReport.onFoot` says the rest of the road is on foot and the parchment prints «Prosegui a piedi» (orchestrator's default, the user can veto).
- **D-29 (research):** the recomputed travel is written like today's defeat detour (road from the ambush point, start = ambush instant), so the pawn never jumps back; on a redirection after a won ambush `reachedCity` is filled. The mount is the companion equipped at departure (BE internal field); travels in flight at the deploy are not recomputed.
- **D-30 (user, 2026-11-14, «Una categoria «Imboscate»»):** one push category for every ambush, won or lost: wire type `ambush`; `ambushDefeat` stays in the enum but is no longer sent. The existing toggle is relabelled «Imboscate» and keeps its stored choice; the app accepts both wire types. Push id = result id: the banner is suppressed when the carousel opens live.
- **D-31 (user, «Solo regole di forma»; amends D-21):** the character name has no content filter today, only form rules (2–20 characters: letters, spaces, apostrophes, hyphens). The companion name follows the same form rules, no word filter. Refusal code `PET_NAME_INVALID`. The rename is not locked by «Missione in corso»; clearing a name is not offered in this phase.
- **D-32 (research):** potion on a companion: full life → `ITEM_NO_EFFECT` (today's code), companion wait → `PET_POTION_RECOVERING` with `extensions.recoveryUntil`, defeated → `PET_DEFEATED`; the result carries the target's values. The potion row of the Journal is tappable when the character **or** a companion can drink («Bevi» disabled inside during the character's wait — amends the Phase 18 D-12 row for this case); a companion in its own wait is not listed in the sheet (its wait shows on its parchment and details).
- **D-33 (research):** guided flow wire: `MissionFightOutcome.companion` (`MissionCompanion`: pet, name, life before, max), `MissionFightEffects.companionLifeAfter` (simulated and corrected), correction `ParticipantOverrideInput.companionLifeAfter` (1..max, 1 = defeated).
- **D-34 (user, «Sì, con l'immagine»; amends Phase 13 D-13):** the companion cards and the details sheet show the pet image (`Pet.imagePath`, all 44 pets have one).
- **D-35 (user, «Foglio della quest + liste dell'oste»):** the card with the long press goes in the Journal, the shop (list and basket), the prize of the quest sheet and the innkeeper's prize rows; the result sheet keeps its text line.

### Companion levels (added by the user on 2026-11-14, during the execution)

- **D-37 (user, verbatim: «Essendo che anche i pet scalano di xp, è necessario avere una progressione come quella del personaggio, dove al raggiungimento di determinate soglie, si aumenta la vita massima. Utilizza la vita massima già presente come punto di partenza, poi da far scalare a crescere»; answers: «10 livelli sul proprio tetto», «Fino al doppio»):** a companion has **10 levels** on thresholds of its **own xp cap** (`Pet.maxXp`), with the same rising curve as the character (early levels come soon, the last ones cost more); level 10 = cap reached. Its **max life** starts from the catalogue `maxLifePoints` (level 1) and grows up to **twice** that at level 10 (Falco 100 → 200, Pegaso 5900 → 11800).
- **D-38 (orchestrator, technical defaults — the user can veto):** the BE computes level and max life (one pure rule; thresholds `maxXp × t(i)/45` and life `base × (1 + t(i)/45)` with `t(i) = i(i−1)/2`, i = 1..10, rounded); wire `OwnedPet.level: Int!` and `OwnedPet.maxLifePoints: Int!` (the companion's own max; `Pet.maxLifePoints` stays the base of the species). Every rule of this phase that reads the companion's max (rest, floor-to-full time, potions, result sheet, innkeeper slider) reads the **owned** max. The recovery time `T` stays one per pet (from the floor to the current max). At a level-up the current life does not change (as for the character); a companion resting at full life stays full. The app shows «Livello N» in the details sheet and next to the species on the Journal parchment, and «Vita: x / max» with the owned max; it never computes a level or a max (pre-gate fallback: the species' max, level hidden).

### Claude's Discretion (technical defaults, to be declared in the plans)
- Wire shape, decided with the BE in the plan: fields on `OwnedPet` (name, defeated marker, the dates the FE interpolates from, the potion wait date), the recovery time on `Pet`, the target of `useItem`, the companion entries of `QuestResult` / ambush report / mission draft, codes of the refusals (defeated companion equipped, potion on a defeated or full companion, companion potion wait, name refused).
- How the BE computes the resting life (lazy at read/write vs sweep) and schedules the «in forze» push.
- The gesture that opens the rename on the parchment (the tap stays equip/unequip), the place of the name prompt in the shop and on the result sheet (several prize companions = one prompt each), final copy.
- Selling a resting or defeated companion stays allowed as today.
- Pattern of the previous pairs: pre-gate plans on mocks, schema gate on the merged BE SDL, device E2E last; `22-REPO-RULES.md` before research and planner; `BACKEND-NOTES.md` kept in this directory.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Rules and planning
- `.planning/ROADMAP.md` §Phase 22 — goal, dependencies
- `docs/rules/ui-ux.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/testing.md`, `docs/rules/workflow.md`
- `../Klimmeck-Guide-BE/.planning/ROADMAP.md` §Phase 23 — the user's rules verbatim
- `../Klimmeck-Guide-BE/.planning/phases/23-sconfitta-riposo-recupero-compagni/23-CONTEXT.md` — BE side of this discuss

### Prior decisions this phase builds on or supersedes
- `.planning/phases/13-city-shops/13-CONTEXT.md` — D-08 (buying never equips), D-10, D-17 (companion dropdown)
- `.planning/phases/16-travel-ambushes/16-CONTEXT.md` — carousel and pushes of the ambushes (superseded in part by D-14/D-15)
- `.planning/phases/18-heal-quests-by-size/18-CONTEXT.md` — D-11..D-17 (potion sheet, countdown, `useItem`, `formatGameDuration`)
- `.planning/phases/19-model-review/19-CONTEXT.md` — D-03 (`ownedPets { pet, xp, currentLifePoints }`), companion xp
- `.planning/phases/21-innkeeper-mission-completion-flow/21-CONTEXT.md` — D-04, D-11/D-12 (lock), D-20, corrections step
- BE `src/travel/food/travel-food.ts` (food by duration, `arrivesAlive`), `src/travel/ambush/`, `src/travel/travel-planner.service.ts` (pet speed), `src/characters/items/item-use.plan.ts`, `src/characters/pets/`, `src/quests/outcomes/combat/combat-context.ts`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/models/owned_pet.dart`, `lib/models/pet.dart` (`maxLifePoints`), `lib/graphql/fragments/character_fragment.dart` — `currentLifePoints` already on the wire, never shown
- `lib/screens/mainScreen/tabs/journal/sections/companion_section.dart`, `components/owned_companion_row.dart`, `components/companion_content.dart`, `shared/components/cards/companion_card.dart`, `utils/item_lines.dart` (`companionXpLine`)
- `lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart`, `sections/items_section.dart`, `lib/repository/item_use_repository.dart` / `item_use_failure.dart`, `pet_equip_failure.dart`
- `lib/shared/components/popup/ambush_report_carousel.dart`, `quest_result_sheet.dart`, `screens/mainScreen/questResultsCubit/`, `components/quest_result_presenter.dart`
- `lib/models/notification_category.dart`, settings `notification_preferences_section.dart`, `notification_popup_registry.dart`
- Spell and equipment cards with their long-press details sheets (the style and gesture D-22 copies)
- `TravelProgressCubit` (interpolation between server dates) as the pattern for the live life; character name input and its failures (character creation) for the companion name

### Established Patterns
- Disabled faded parchment with a countdown from a server date (potions, Phase 18 D-12)
- Failure classifier per action with `BAD_USER_INPUT` and `MISSION_IN_PROGRESS` mapped
- Schema registry (`schemaCheckDocuments`, 54 today) and count tests

### Integration Points
- Journal companion rows and potion sheet; shop buy flow (name prompt); result sheet and ambush carousel; Map opening (unseen ambushes mid-travel, travel recomputed by the stream); innkeeper corrections step (companion slider); push categories

</code_context>

<specifics>
## Specific Ideas

- User's example of the rest: 100 minutes from 1 to 100; at rest from 20 for 20 minutes → 40.
- «Dai a Worg» → «Dai a "nome"» once named.
- Travel answer in full: «Resto del viaggio a piedi, mandiamo una notifica per segnalare che hai subito un'imboscata e che il pet è stato sconfitto. Mandiamo una notifica per ogni imboscata subita. Quando apri l'app (e quindi la mappa) mostriamo il risultato dell'imboscata o delle imboscate subite, anche se sei ancora in viaggio. Se il cibo non è più sufficiente per arrivare in vita alla meta impostata, allora il personaggio viene ridirezionato al villaggio/città/capitale più vicina».

</specifics>

<deferred>
## Deferred Ideas

- Companion portrait on the Profile tab (Phase 13 deferred, still deferred).
- Push for a hurt companion that finishes resting (declined, D-11).

</deferred>

---

*Phase: 22-companion-defeat-rest-and-recovery*
*Context gathered: 2026-11-14*
