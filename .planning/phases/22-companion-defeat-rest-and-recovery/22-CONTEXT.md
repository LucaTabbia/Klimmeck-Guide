# Phase 22: Companion Defeat, Rest and Recovery - Context

**Gathered:** 2026-11-14 (interactive discuss, joint with the BE Phase 23 «Sconfitta, riposo e recupero dei compagni»; this file is authoritative for both, same numbering D-01..D-21; D-22 is FE-only)
**Status:** Ready for planning — branch `feat/22-companion-defeat-rest-and-recovery` stacked on `feat/21-innkeeper-mission-completion` (FE PR #51 draft); BE branch `feat/23-sconfitta-riposo-recupero-compagni` stacked on `feat/mission-start-push` (BE PR #41). **No UI phase** (same rule as the previous phases: every visual Claude builds is provisional).

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
