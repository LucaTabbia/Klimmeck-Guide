# Phase 22: Companion Defeat, Rest and Recovery - Research

**Researched:** 2026-11-14
**Domain:** Flutter gameplay surfaces over a backend-owned companion state (BE Phase 23 «Sconfitta, riposo e recupero dei compagni»): Journal companion parchments with live rising life, potions given to companions, companion name, restyled companion cards with a long-press details sheet, companion lines on the result sheet and the ambush carousel shown mid-travel, two push categories, a companion slider in the innkeeper's corrections
**Confidence:** HIGH for code facts (file:line read this session on `feat/22-companion-defeat-rest-and-recovery` at `d0cf72f4`; 68 candidate files checked formatter-clean one by one with `dart format --output=none --set-exit-if-changed`: only `lib/shared/components/popup/equipment_info_display.dart` is not clean; one throw-away probe + the existing travel reroute tests run: `+38: All tests passed!`, probe deleted, `git status --short` empty afterwards); MEDIUM for the wire (BE research in progress: every new name below is the orchestrator's DRAFT from `22-REPO-RULES.md`, **BE to confirm**; BE SDL read with `git -C <BE> show origin/develop:src/schema.gql`, BE `origin/develop` = `2c462cbe`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `22-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **Carried forward:** defeated companion unequipped at the end of the fight, equippable again only at full life; a hurt companion rests while unequipped and regains life in proportion to time (100 min from 1 to 100; at rest from 20 for 20 min → 40); potions on the companion work like the character's, wait included. Phase 21 D-11/D-12 lock covers companion equip/unequip and potions. Phase 13 D-17 dropdown of tappable parchments. Phase 18 D-17 `formatGameDuration`. Rules 1, 2, 4.
- **D-01** Each catalogue pet carries its own full recovery time at DB (seeded from rarity + `maxXp` + `maxLifePoints`, reviewed by the user, then curated at DB; never hard-coded in the FE).
- **D-02** One clock: a defeated companion is a forced rest from the minimum; not equippable until full life; linear recovery.
- **D-03** Life floor is **1**; a pet never dies; «defeated» = reached the floor in a fight.
- **D-04** Every owned companion outside the slot recovers by itself; the equipped one never recovers with time; a hurt (not defeated) one can be equipped at any moment.
- **D-05** A potion given to a companion starts a wait of that companion only; the character's `potionRecoveryUntil` does not block the companions.
- **D-06** A defeated companion refuses potions.
- **D-07** Targets = any owned companion below full life and not defeated, equipped or resting.
- **D-08** Only entry point = the potion sheet of the Journal: «Bevi» + below the eligible companions as tappable parchments («Dai a <nome>»); no eligible companion → today's sheet; the tap on a companion parchment stays equip/unequip.
- **D-09** Journal parchment: «Vita: 40 / 100» under the experience line; while resting the number rises live (interpolated between the server's dates) with «A riposo: in forze fra 1 h 20 min»; defeated: «Sconfitto: torna fra 3 h», faded, not tappable. Copy provisional.
- **D-10** Result sheet: «Fenrir: 120 / 300 di vita» when damaged, «Fenrir è stato sconfitto: riposa e tornerà fra 10 h» when fallen, nothing when unharmed; Phase 19 xp line stays.
- **D-11** One new push only when a **defeated** companion is back to full life (new category + settings toggle); none for hurt ones.
- **D-12** Dungeon: a companion defeated on a floor is out of the following floors; slot emptied at the end of the mission.
- **D-13** Mount defeated in a won ambush → leaves the slot at once, residual road recomputed on foot (arrival and food change).
- **D-14** A push for **every** ambush (won or lost, with or without a companion); it says when the companion fell.
- **D-15** Ambush parchments shown at the Map opening for the unseen ambushes, also mid-travel; at the arrival only the unseen ones.
- **D-16** After D-13, if the character would not arrive alive, redirect to the nearest city by road; the quest follows the defeat rule.
- **D-17** Innkeeper guided completion: simulation proposes each participant's companion life; the innkeeper corrects it with a slider next to the character's (minimum = defeated).
- **D-18** Name asked at acquisition (shop or quest prize), skippable; a chosen name replaces the species in every standard wording.
- **D-19** Name given or changed later from the Journal parchment.
- **D-20** Sentences, buttons, pushes use the name alone; on the Journal parchment the name is the title and the species below, smaller; without a name everything reads the species.
- **D-21** Name rules = character name rules (length, characters, server-side content filter); a refused name shows the notice, retry or skip.
- **D-22** Companion cards in the menus (Journal list and slot, shop, prize lists) take the same style as spell and equipment cards; long press opens the details (same gesture, same kind of sheet); details = home of life, recovery, attack/defense and rename; the tap stays equip/unequip.

### Claude's Discretion
- Wire shape decided with the BE (OwnedPet fields, `Pet` recovery time, `useItem` target, companion entries of `QuestResult` / ambush report / mission draft, refusal codes).
- How the BE computes the resting life and schedules the «in forze» push.
- The gesture that opens the rename (tap stays equip/unequip), where the name prompt sits in the shop and on the result sheet (several prize companions = one prompt each), final copy.
- Selling a resting or defeated companion stays allowed.
- Pattern of the previous pairs: pre-gate plans on mocks, schema gate on the merged BE SDL, device E2E last; `22-REPO-RULES.md` before research and planner; `BACKEND-NOTES.md` in this directory.

### Deferred Ideas (OUT OF SCOPE)
- Companion portrait on the Profile tab.
- Push for a hurt companion that finishes resting (declined, D-11).
</user_constraints>

<phase_requirements>
## Phase Requirements

ROADMAP §Phase 22 says «Requirements: TBD (defined at planning)»; `REQUIREMENTS.md:93` coverage stops at GMFLOW. Proposed IDs (to be added to `REQUIREMENTS.md` + traceability by the orchestrator or the first plan, before any plan references them — `gsd-tools requirements mark-complete` fails on unknown IDs, Phase 20 Pitfall 11):

| ID (proposed) | Description | Decisions | Research Support |
|----|-------------|-----------|------------------|
| PET-01 | Companion state parsed leniently on `OwnedPet` (name, defeated, life dates, potion wait) and `Pet` (recovery time, max life); one display-name function (name, else species) used by every wording; companion vitality (life now, resting/defeated, remaining) derived only from served dates + server clock | D-02..D-04, D-09, D-20 | F-1, F-2 |
| PET-02 | Journal «Compagno»: «Vita: x / max» rising live while resting, «A riposo: in forze fra …», defeated parchment faded and not tappable with «Sconfitto: torna fra …», slot shows the equipped companion's life, name as title + species below | D-02, D-04, D-09, D-20 | F-2, F-3 |
| PET-03 | Companion cards restyled like spell/equipment cards in Journal, shop, basket and prize lists; long press opens a companion details sheet (life, recovery, attack/defense, xp, speed, recovery time, rename entry) | D-19, D-22 | F-3 |
| PET-04 | Potion sheet: «Bevi» + one «Dai a <nome>» parchment per eligible companion; potion row tappable when the character or a companion can drink; `useItem` with a target; new refusals mapped; companion potion wait shown on the companion | D-05..D-08 | F-4 |
| PET-05 | Name: prompt after a shop purchase and after a result sheet with a prize companion (one each, skippable), rename from the details sheet, character-name rules client-side, refusal notice with retry/skip | D-18..D-21 | F-5 |
| PET-06 | Result sheet (and ambush pages): companion life line, defeat line, xp line with the name | D-10, D-20 | F-6 |
| PET-07 | Ambushes and pushes: carousel opened mid-travel for unseen reports (existing queue), recomputed/redirected travel read from the stream, `ambush` push for every ambush, `petRecovered` category with its toggle | D-11, D-13..D-16 | F-7 |
| PET-08 | Innkeeper corrections: companion life slider next to the character's, bounds served (floor 1 = defeated), sent in the per-fight correction | D-17 | F-8 |
| PET-09 | Schema gate on the merged BE Phase 23 SDL (selections flipped, documents validated, full suite) and device E2E | all | F-9, F-10, Validation |

## Project Constraints (from CLAUDE.md)

- Clean Code, SoC (models Flutter-free, UI no networking, Cubit no `BuildContext`, Repository no `BuildContext`), **TDD red → green → refactor**, Boy Scout rule within scope.
- Rule 1 — no app chrome outside utility screens: Journal, shop, result sheet, ambush carousel, potion sheet, name prompt and companion details sheet are **gameplay** (parchments, in-world notices, no Material dialog/AppBar); the innkeeper wizard and the settings are utility.
- Rule 2 — no blocking loading in session: companion state arrives silently with `characterUpdated`; the live life is local interpolation; loaders only on explicit actions (give a potion, rename).
- Rule 3 — branch `feat/22-companion-defeat-rest-and-recovery`, PR → `develop`.
- Rule 4 — backend is the source of truth: the FE never decides a defeat, never computes life regained from `recoveryTime`, never computes a potion wait, never recomputes a travel, never validates a name beyond the character-name UX rules.
- Rule 5 — no secrets in repo.
- `docs/rules/graphql.md`: documents only in `lib/graphql/**`, named operations, `OperationException` never reaches the UI (repository classifier). `docs/rules/state-management.md`: one responsibility per Cubit, `Equatable` states, a Cubit never calls a Cubit, `bloc_test` for every non-trivial Cubit, timers cancelled in `close()`. `docs/rules/ui-ux.md`: theme tokens only, tap targets ≥ 44, domain images via `CachedSvg`, long lists `ListView.builder`. `docs/rules/testing.md`: model tests first, fixtures under `test/helpers/fixtures/`.
- Repo practice (`22-REPO-RULES.md`): sequential plans on the main tree, `dart format` per touched file only, analyzer gate 47 info / 0 warning / 0 error, full suite only in the gate plan (baseline 4722), no commit trailers, scope `phase-22`, BE read-only, `pubspec.lock` never staged, registry 54 today and every new document registered in the plan that adds it, no new dependency, no new Cloudinary asset id.

## Summary

**(1) Every companion is identified by its catalogue pet id today, and the BE guarantees one owned entry per species.** `CompanionCubit.toggle(character, petId)` → `CompanionRepository.equip(petId)` → `EquipPetRequest { id, petId }` (`companion_cubit.dart:48-59`, `companion_repository.dart:23-29`, `equip_pet_request.dart:5-17`); rows are keyed `ValueKey(entry.pet.id)` (`companion_content.dart:51-59`); the slot and the shop compare `pet.id` (`companion_section.dart:20-27`, `shop.dart:178, :395-400`). The BE refuses buying an owned species (`trade-pets.ts` `assertPetsNotOwned`, D-14) and skips a prize species already owned (`outcome-plan.ts:351-361` `petWonBy`), and `QuestResult.rewards.pet` is written only when the entry was actually added (`outcome-plan.ts:472, :553`). Consequence: the FE knows **which** entry was just acquired without any new field (shop: the bought `TradeSelection.pets`; result: `rewards.pet.id`), and `useItem`/`renamePet` could be keyed by the catalogue `petId` exactly like `equipPet`. The draft's `OwnedPet.id` would introduce a second key next to `equipPet.petId` (W-2: recommend one key). Adding `id` breaks nothing on the FE (selection is opt-in; PROBE: extra keys ignored).

**(2) The live life is a Journal-scoped ticker over served dates — the SpellRecoveryCubit pattern, not TravelProgressCubit.** The Journal already has three server-clock tickers that live only while the Journal page is mounted: `SpellRecoveryCubit` (map of statuses, one timer while any countdown runs, `offsetChanges` resync — `spell_recovery_cubit.dart:15-76`), `PotionRecoveryCubit` over the shared `ServerDeadlineCountdown` (`potion_recovery_cubit.dart:15-42`, `server_deadline_countdown.dart:10-54`). A `CompanionVitalityCubit` with the same shape (inputs = owned entries, output = `Map<petId, CompanionVitality>`) gives the rising number, the countdowns, the potion eligibility and the faded state, all from `(currentLifePoints @ lifeAsOf) → (maxLifePoints @ fullLifeAt)` linear interpolation on `ServerClockService.now()`. Provided at the Journal level so the companion section, the items section (potion eligibility) and the details sheet share it; handed `.value` to the potion sheet on the root navigator (pattern `items_section.dart:212-238`). `Pet.maxLifePoints` exists on today's SDL (`maxLifePoints: Int!`) but `PetFragment` does not select it (`pet_fragment.dart:8-27`; PROBE: `pet.maxLifePoints == null` today) — selecting it is **live-safe pre-gate**, so «Vita: x / max» can ship before the BE merge.

**(3) D-15 needs no new FE mechanism: «unseen» = unacknowledged `QuestResult`, and the presenter already opens sheets mid-travel.** Ambush reports are `QuestResult`s with `kind: ambush` rendered by `QuestResultSheet` inside `AmbushReportCarousel` (`quest_result_presenter.dart:183-212, :270-283`, `ambush_report_carousel.dart:15-42`); the queue is fed by the live subscription and by `ListUnacknowledgedQuestResults` at cold start, resume and reconnection (`quest_results_cubit.dart:83-120, :349-368`); the presenter needs only «Map visible and free» + `TravelCubit` idle, and `TravelCubit` returns to `TravelIdle` as soon as `activeTravel` arrives (`travel_cubit.dart:171`, `quest_result_presenter.dart:164-172`). Mid-travel delivery is blocked **on the BE only**: every report, won or lost, is held in `status.activeTravel.ambushReports` until the arrival (`ambush-plan.ts:167, :320-330`, `travel-completion.service.ts:213`). If the BE inserts each ambush `QuestResult` at resolution and publishes it (W-6), D-15 works with zero FE logic change. Corollary: the draft's `AmbushReport.companion` duplicates `QuestResult.companion` (W-5, C-6).

**(4) The recomputed travel is already handled — if the BE keeps the defeat-detour shape.** `TravelProgressCubit` re-measures any travel that differs in road, start, end or destination and moves the pawn linearly on the served road (`travel_progress_cubit.dart:50-56, :104`, `travel_route.dart:93-101`); the Phase 16 reroute cases pass (`travel_progress_cubit_test.dart:663-720`, run this session). Linear progress over the **whole** road means a recomputed travel that keeps the original `road`/`startTime` and only lengthens `endTime` would make the pawn jump **backwards**; the BE must write the D-13 residual exactly like today's defeat detour: road from the ambush point, `startTime` = ambush instant, new `endTime`/`duration` (`ambush-detour.ts:19-44`, `ambush-plan.ts:361`) (W-7).

**(5) Four places where the draft table and the code disagree** (each a wish, none blocks): (a) mission corrections live in `MissionFightInput.corrections: [ParticipantOverrideInput!]` (SDL; `mission_draft_inputs.dart:92-131`), so `companionLifeAfter` belongs on `ParticipantOverrideInput` (and on `MissionFightEffects` for the simulated/corrected value), not on `SaveMissionDraftInput` (C-5, W-11); (b) today's «full life» refusal of a potion is `ITEM_NO_EFFECT` (`item_use_failure.dart:13`), and the wait refusal is `POTION_RECOVERING` with a `recoveryUntil` extension (`:12-16, :74-84`) — the companion wait should reuse that shape (C-8, W-4); (c) the potion row is **disabled** while the character's potion recovers (`items_section.dart:179-186`), which would hide the companions D-05 says stay usable (C-2); (d) `CompanionRow` (shop, basket, innkeeper prizes) has **no card at all** and the quest-sheet prize is a text line (`companion_row.dart:8-98`, `quest_info_sheet.dart:458-468`), so D-22 «prize lists» needs an interpretation (C-3).

**Primary recommendation:** fifteen sequential plans — twelve pre-gate (models and pure rules; live-safe `maxLifePoints` selection; vitality Cubit; card/details-sheet refactor; Journal states; shop/prize cards; potion plumbing; potion sheet; name plumbing; name entry points + wording; result lines + notifications; innkeeper slider) and three gated (schema gate + selection flip; device E2E + closing). Keep every new wire name behind one parser per type and one fragment constant so a BE rename costs one line.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `flutter_bloc` / `bloc_test ^10.0.0` / `mocktail ^1.0.5` | `CompanionVitalityCubit`, `CompanionNameCubit`, `PotionCubit.give`; `FakeServerClockService` exists (`test/helpers/fakes/fake_server_clock_service.dart:6`), `journal_harness.dart:140-147` injects it | [VERIFIED: codebase] |
| `equatable` | every new model/state with full `props` | [VERIFIED: codebase] |
| `graphql_flutter 5.2.1` via `KlimmeckGraphQl` | `useItem` with a target, `RenamePet` through `_successfulMutation` (pattern `graphql.dart:862-871`) | [VERIFIED: codebase] |
| `ServerClockService` | `now()` + `offsetChanges` for the vitality ticker (`server_clock_service.dart:33-39`) | [VERIFIED: codebase] |
| `cached_network_image` / `CachedSvg` | pet image on the card only if the user wants it (U-1); pattern `EnemyPortrait` | [VERIFIED: codebase] |
| Material `TextField`, `Slider` | name prompt field (themed, inside a parchment sheet), innkeeper companion slider (utility) | [VERIFIED: codebase `sheet_text_field.dart:52-68`, `correction_section.dart:96-111`] |
| Node + BE `node_modules/graphql` | `tool/schema_check/validate_documents.js` (gate) | [VERIFIED: codebase] |

## Architecture Patterns

### Recommended files
```
lib/models/owned_pet.dart                       # + name?, defeated, lifeAsOf?, fullLifeAt?, potionRecoveryUntil? (lenient), id? only if the BE keeps it
lib/models/pet.dart                             # + recoveryTime? (ms, lenient) → Duration getter
lib/models/companion/companion_vitality.dart    # NEW pure: sealed CompanionVitality {Steady, Resting, Defeated} + companionVitalityOf(OwnedPet, DateTime now, {bool isEquipped})
lib/models/companion/companion_display_name.dart# NEW pure: companionDisplayNameOf(OwnedPet) / of(name, Pet)
lib/models/quest_result/companion_outcome.dart  # NEW: CompanionOutcome (name, lifeBefore?, lifePoints, maxLifePoints, defeated, fullLifeAt?) lenient
lib/models/quest_result/quest_result.dart       # + companion (tryFromJson, null on malformed)
lib/models/mission/mission_fight.dart           # + MissionFightOutcome.companion (MissionCompanion), MissionFightEffects.companionLifeAfter?
lib/models/request/mission_draft_inputs.dart    # + MissionCorrection.companionLifeAfter? (sent only when non-null)
lib/utils/name_rules.dart                       # NEW pure: extracted from CharacterDraft (normalise, NameError) — CharacterDraft delegates (refactor, no behaviour change)
lib/utils/companion_lines.dart                  # NEW: «Vita: …», «A riposo: …», «Sconfitto: …», «Pozione: pronta fra …», result lines
lib/graphql/fragments/pet_fragment.dart         # + maxLifePoints (live-safe); + recoveryTime (gated); + imagePath only if U-1 = yes
lib/graphql/fragments/character_fragment.dart   # ownedPets { … new fields } (gated)
lib/graphql/fragments/quest_result_fragment.dart# + companion { … } (gated)
lib/graphql/mutations/character_mutations.dart  # UseItem + $petId/$ownedPetId (gated); RenamePet (new, registered when added, sent only after the gate)
lib/repository/item_use_repository.dart + item_use_failure.dart   # target + petDefeated + companion wait
lib/repository/pet_equip_failure.dart           # + defeated
lib/repository/companion_repository.dart + pet_rename_failure.dart (NEW)  # rename through its own classifier
lib/screens/mainScreen/tabs/journal/companionVitalityCubit/        # NEW (pattern spellRecoveryCubit/)
lib/screens/mainScreen/tabs/journal/companionNameCubit/            # NEW, provided by AuthenticatedShell next to CompanionCubit (authenticated_shell.dart:276-279)
lib/shared/components/popup/details_sheet_frame.dart              # NEW: extracted from SpellInfoSheet (parchment, paddings, card slot, bookmark)
lib/shared/components/popup/companion_info_sheet.dart + companion_info.dart   # NEW
lib/shared/components/popup/companion_name_sheet.dart             # NEW: name prompt parchment (gameplay)
lib/shared/components/cards/companion_card.dart # restyle (name title in rarity colour, species sub-label when named, optional image)
lib/shared/components/companion_row.dart        # + leading CompanionCard + onLongPress (shop, basket, innkeeper rows at once)
lib/models/notification_category.dart           # + petRecovered; ambush category accepts 'ambush' and 'ambushDefeat'
```
Names are proposals following `docs/rules/naming.md`; GraphQL names mirror the BE draft and change with it.

### F-1. Companion model and parsing today [VERIFIED: codebase + SDL]

| Item | File:line | Note |
|------|-----------|------|
| Owned entry | `owned_pet.dart:6-36` — `{ pet, xp, currentLifePoints }`, `tryFromJson` drops any other shape; comment «La vita non si mostra (D-18)» (superseded by D-09) | add fields lenient: `name` (String, empty → null), `defeated` (`== true`), dates via `DateTime.tryParse` (malformed → null) |
| Catalogue pet | `pet.dart:7-137` — `maxLifePoints` parsed (`:52`) but **not selected** (`pet_fragment.dart:8-27`) | add `recoveryTime` (`num` → int ms, `<= 0` → null, pattern `loot_recovery.dart:19-23`) |
| List | `character_assets.dart:22, :38-40` — unmodifiable, per-entry lenient; `ownedCatalogPets` (`:25`) used by the shop | shop sell list must move to `OwnedPet` to print names (F-5) |
| Equipped | `character_assets.dart:21, :34` — `assets.pet` is the **catalogue** `Pet`, not the entry | the slot resolves the entry by `pet.id` (`companion_section.dart:20-27`) → change to return the `OwnedPet` |
| Selection | `character_fragment.dart:93-103` (`pet { PetFragment }`, `ownedPets { xp currentLifePoints pet { PetFragment } }`), used by `character` and `characterUpdated` | **Pitfall 1:** any new field selected before the merge breaks both documents → the app loses its character |
| Identification | equip/unequip by catalogue `petId` (`equip_pet_request.dart:5-17`; SDL `input EquipPetRequest { id petId }`), rows/keys by `pet.id` (`companion_content.dart:53-58`), optimistic match by `assets.pet.id` (`companion_cubit.dart:173-178`) | one entry per species is a BE invariant (Summary 1); duplicates would collide in keys and in `_matches` |

PROBE `test/_probes/phase22_probe_test.dart` (deleted): `OwnedPet.tryFromJson` and `CharacterAssets.fromJson` with `id, name, defeated, lifeAsOf, fullLifeAt, potionRecoveryUntil` and `pet.recoveryTime` → parse, one entry kept; `ownedPetJson()` today → `pet.maxLifePoints == null`. Command `flutter test test/_probes/phase22_probe_test.dart …` → passed.

**Fragments/documents that change at the gate** (pre-gate: modelled, not selected):
- `CharacterFragment.assetsFields.ownedPets` → `character`, `characterUpdated`: `name defeated lifeAsOf fullLifeAt potionRecoveryUntil` (+ `id` if kept).
- `PetFragment` → `character`, `characterUpdated`, `GetCityShop`, `GetMissionDraft`/`GetMissionPrizeOptions` (`mission_queries.dart:60, :77`): `recoveryTime` (gated). `maxLifePoints` is **pre-gate live-safe** (SDL `type Pet { … maxLifePoints: Int! … }` today).
- `QuestResultFragment` (`quest_result_fragment.dart:17-133`) → `GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived`, `CompleteGuidedMission`: `companion { … }`.
- Mission draft fragment (Phase 21) → `GetMissionDraft`, `StartMissionDraft`, `SaveMissionDraft`, `SimulateMissionFight`: companion fields of the fight outcome.
- `UseItem` (`character_mutations.dart:75-89`): `$petId: ID` (or `$ownedPetId`) argument — **one** document, changed at the gate (count unchanged); pre-gate the variable cannot be declared (today's BE would refuse the whole document and break drinking).
- `RenamePet` (new): can be **added and registered pre-gate** (registry +1 → 55; Phase 21 registered its documents pre-gate) but never sent before the gate.

### F-2. Live rising life (D-09) [VERIFIED: codebase; recommendation]

- **Patterns in the codebase:** `TravelProgressCubit` (`travel_progress_cubit.dart:18-148`) interpolates position between `startTime`/`endTime` on `ServerClockService.now()`, ticks 1 s, re-measures on `offsetChanges`, lives inside `WorldMap`. The Journal tickers are the closer fit: `SpellRecoveryCubit` (inputs → map of statuses, timer only while some countdown can change, `offsetChanges` listener, created/closed by the section — `spell_recovery_cubit.dart:15-76`, `spells_section.dart:61-66, :92-99`) and `PotionRecoveryCubit` (`ServerDeadlineCountdown`, rounding up to the minute — `server_deadline_countdown.dart:33-43`).
- **Pure rule (Flutter-free, unit-tested with fixed `now`):**
  - equipped, or `fullLifeAt == null`, or `lifeAsOf == null` → `Steady(life: currentLifePoints, max)`;
  - else `t = (now − lifeAsOf) / (fullLifeAt − lifeAsOf)` clamped to `[0, 1]`; `life = currentLifePoints + floor((max − currentLifePoints) × t)`; `remaining = fullLifeAt − now`;
  - `now ≥ fullLifeAt` → `Steady(max, max)` (the parchment re-enables locally, exactly as potion parchments re-enable when `potionRecoveryUntil` passes — `items_section.dart:179-186` + `server_deadline_countdown.dart:35-37`);
  - `defeated && remaining > 0` → `Defeated(life, max, remaining)`; otherwise `Resting(life, max, remaining)`.
  - Floor rounding never shows `max` before `fullLifeAt`; the slope and the floor 1 come only from served numbers (REPO-RULES: never from `recoveryTime`).
- **Cubit:** `CompanionVitalityCubit({clock, tick = 1 s})`, `follow(List<CompanionVitalityInput>)` from `character.assets.ownedPets` + `assets.pet?.id`, state `Map<String, CompanionVitality>`; timer runs only while some entry is `Resting`/`Defeated`; `offsetChanges` → recompute; `close()` cancels both (state-management rule). One Cubit for all companions (one timer, one `follow`, like spells), not one per row.
- **Where it lives:** provided by `Journal` (`journal.dart`) above `ItemsSection` and `CompanionSection` (both need it: potion eligibility + rows); `follow` driven by a `BlocListener<CharacterCubit>` as in `items_section.dart:96-109`; the potion sheet (root navigator) and the Journal-hosted details sheet get it `.value` (pattern `journal.dart:278-286` for `SpellRecoveryCubit`). Ticks only while the Journal page is mounted (the shell's `PageView` destroys off-screen tabs — `companion_cubit.dart:13-16`).
- **At `fullLifeAt`:** local state shows full life and a tappable parchment; no reread; the served state converges when the BE emits (W-1: `defeated` resolved at read and `characterUpdated` published together with the `petRecovered` push). An equip refused with `PET_DEFEATED` on a stale view maps to a banner (F-4).
- **Three parchment states** (`OwnedCompanionRow`, `owned_companion_row.dart:27-73`, whose text column already carries the «Al tuo fianco» mark and the xp line): lines after «Esperienza: x / y» → «Vita: x / max»; Resting → «A riposo: in forze fra …»; Defeated → «Sconfitto: torna fra …», `AnimatedOpacity(pendingInkOpacity)` + no `onTap` (pattern `ItemRow.isDisabled`, `item_row.dart:35-39, :51-54`); the equipped one shows «Vita» without countdown. Every duration through `formatGameDuration` (`game_duration_format.dart:7-15`).

### F-3. Companion cards and details sheet (D-22) [VERIFIED: codebase]

**Every place a companion is drawn today:**

| Place | File:line | Widget today | Gesture |
|-------|-----------|--------------|---------|
| Journal slot | `companion_slot.dart:39-48` | `CompanionCard` (text labels on `emptyCardSheet`) | tap = unequip |
| Journal list | `owned_companion_row.dart:32-48` | `CompanionCard` + text column | tap = equip/unequip |
| Shop buy/sell lists | `shop_modal.dart:202-221` | `CompanionRow` (text only + coins) | tap = select |
| Shop basket | `transaction_modal.dart:239-246` | `CompanionRow` | tap = remove |
| Innkeeper prize step / catalogue | `prizes_step.dart:450-461`, `prize_catalogue_sheet.dart:105` | `CompanionRow` (utility) | tap = add/remove |
| Quest sheet prize | `quest_info_sheet.dart:458-468`, `quest_sheet_details.dart:178-179` | text «Compagno in premio: X» (`prizes.pet { id name }` only, `quest_fragment.dart:95-98`) | none |
| Result sheet | `quest_result_sheet.dart:476-481` | text «Compagno ottenuto: X» | none |

**Spell and equipment cards:** `SpellCard` (`spell_card.dart:9-83`: `emptyCardSheet`, use-type + energy icons, name, power, pencil counter, bookmark) and `EquipmentItemCard` (`equipment_item_card.dart:11-138`: icon of the equip type, name in rarity colour with `AutoSizeText`, quantity, bookmark; owns `onTap`/`onLongPress`). Spell rows put the gestures on the row (`known_spell_row.dart:34-38`, `spell_slot_row.dart:64`); equipment rows get them through the card (`item_row.dart:55-64`). **No shared base** among the details sheets: `SpellInfoSheet` (`spell_info_sheet.dart:13-84`) and `EquipmentInfoSheet` (`equipment_info_sheet.dart:13-…`) each repeat the parchment frame (`emptySheet`, height × 1.3, paddings /6 /9 /8, `BookmarkRibbon` as equip toggle). Hosting: the Journal slides the sheet in from its own `Stack` (`journal.dart:236-286, :311-327`: `_selectEquipment` / `_selectSpell`, one `AnimationController`); the shop uses `EquipmentInfoSheetDisplay` with its own controller (`shop.dart:227-230`, `equipment_info_display.dart:5-76`, **not formatter-clean**).

**Companion details sheet content** (D-19, D-22): card at half width, title = display name, species below when named, rarity; «Vita: x / max» live (+ «A riposo: in forze fra …» / «Sconfitto: torna fra …»); «Recupero completo: …» from `recoveryTime` (read only, gated field); «Attacco: …», «Difesa: …» (`petAttackLine`/`petDefenseLine`), speed label (`companionSpeedLabel`), «Esperienza: x / y»; potion wait «Pozione: pronta fra …» when `potionRecoveryUntil` is in the future; rename action «Dai un nome» / «Cambia nome» (only for an owned entry); `BookmarkRibbon` = equip/unequip toggle in the Journal (disabled when defeated or on mission), absent in the shop.

**Smallest refactor without duplication:**
1. Extract `DetailsSheetFrame({card, body, bookmark?})` from `SpellInfoSheet` (pure refactor: `spell_info_sheet` tests stay green); `CompanionInfoSheet` = frame + `CompanionInfo`. Leave `EquipmentInfoSheet` alone (out of scope, large).
2. Restyle `CompanionCard` (title in rarity colour like `EquipmentItemCard`, species sub-label when a name is given, optional image per U-1, bookmark kept); move speed/attack/defense to the row text and the details sheet (the card stays readable at Journal size).
3. `CompanionRow` gains a leading `CompanionCard` and `onLongPress` → shop lists, basket and innkeeper rows change at once (one widget, four call sites).
4. Journal: `CompanionSection(onShowDetails)` like `SpellsSection(onShowDetails)` (`spells_section.dart:49-66, :154-155`); `Journal._selectCompanion(petId, vitality)` beside `_selectSpell`; `OwnedCompanionRow`/`CompanionSlot` get `onLongPress` on their `GestureDetector`.
5. Shop: generalise the slide-in host to take a child (then the style commit of `equipment_info_display.dart` comes first) or add a sibling `CompanionInfoSheetDisplay` — recommended: generalise (`DetailsSheetDisplay`), equipment keeps working.

### F-4. Potion sheet (D-05..D-08) [VERIFIED: codebase + SDL]

- **Today's flow:** `ItemsSection._row` (`items_section.dart:159-192`): not a heal potion or awaiting aid → read-only; on mission → disabled «Missione in corso»; `PotionRecoveryCubit.remaining != null` → disabled «pronta fra …»; else tap → `_confirmDrink` (`:212-238`) opens `PaperSheetModal(PotionSheet)` on the root navigator with `PotionCubit` `.value` and `maxLifePoints`. `PotionSheet` (`potion_sheet.dart:17-187`): «Bevi <nome>?», cure/recovery lines, «Non ora» / «Bevi»; in flight → actions off, `PopScope(canPop: false)`; drunk → hp bar from `UseItemResult.hpBefore/hpAfter` (`:146-157`); refused → closes, banner via `PotionOutcomeListener`. `PotionCubit.drink(itemId)` (`potion_cubit.dart:20-31`), states `PotionIdle/Drinking/Drunk/Refused` (`potion_state.dart`). `ItemUseRepository.useItem(itemId)` (`item_use_repository.dart:21-31`), classifier (`item_use_failure.dart:56-84`: `POTION_RECOVERING` + `recoveryUntil` extension, `ITEM_NO_EFFECT`, `AWAITING_AID`, `MISSION_IN_PROGRESS`, …). SDL today: `useItem(itemId: ID!): UseItemResult!`, `UseItemResult { hpAfter hpBefore injuriesHealed loreUnlocked quantityLeft recoveryUntil }`.
- **Row gating (C-2):** the row becomes tappable when `!isOnMission && !awaitingAid && (characterCanDrink || anyCompanionEligible)`; the status line keeps the character's «pronta fra …» while it runs.
- **Sheet:** under the confirmation, one `CompanionPotionTarget` parchment per eligible companion («Dai a Fenrir», small companion card + «Vita: x / max»); «Bevi» disabled with the character's countdown when the character is recovering; eligibility read from `CompanionVitalityCubit` state + `OwnedPet.potionRecoveryUntil` (not defeated, `life < max`, wait over) — display only (BE judges). No eligible companion → today's sheet unchanged (D-08).
- **Cubit:** `PotionCubit.give(itemId, petId)` (same single-flight; states carry an optional `targetPetId`); outcome face: title = display name of the target, hp bar with the **companion's** `maxLifePoints` (passed in, like `maxLifePoints` today), no «Guarite» for pets; refusal closes the sheet as today.
- **Repository/classifier:** `useItem(itemId, {String? petId})`; `ItemUseFailure.petDefeated` (`PET_DEFEATED`), companion wait = `potionRecovering` with `recoveryUntil` (W-4: reuse `POTION_RECOVERING` scoped to the target) or a new `petPotionRecovering` if the BE insists on `PET_POTION_RECOVERY`; full life = `ITEM_NO_EFFECT` (today's code). `PetEquipFailure.defeated` for `equipPet` (`pet_equip_failure.dart:44-58`) with its copy in `companion_notice.dart:23-36`.
- **Notices:** `potionNoticeFor(failure, {remaining, targetName})` — a target name switches the title to «Pozione non data» and the lines to the companion (copy table).
- **Per-companion wait on the companion:** status line on the Journal row and in the details sheet («Pozione: pronta fra …» from `potionRecoveryUntil`, ticking with the vitality Cubit — no second ticker).
- **Lock:** `isOnMission` disables the row (`items_section.dart:171-178`), so the sheet never opens on mission; `MISSION_IN_PROGRESS` already mapped. **Awaiting aid:** today the row is read-only for potions (`:167-170`); keep it for companions too unless the BE says `AWAITING_AID` does not apply to a companion target (W-4).

### F-5. Name (D-18..D-21) [VERIFIED: codebase + BE read]

- **Character-name input:** `SheetTextField` (`sheet_text_field.dart:6-69`, Material `TextField`, utility styling) used at `character_creation_screen.dart:137-147`; rules in `CharacterDraft` (`character_draft.dart:9, :26-58`: normalise whitespace, 2–20, `^[\p{L}'’\- ]+$` with at least one letter → `NameError {required, tooShort, tooLong, invalidCharacters}`), messages `character_creation_messages.dart:9-17`; server codes `CHARACTER_NAME_INVALID` (copy «Il nome non è accettato dalle cronache, scegline un altro»), `CHARACTER_NAME_TAKEN`, `BAD_USER_INPUT` (`character_creation_failure.dart:4-66`, messages `:34-36`).
- **Reuse:** extract the rules to `lib/utils/name_rules.dart` (`normalizedNameOf`, `nameErrorOf`, `NameError` + messages); `CharacterDraft` delegates (refactor, its tests green). `CHARACTER_NAME_TAKEN` is not expected for pets (no uniqueness) — map it like invalid if it ever comes.
- **Prompt UI (gameplay):** `CompanionNameSheet` in `PaperSheetModal`: title «Come chiamerai il tuo Worg?», a themed `TextField` (no Material dialog), inline UX error, «Chiamalo così» / «Più tardi»; on submit → `CompanionNameCubit.rename(petId, name)` (idle/submitting/refused/done); refused → inline notice, field kept, retry or skip (D-21); success → sheet closes, the name arrives with `characterUpdated`. Keyboard in landscape: `isScrollControlled` + `viewInsets` padding (Pitfall 6).
- **Which entry was acquired:** shop — the bought pets are `_toBuy.pets` at the moment `TransactionDone` arrives (`shop.dart:329-335` clears `_toBuy` right there; `TransactionDone` carries nothing, `transaction_state.dart:10`) → capture the bought pet ids before clearing (or make `doTransaction` return them in the state); result — `QuestResult.rewards.pet.id` (written only when the entry was added, BE `outcome-plan.ts:553`). Uniqueness per species (Summary 1) makes the catalogue id enough; **no BE field needed** for this.
- **Where:** shop → after `TransactionDone`, one prompt per bought companion in sequence (post-frame, root navigator; buying never equips, Phase 13 D-08); result sheet → after «Continua» closes a result with `rewards.pet` (in `QuestResultPresenter._present`, `quest_result_presenter.dart:204-211`, before the next `_tryPresent`; the prompt route covers the shell so the next sheet waits — `isRouteCovered`), skipped when the entry already has a name; several prize companions = several results = one prompt each. Rename → the details sheet's «Dai un nome» / «Cambia nome».
- **Lock:** recommend rename **not** locked by «Missione in corso» (cosmetic, no game effect) — BE to confirm (W-10); `MISSION_IN_PROGRESS` mapped anyway.
- **Display name:** one function `companionDisplayNameOf(OwnedPet)` = trimmed name if non-empty else `pet.name ?? ''`. **Species wording inventory:** `companion_card.dart:46-50` (title), `companion_row.dart:71-74` (shop/basket/innkeeper — catalogue: species is right for buy/prizes, **sell list must pass the owned entry**: `shop.dart:174-179` passes `ownedCatalogPets`), `quest_sheet_details.dart:120, :178-179` (prize: species, correct), `quest_result_sheet.dart:476-481` («Compagno ottenuto: <species>», correct: unnamed yet), `quest_outcome_lines.dart:37-38` («Il tuo compagno guadagna N PE»: no name on the wire → W-5), `companion_notice.dart:6-7` (titles without name). Push texts are built by the BE (`notification_category.dart:3-6`, `push_event.dart:26-41`: title/body from `data`), so pushes need no FE wording.

### F-6. Result sheet (D-10) [VERIFIED: codebase]

- `QuestResultSheet._content` (`quest_result_sheet.dart:165-201`) is a flat list of `_line(text, key)` entries; the Phase 19 companion xp line is `companionXpGainedLine(_result.petXpGained)` at `:190-193` (`quest_outcome_lines.dart:35-38`), after the character xp line.
- Add after the xp lines (or right after `_hp()`): `companionLifeLine(companion)` → «Fenrir: 120 / 300 di vita» when `!defeated && lifePoints < lifeBefore` (or, without `lifeBefore`, when the entry is served at all — the BE's «null when unharmed»); `companionDefeatLine(companion, resolvedAt)` → «Fenrir è stato sconfitto: riposa e tornerà fra 10 h» with the duration `fullLifeAt − resolvedAt` (a **historical** sheet opened possibly hours later: never `fullLifeAt − now`, C-9). Keys `QuestResultSheet.companionLifeKey` / `companionDefeatKey`.
- The ambush carousel renders the same sheet (`ambush_report_carousel.dart:1-3`), so ambush pages get both lines for free from `QuestResult.companion`.
- xp line with the name when served (`companion?.name`), else today's copy.

### F-7. Ambushes, travel, pushes (D-11, D-13..D-16) [VERIFIED: codebase + BE read]

- **Carousel feed:** `QuestResultsCubit` (`quest_results_cubit.dart:26-397`) — live subscription `watch(characterId)` + `refetchPending()` at start/resume/reconnect; `presentable` = head or the consecutive ambushes (`quest_results_state.dart:45-50`); `isSettlingAmbushes` waits for the batch reread (`:55-56`); acknowledgement on close (`_present` → `closed(head.id)`). **Opened anywhere the Map is visible and free**, not only at the arrival (`quest_result_presenter.dart:150-172`); the Map is page 0 (`main_screen.dart:83`, `notification_intent_landing.dart:19`), so «opening the app opens the Map».
- **What must change for D-15:** BE only — insert each ambush `QuestResult` at resolution and publish it (today held in `activeTravel.ambushReports` until arrival, `ambush-plan.ts:320-330`, `travel-completion.service.ts:213`). Unseen = `acknowledgedAt == null` (already the FE's rule, `quest_results_cubit.dart:349-368`). **No flag, no mutation, no list on the travel needed.**
- **Double notice risk:** a live ambush with the Map visible would show the carousel **and** the foreground `ambush` push banner. `questEnd` solves it by suppressing `questEnd|<resultId>` when the sheet can open (`quest_result_presenter.dart:112-127`); the same works for `ambush|<resultId>` if the BE uses the result id as push `id` (W-8).
- **Recomputed travel (D-13/D-16):** handled by `TravelProgressCubit` as long as the BE writes road-from-point + `startTime` = ambush instant (Summary 4, W-7). The Phase 16 reroute tests (`travel_progress_cubit_test.dart:663-720`: «remaining route is the whole new road from the pawn», «advances along the new road», «fresh arrival budget») pass — run this session. A redirection after a **won** ambush prints «Portato a <città>» only if the BE fills `AmbushReport.reachedCity` (today `won ? null`, BE `reportOf`) (W-7).
- **Push categories:** `NotificationCategory` (`notification_category.dart:7-37`, explicit `storageKey` + `wireType`, unknown wire types dropped), settings switch per category with an exhaustive label switch (`notification_preferences_section.dart:23-52`; «Imboscate» is already the label of `ambushDefeat`), popup registry (`notification_popup_registry.dart:19-25`; entries optional — `streamerLive`/`questCancelled` have none).
  - `ambush` (D-14): **replace in place** — keep one category «Imboscate» with `storageKey: 'ambush_defeat'` (the user's saved toggle survives; the explicit key exists exactly for renames, `:1-2`), accept wire types `ambush` **and** `ambushDefeat` (pre-gate safe, deploy-order safe), popup `focusCharacterOnMap` (the queue opens the unseen pages anyway). Enum value rename `ambushDefeat → ambush` optional (pins in 9 test files).
  - `petRecovered` (D-11): new personal category, `storageKey: 'pet_recovered'`, label «Compagno in forze», no popup entry (lands on the Map) — adding it pre-gate is harmless (the BE never sends it before the merge).
  - Dedup is `(type, id)` for 2 min (`push_event.dart:45`, `in_app_notifications_cubit.dart:34`) — ids per ambush/recovery must differ (W-8, W-9).

### F-8. Innkeeper wizard (D-17) [VERIFIED: codebase + SDL]

- Corrections: `CorrectionSection` (`correction_section.dart:14-126`, utility `ExpansionTile` per participant; slider `minLifeAfterFight..maxLifePoints` with `divisions`, hidden when max = 1, text «x / max» — `:96-111`; `minLifeAfterFight = 1`, `mission_limits.dart:11-12`).
- Served shape for characters: `MissionFightOutcome { character hpBefore injuriesBefore consumablesAvailable spellsAvailable simulated corrected }`, `MissionFightEffects { hpAfter injuriesAdded consumablesUsed spellsUsed }` (SDL; `mission_fight.dart:44-152`); corrections sent as `MissionFightInput.corrections: [ParticipantOverrideInput!]` (`characterId hpAfter injuries consumablesUsed spellsUsed`; `mission_draft_inputs.dart:29-131`).
- Companion, mirroring that shape (W-11): `MissionFightOutcome.companion: MissionCompanion { pet: ID!, name: String!, maxLifePoints: Int!, lifeBefore: Int! }` (null = no companion in this fight, including one defeated on an earlier floor, D-12) and `MissionFightEffects.companionLifeAfter: Int` (null without companion); correction `ParticipantOverrideInput.companionLifeAfter: Int`. FE: `MissionCompanion.tryFromJson` (null on malformed), `effective.companionLifeAfter`, `MissionCorrection.companionLifeAfter` sent only when the participant has a companion; a second slider block «Compagno: Fenrir» under «Punti vita» (same `Slider` code, extracted into a small `LifeSlider` to avoid duplication), «Sconfitto» marker when the value is at the floor; recap line optional.
- Pre-gate: models parse the companion lenient; nothing is selected, so `companion` is always null and no `companionLifeAfter` is sent — the wizard keeps working on today's BE.

### F-9. Schema-check registry [VERIFIED: codebase]

- Registry `tool/schema_check/schema_check_documents.dart:51-…` = **54**; count pins in four files: `test/tool/schema_check_documents_test.dart:34`, `test/graphql/loot_fragment_test.dart:125`, `test/graphql/travel_documents_test.dart:197`, `test/graphql/shop_documents_test.dart:132`.
- New: `RenamePet` → **55**. Changed (count unchanged): `UseItem` (target variable), `character`, `characterUpdated`, `GetCityShop`, `GetMissionDraft`, `GetMissionPrizeOptions`, `StartMissionDraft`, `SaveMissionDraft`, `SimulateMissionFight`, `GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived`, `CompleteGuidedMission` (+ `quests`/`OnQuestUpdated` only if the quest-sheet prize card selects `PetFragment`, C-3).
- Selection pins that go RED: `test/graphql/shop_documents_test.dart:78-94` (exact `PetFragment` + «without imagePath (D-13)»), `test/graphql/character_fragment_test.dart:186-195` (`ownedPets { xp currentLifePoints pet { … } }`), the quest-result fragment pins.

### F-10. Pre-gate vs gated split [VERIFIED: codebase; recommendation]

- **Pre-gate, safe against today's BE:** all models (lenient, unselected), pure rules, vitality Cubit, cards/details sheet, Journal states (they render «Steady» with today's data: life + max once `maxLifePoints` is selected), `maxLifePoints` in `PetFragment` (live-safe), shop/prize cards, potion plumbing on mocks (`useItem(itemId, petId:)` path never taken: no eligible companion without served dates? — **careful:** with `maxLifePoints` selected and `currentLifePoints < max`, an equipped hurt companion **is** eligible by D-07 even pre-gate; the sheet must therefore hide companion targets until the gate, e.g. a `companionPotionsEnabled` constant flipped in the gate plan, or eligibility requiring a served `id`/flag — Pitfall 3), name plumbing + `RenamePet` registered (not sent: entry points hidden until the gate by the same switch), result lines (driven by `companion`, always null pre-gate), notification categories (`petRecovered` + dual ambush wire type), innkeeper slider (companion null pre-gate).
- **Gate plan flips:** selections (ownedPets fields, `recoveryTime`, `QuestResultFragment.companion`, mission companion fields), the `UseItem` variable, the potion/rename switch, final wire renames from the BE SDL, registry final count, schema check N × OK, full suite.
- **Device E2E (human, orchestrator-guided, one step per message):** (1) defeat in a fight: seed a weak equipped companion, run a fight/hunt → result sheet defeat line, slot emptied, Journal parchment faded «Sconfitto: torna fra …»; (2) rest: unequip a hurt companion → number rises live, countdown, re-equip mid-way keeps the reached life; (3) potion on a companion (equipped and resting), its own wait shown, character's potion still drinkable; refusals by GraphQL probe (`PET_DEFEATED`, companion wait); (4) name prompt after a purchase (skip once, name once), after a prize result; rename from the details sheet; a refused name (content filter) → notice, retry; names in «Dai a …», result lines and pushes; (5) ambush mid-travel with a mount: the push arrives, opening the app shows the carousel before the arrival, pawn continues on foot (arrival later), redirection case if food short; (6) «in forze» push after a defeated companion's wait (DB trick: move `fullLifeAt` back + sweep), toggle off in settings suppresses it; (7) innkeeper slider: simulate, move the companion slider to the floor, complete → participant's companion defeated and resting; (8) long press details in Journal and shop.

### Anti-Patterns to Avoid
- Computing life regained or the defeat wait from `Pet.recoveryTime` (REPO-RULES; slope only from served dates).
- One ticker per row, or a ticker at the shell level that runs off the Journal.
- Waiting for the server to re-enable a recovered companion (potions re-enable locally at the deadline; do the same).
- Selecting any new field in `CharacterFragment`/`PetFragment`/`QuestResultFragment` before the merge (except `maxLifePoints`, already in the SDL).
- Declaring `$petId` in `UseItem` before the merge (breaks every potion).
- Text rows opening a bottom sheet for companions (Phase 13 D-17 rejection); Material dialogs for the name prompt or details.
- Deriving «on foot» or «redirected» from local state; the page prints served facts only.
- `appLog` of companion names, results or ambush payloads (`tool/hardening_check.sh`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Server-clock ticking | a new timer per widget | `CompanionVitalityCubit` on the `SpellRecoveryCubit` shape / `ServerDeadlineCountdown` | one timer, offset resync, tested pattern |
| Duration copy | ad-hoc «h/min» | `formatGameDuration` | Phase 18 D-17 |
| Name validation | new regex | extracted `name_rules.dart` from `CharacterDraft` | D-21 same rules |
| Error mapping | inline code strings | per-action classifiers (`itemUseFailureFrom`, `petEquipFailureFrom`, new `petRenameFailureFrom`) | 11 classifiers precedent |
| Details sheet frame | a third copy of the parchment frame | `DetailsSheetFrame` extracted from `SpellInfoSheet` | zero duplication |
| Unseen ambushes | a «seen» flag/mutation | unacknowledged `QuestResult` + existing ack | already the queue's rule |
| Travel after an ambush | FE recomputation | served `activeTravel` + `TravelProgressCubit` | rule 4 |
| Schema validation | new script | `dump_documents.dart` + `validate_documents.js` | registry |

## Runtime State Inventory

Not a rename phase; the push-category change and new stored companion state are noted:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | BE: new fields on owned pets and `Pet.recoveryTime` (orchestrator seeds the table after the user review, D-01); FE `SharedPreferences` toggle `ambush_defeat` | keep `storageKey 'ambush_defeat'` so the toggle survives; new key `pet_recovered` |
| Live service config | none on the FE | none |
| OS-registered state | Android notification channel(s) used by `flutter_local_notifications` for push categories — verify in the plan whether channels are per category (none found in this read) | if per category: create the `petRecovered` channel; else none |
| Secrets/env vars | none | none |
| Build artifacts | none (no codegen); registry count pins in four test files | update pins in the plan adding `RenamePet` |

## Conflicts with the CONTEXT

Each with a proposed fix; no decision changed here — the orchestrator arbitrates.

- **C-1 (D-09 «as the pawn in travel», CONTEXT code_context «`TravelProgressCubit` as the pattern»):** the closer and cheaper pattern is the Journal's `SpellRecoveryCubit`/`ServerDeadlineCountdown` (Journal-scoped, map of statuses). Same principle (interpolation between served dates on the server clock), different host. **Fix:** `CompanionVitalityCubit` on the spells shape (F-2).
- **C-2 (D-05/D-08 vs Phase 18 D-12 row behaviour):** the potion row is disabled while the character's potion recovers (`items_section.dart:179-186`, pinned by `items_section_test.dart:186-250`), so the companions could not get a potion during the character's wait — contradicting D-05. **Fix:** row tappable when the character **or** a companion can drink; «Bevi» disabled inside with the countdown (F-4). Phase 18 tests change for the «companion eligible» case only.
- **C-3 (D-22 «prize lists»):** no prize list shows a companion card today: the quest-sheet prize is a text line with `prizes.pet { id name }` only, the result sheet prints «Compagno ottenuto: X», the innkeeper prize rows use the text `CompanionRow`. **Fix (recommended):** `CompanionRow` with a leading card covers shop, basket and innkeeper rows; the quest-sheet prize line becomes a `CompanionCard` with long press (needs `PetFragment` under `prizes.pet`, live-safe today); the result sheet keeps its text line. Scope question U-2.
- **C-4 (D-22 «same style as spells and equipment» vs Phase 13 D-13 «no image»):** spell/equipment cards carry an icon; the companion card is text-only by Phase 13 D-13 (a «no new assets» rule of a no-UI phase). `Pet.imagePath: String!` is served today. **Fix:** user decides (U-1); default without image = name + rarity colour + species sub-label.
- **C-5 (REPO-RULES draft «`companionLifeAfter: Int` in `SaveMissionDraftInput`»):** corrections travel per fight per character in `MissionFightInput.corrections: [ParticipantOverrideInput!]` (SDL). **Fix:** `ParticipantOverrideInput.companionLifeAfter` + `MissionFightEffects.companionLifeAfter` + `MissionFightOutcome.companion` (W-11).
- **C-6 (REPO-RULES draft «`AmbushReport.companion`»):** an ambush report **is** a `QuestResult` (`kind: ambush`, nullable `quest`, `ambush` sub-object — `quest_result_fragment.dart:11-12, :122-132`); the carousel renders `QuestResultSheet`. **Fix:** one `QuestResult.companion` for quests and ambushes; drop `AmbushReport.companion` (W-5).
- **C-7 (REPO-RULES draft «full life as today's code for the character»):** today's code is `ITEM_NO_EFFECT` («the potion would change nothing»), not a full-life code (`item_use_failure.dart:13, :23-24`). **Fix:** reuse `ITEM_NO_EFFECT` for a companion at full life; copy names the companion.
- **C-8 (REPO-RULES draft `PET_POTION_RECOVERY`):** the character's wait is `POTION_RECOVERING` + extension `recoveryUntil` (`item_use_failure.dart:12-16, :74-84`). **Fix:** reuse `POTION_RECOVERING` with the target's `recoveryUntil` (the FE knows the target), or `PET_POTION_RECOVERING` **with** the same extension (W-4).
- **C-9 (D-10 «tornerà fra 10 h» on the result sheet):** the sheet is a dated record (`resolvedAt`, `quest_result_sheet.dart:213-217`) and can open hours later. **Fix:** duration `fullLifeAt − resolvedAt` (fixed, no ticker); never `fullLifeAt − now`.
- **C-10 (Phase 19 D-18 «la vita non si mostra»):** superseded by D-09; update the doc comment at `owned_pet.dart:4-5` in the model plan.
- **C-11 (Phase 16 D-02 «No banner or push on a victory», D-13 reports held until arrival):** superseded by D-14/D-15; the presenter's «no banner for reports» (`quest_result_presenter.dart:116-118`) stays, the push banner is suppressed when the carousel opens live (W-8).
- **C-12 (REPO-RULES draft `OwnedPet.id` + `ownedPetId` on `useItem`/`renamePet` next to `equipPet.petId`):** two keys for the same entry. **Fix:** one key — catalogue `petId` everywhere (uniqueness per species is a BE invariant), or `ownedPetId` everywhere including `equipPet`/`unequipPet` (W-2).
- **C-13 (D-20 «sentences use the name») vs result xp line:** «Il tuo compagno guadagna N PE» (`quest_outcome_lines.dart:37-38`) has no name on the wire when the companion was unharmed (draft: `companion` null then). **Fix:** W-5 (serve `companion` whenever a companion fought, with `lifeBefore`).

## What the FE needs from the BE

Every wish beyond / against the draft table (`22-REPO-RULES.md` §Contract), to be reconciled with the BE `23-RESEARCH.md`:

- **W-1 Resting state semantics:** `currentLifePoints` = life at `lifeAsOf`; `lifeAsOf` and `fullLifeAt` both non-null exactly when the companion is resting below full life (null when equipped or full); `defeated` resolved at read (true only while `fullLifeAt > now`) and `equipPet` judged on the same predicate (so a local re-enable at `fullLifeAt` is never refused); `characterUpdated` published when a defeated companion recovers (same moment as the `petRecovered` push). Linear recovery between the two served points (the FE interpolates exactly that).
- **W-2 One key:** keep the catalogue `petId` for `useItem` and `renamePet` like `equipPet` (owned entries unique per species: BE `trade-pets.ts` D-14, `outcome-plan.ts:351-361`), **or** add `OwnedPet.id` and accept it on `equipPet`/`unequipPet` too. Either way say whether one-entry-per-species stays an invariant (FE keys rely on it).
- **W-3 `Pet.recoveryTime`:** milliseconds like `LootRecovery.time`; GraphQL `Int` caps at 2 147 483 647 ms ≈ 24.8 days — confirm the seeded maximum (Pegaso) is below, else `Float` or minutes. `Pet.maxLifePoints` is already served (FE starts selecting it pre-gate).
- **W-4 `useItem` target:** argument name (`petId` or `ownedPetId`, nullable); `UseItemResult.hpBefore/hpAfter` = the **target's** life, `recoveryUntil` = the target's wait, `injuriesHealed` = `[]` for a pet; refusals: `PET_DEFEATED`; companion wait = `POTION_RECOVERING` (or `PET_POTION_RECOVERING`) **with `extensions.recoveryUntil`**; full life = `ITEM_NO_EFFECT`; `MISSION_IN_PROGRESS` and `AWAITING_AID` apply to a companion target as to the character (state it); the character's `potionRecoveryUntil` never blocks a companion target (D-05); lore «Il limite del corpo» on the first companion potion (D-05 mentions the lore) — say whether `loreUnlocked` can come from a companion potion.
- **W-5 `QuestResult.companion: CompanionOutcome`** served **whenever a companion fought** (null otherwise), fields `name: String!` (display name), `lifeBefore: Int!`, `lifePoints: Int!`, `maxLifePoints: Int!`, `defeated: Boolean!`, `fullLifeAt: DateTime`; the FE prints the life line only when `lifePoints < lifeBefore` and not defeated, the defeat line when defeated, and names the xp line. Drop `AmbushReport.companion` (ambush reports are `QuestResult`s).
- **W-6 Mid-travel ambush delivery:** insert each ambush `QuestResult` at resolution (`resolvedAt` = ambush instant) and publish it on the result subscription instead of holding it in `activeTravel.ambushReports` until arrival; unseen = `acknowledgedAt == null`. No new flag, mutation or list needed by the FE.
- **W-7 Recomputed travel shape (D-13/D-16):** like today's defeat detour — `road` from the ambush point, `startTime` = ambush instant, recomputed `endTime`/`duration`, `to` changed only on redirection; on a redirection after a **won** ambush fill `AmbushReport.reachedCity` (the page prints «Portato a <città>»). Optional: `AmbushReport.onFoot: Boolean!` if a «Prosegui a piedi» line is wanted (copy U-6).
- **W-8 Push `ambush`:** personal, `id` = the ambush `QuestResult` id (dedup per ambush, banner suppression when the carousel opens live), title/body by the BE with the display name when the companion fell; say whether `ambushDefeat` keeps being sent (the FE accepts both).
- **W-9 Push `petRecovered`:** personal, `id` unique per recovery (pet id is fine: dedup window 2 min), title/body with the display name («Fenrir è di nuovo in forze»).
- **W-10 `renamePet`:** request `{ petId | ownedPetId, name }`, `CommonResponse`; server normalisation and limits equal to the character name (2–20, letters/space/apostrophe/hyphen, content filter); codes `CHARACTER_NAME_INVALID` (or `PET_NAME_INVALID`), `BAD_USER_INPUT`, stale entry → `PET_NOT_OWNED`/`NOT_FOUND`; not refused by `MISSION_IN_PROGRESS` (recommended); emits `characterUpdated`; `name: null` clears (FE will not expose clearing in this phase).
- **W-11 Mission draft companion:** `MissionFightOutcome.companion: MissionCompanion { pet: ID!, name: String!, maxLifePoints: Int!, lifeBefore: Int! }` (null = none, also after a floor defeat D-12), `MissionFightEffects.companionLifeAfter: Int` (simulated and corrected), correction `ParticipantOverrideInput.companionLifeAfter: Int` (bounds `1..maxLifePoints`, 1 = defeated); invalidation rules unchanged.
- **W-12 Name everywhere it is served:** `CompanionOutcome.name`, `MissionCompanion.name` and push texts use the display name (name else species), so the FE never has to join names.

## Open Questions (RESOLVED)

Recommended defaults (the orchestrator confirms in REPO-RULES):
1. **Pre-gate visibility of companion potions and rename.** Hidden behind one constant flipped in the gate plan (Pitfall 3). Default: yes.
2. **Rename lock during «Missione in corso».** Not locked (cosmetic); FE maps the code anyway. Default: not locked, BE to confirm (W-10).
3. **Companions in their own potion wait in the potion sheet.** Hidden (literal D-08); their wait is shown on the Journal row and in the details sheet. Default: hidden.
4. **Clearing a name.** Not offered in this phase. Default: no.
5. **`petRecovered` tap.** No popup (lands on the Map). Default: no popup.
6. **Ambush category.** One «Imboscate» toggle, `storageKey` kept, both wire types accepted. Default: replace in place.
7. **Result defeat duration.** `fullLifeAt − resolvedAt`. Default: as C-9.
8. **Card details host in the shop.** Generalise `EquipmentInfoSheetDisplay` into a child-taking host (style commit first). Default: generalise.

### For the user (product-level)
- **U-1 — Pet image on the cards.** «Le carte dei compagni devono mostrare l'immagine dell'animale (servita dal backend, come i nemici) sopra il nome, come le icone di magie ed equipaggiamenti? (a) sì; (b) no, solo nome colorato per rarità e specie sotto.» Recommended: **(a)** if every pet has an `imagePath` on Cloudinary (the orchestrator checks the DB), else (b).
- **U-2 — Which «prize lists».** «La carta del compagno con il tocco prolungato va anche (a) nel foglio della quest («Compagno in premio») e nelle liste premi dell'oste; (b) solo nelle liste premi dell'oste; (c) solo Diario e negozio.» Recommended: **(a)**.
- **U-6 — Line «a piedi» on the ambush page.** «Quando la cavalcatura cade in un'imboscata vinta, la pergamena dice anche «Prosegui a piedi»? (a) sì; (b) basta la riga «Fenrir è stato sconfitto…».» Recommended: **(b)** (no extra wire); (a) needs W-7 optional field.

## Pitfalls

### Pitfall 1: gated selection on the character fragment
Any new `ownedPets` field (or `recoveryTime` in `PetFragment`) selected before the BE merge breaks `character` and `characterUpdated` → the app loses its character (Phase 21 Pitfall 2). Only `maxLifePoints` is safe today (in the SDL).

### Pitfall 2: `UseItem` variable before the merge
Declaring `$petId` makes today's BE reject the whole document: the character can no longer drink. The variable lands in the gate plan.

### Pitfall 3: eligible companions appear pre-gate
Once `maxLifePoints` is selected, an equipped companion with `currentLifePoints < max` satisfies D-07 even on today's BE; showing «Dai a …» would send a target the BE cannot read. Hide companion targets (and the rename entry) until the gate plan flips one constant.

### Pitfall 4: the backward-jumping pawn
`travelProgress` is linear over the whole served road (`travel_route.dart:93-101`); a recomputed travel that keeps the original road/start and only moves `endTime` moves the pawn back. Device check in the E2E; BE shape W-7.

### Pitfall 5: double notice for a live ambush
Foreground push banner + carousel at the same time. Suppress `ambush|<resultId>` like `questEnd` (`quest_result_presenter.dart:112-127`) when the BE uses the result id (W-8).

### Pitfall 6: keyboard in landscape on a parchment sheet
The name prompt must keep the field visible with the keyboard open (FE 21 UAT: `resizeToAvoidBottomInset` removes `viewInsets` from the body; pad by hand) and never overflow.

### Pitfall 7: historical result sheet with a live countdown
«tornerà fra …» from `now` is wrong for a sheet opened hours later; use `fullLifeAt − resolvedAt` (C-9).

### Pitfall 8: rounding the rising life
`round()` can show `max` one tick before `fullLifeAt` while the parchment is still faded; use `floor` and switch to `max` exactly at the deadline.

### Pitfall 9: shop sell list loses the name
`_sellStock` passes `ownedCatalogPets` (`shop.dart:174-179`); named companions would show the species. Pass `OwnedPet` (or a display-name map).

### Pitfall 10: pins that go red
`shop_documents_test.dart:78-94` (exact `PetFragment`, «without imagePath»), `character_fragment_test.dart:186-195`, the four registry pins (54 → 55), `notification_category_test.dart:5-41` (values, storage keys, wire types), `notification_preferences_section_test.dart:72` («five labelled switches» — already stale wording, count grows), `items_section_test.dart:186-250` (disabled during recovery), `quest_outcome_lines_test.dart` / `quest_result_sheet_test.dart` («Il tuo compagno guadagna»).

### Pitfall 11: `equipment_info_display.dart` not formatter-clean
Style commit first if the shop host is generalised.

### Pitfall 12: duplicates per species
FE keys (`ValueKey(entry.pet.id)`), `CompanionCubit._matches` and the acquired-entry lookup assume one entry per species; if the BE ever allows duplicates every one of them must move to an owned id (W-2).

### Pitfall 13: `Int` overflow of `recoveryTime`
32-bit GraphQL `Int` in ms caps at ~24.8 days (W-3).

### Pitfall 14: REQUIREMENTS scope
Add the PET IDs before plans reference them.

## Code Examples

### Lenient owned-entry fields (pattern `quest.dart:47`, `loot_recovery.dart:19-23`)
```dart
// lib/models/owned_pet.dart (sketch)
name: _nameOf(json['name']),               // String, trimmed, empty → null
isDefeated: json['defeated'] == true,
lifeAsOf: _instantOf(json['lifeAsOf']),     // DateTime.tryParse(...)?.toUtc()
fullLifeAt: _instantOf(json['fullLifeAt']),
potionRecoveryUntil: _instantOf(json['potionRecoveryUntil']),
```

### Vitality rule (pure)
```dart
CompanionVitality companionVitalityOf(OwnedPet owned, DateTime now, {required bool isEquipped}) {
  final max = owned.pet.maxLifePoints;
  final from = owned.lifeAsOf, to = owned.fullLifeAt;
  if (max == null || isEquipped || from == null || to == null) {
    return CompanionSteady(life: owned.currentLifePoints, max: max);
  }
  if (!now.isBefore(to)) return CompanionSteady(life: max, max: max);
  final span = to.difference(from).inMilliseconds;
  final share = span <= 0 ? 1.0 : (now.difference(from).inMilliseconds / span).clamp(0.0, 1.0);
  final life = owned.currentLifePoints + ((max - owned.currentLifePoints) * share).floor();
  final remaining = to.difference(now);
  return owned.isDefeated
      ? CompanionDefeated(life: life, max: max, remaining: remaining)
      : CompanionResting(life: life, max: max, remaining: remaining);
}
```

### Dual ambush wire type
```dart
// lib/models/notification_category.dart (sketch)
ambush('ambush_defeat', 'ambush', legacyWireTypes: {'ambushDefeat'}),
petRecovered('pet_recovered', 'petRecovered');
static NotificationCategory? fromWireType(Object? value) {
  for (final c in values) {
    if (c.wireType == value || c.legacyWireTypes.contains(value)) return c;
  }
  return null;
}
```

### Refusal code reuse
```dart
// lib/repository/item_use_failure.dart
const String petDefeatedCode = 'PET_DEFEATED';
petDefeatedCode => ItemUseFailure.petDefeated,
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Companion life parsed, never shown (Phase 19 D-18) | «Vita» + live rest + defeated state | D-09 | `maxLifePoints` selected, vitality Cubit |
| Ambush reports held until arrival, push only on defeat (Phase 16 D-02/D-13) | Reports at resolution, push for every ambush | D-14/D-15 | BE change; FE category + suppression |
| Speed photographed at departure | Residual on foot after a mount defeat | D-13 | read-only on the FE |
| Text-only companion rows (Phase 13 D-13/D-15) | Cards + long-press details | D-22 | `CompanionRow` + `CompanionCard` + details sheet |
| Species everywhere | Display name (name else species) | D-18..D-20 | one function, prompt, rename |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Draft wire names of `22-REPO-RULES.md` (`OwnedPet` fields, `Pet.recoveryTime`, `useItem(…, ownedPetId)`, `renamePet`, `CompanionOutcome`, `PushEventType.ambush`/`petRecovered`, mission companion) | all | renames in the gate plan (one fragment + parser per type) |
| A2 | The BE keeps one owned entry per species | F-1, F-5 | acquired-entry lookup and keys must move to an owned id |
| A3 | Pets have Cloudinary images in `imagePath` | C-4, U-1 | image variant not possible → text card |
| A4 | Android notification channels are not per category (not found in this read) | Runtime State | a channel to add for `petRecovered` |
| A5 | Full suite 4722 (not re-run per the rules) | Validation | baseline number in the gate SUMMARY only |
| A6 | Italian copy of the copy table | Copy | orchestrator/user fix it in REPO-RULES |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | analyze/test | ✓ | `flutter test` ran this session | — |
| BE SDL `origin/develop` | live-safe `maxLifePoints` | ✓ (`type Pet { maxLifePoints: Int! }`) | `2c462cbe` | — |
| Node + BE `node_modules/graphql` | schema check | ✓ (used in Phases 20–21) | — | — |
| BE merged SDL with Phase 23 | gated plans | ✗ (BE research in progress) | — | park at the gate plan |
| Device + BE boot + UAT data (weak companion, mount, food, DB tricks) | E2E | orchestrator/user | — | none (human checkpoint) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test ^10.0.0` + `mocktail ^1.0.5` (+ `fake_async` for tickers) |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `journal_harness.dart`, `fakes/fake_server_clock_service.dart`, fixtures `shop_fixtures.dart` `petJson`/`ownedPetJson`) |
| Quick run command | `flutter test <touched test files>` (foreground) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (gate plan only, timeout ≥ 300 000 ms) |
| Analyzer gate | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| Schema gate | `git -C <BE> show origin/develop:src/schema.gql` in a `mktemp -d` dir + block-anchored checks + `dart run tool/schema_check/dump_documents.dart <dir>` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → 55 × OK |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PET-01 | lenient parse of new `OwnedPet`/`Pet`/`CompanionOutcome`/mission companion fields; display name; vitality rule (steady/resting/defeated, floor rounding, deadline, unsynced clock) | unit | `flutter test test/models/owned_pet_test.dart test/models/pet_test.dart test/models/companion test/models/quest_result test/models/mission` | ✅ extend; ❌ W0 `test/models/companion/*` |
| PET-01 | `name_rules` extraction keeps the character-creation behaviour | unit | `flutter test test/utils/name_rules_test.dart test/screens/characterCreation` | ❌ W0 `name_rules_test.dart` |
| PET-02 | `CompanionVitalityCubit` ticks only while needed, offset resync, close cancels | bloc | `flutter test test/screens/mainScreen/tabs/journal/companionVitalityCubit` | ❌ W0 |
| PET-02 | Journal rows: «Vita», rising number with fake clock, «A riposo…», defeated faded + not tappable, slot life, name title + species | widget | `flutter test test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart test/screens/mainScreen/tabs/journal/components` | ✅ extend |
| PET-03 | card restyle, `CompanionRow` with card + long press, details sheet content, frame extraction keeps spell sheet green | widget | `flutter test test/shared/components test/screens/mainScreen/tabs/shop test/screens/mainScreen/tabs/journal` | ✅ extend; ❌ W0 `companion_info_sheet_test.dart`, `details_sheet_frame_test.dart` |
| PET-03 | `PetFragment` + `maxLifePoints` (live-safe) | document pin | `flutter test test/graphql/shop_documents_test.dart test/graphql/character_fragment_test.dart` | ✅ change pin |
| PET-04 | row gating (character or companion), sheet targets, «Bevi» off during the character's wait, `give` single-flight, outcome face for a companion, refusal codes + copy | unit + bloc + widget | `flutter test test/repository/item_use_failure_test.dart test/repository/item_use_repository_test.dart test/screens/mainScreen/tabs/journal/potionCubit test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart test/screens/mainScreen/tabs/journal/sections/items_section_test.dart test/repository/pet_equip_failure_test.dart` | ✅ extend |
| PET-05 | rename repository + classifier, `CompanionNameCubit`, name sheet (UX errors, refused notice, retry/skip), prompt after purchase and after a prize result, details-sheet entry, display name in wording | unit + bloc + widget | `flutter test test/repository/pet_rename_failure_test.dart test/screens/mainScreen/tabs/journal/companionNameCubit test/shared/components/popup/companion_name_sheet_test.dart test/screens/mainScreen/tabs/shop/shop_test.dart test/screens/mainScreen/components/quest_result_presenter_test.dart` | ❌ W0 (3 new); ✅ extend |
| PET-06 | life line, defeat line with `fullLifeAt − resolvedAt`, nothing when unharmed, named xp line; ambush page inherits | unit + widget | `flutter test test/utils/quest_outcome_lines_test.dart test/shared/components/popup/quest_result_sheet_test.dart test/shared/components/popup/ambush_report_carousel_test.dart` | ✅ extend |
| PET-07 | `petRecovered` category (storage key, wire type, label, no popup); `ambush` + legacy wire type; presenter suppresses `ambush|<id>` banner when the carousel opens; mid-travel ambush result presented (Map visible, travel active) | unit + widget | `flutter test test/models/notification_category_test.dart test/models/push_event_test.dart test/screens/mainScreen/tabs/settings test/screens/mainScreen/components/quest_result_presenter_test.dart test/screens/mainScreen/components/notification_intent_landing_test.dart` | ✅ extend |
| PET-07 | rerouted travel moves the pawn from the ambush point | unit | `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit_test.dart` | ✅ green today (35 cases) |
| PET-08 | companion slider bounds/floor/«Sconfitto», correction JSON only with a companion, lenient parse | unit + widget | `flutter test test/models/mission test/models/request test/screens/innkeeper/missionCompletion` | ✅ extend |
| PET-09 | selections flipped + registry 55 + schema check + full suite | gate | gate script + schema check + full suite | ✅ |
| PET-09 | device: defeat, rest, potion, name, ambush mid-travel with mount, «in forze» push, innkeeper slider, details | manual | `22-HUMAN-UAT.md` | ❌ (created in the last plan) |

### Sampling Rate
- **Per task commit:** touched tests + analyzer gate + trailer check
- **Per plan:** the test directories named in the plan
- **Phase gate:** full suite green, schema check 55 × OK, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/helpers/fixtures/shop_fixtures.dart` — extend `petJson` (`maxLifePoints`, `recoveryTime`, `imagePath`) and `ownedPetJson` (`name`, `defeated`, `lifeAsOf`, `fullLifeAt`, `potionRecoveryUntil`, `id?`); `companionOutcomeJson` beside the quest-result fixtures; mission companion fixtures beside the Phase 21 ones
- [ ] `test/models/companion/companion_vitality_test.dart`, `companion_display_name_test.dart`, `test/models/quest_result/companion_outcome_test.dart`
- [ ] `test/utils/name_rules_test.dart`, `test/utils/companion_lines_test.dart`
- [ ] `test/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit_test.dart`, `companionNameCubit/companion_name_cubit_test.dart`
- [ ] `test/shared/components/popup/companion_info_sheet_test.dart`, `details_sheet_frame_test.dart`, `companion_name_sheet_test.dart`
- [ ] `test/repository/pet_rename_failure_test.dart`, `companion_repository_test.dart` (rename cases)
- [ ] Mocks: `MockCompanionNameCubit`, `MockCompanionVitalityCubit` in `test/helpers/mocks.dart`
- No framework install, no golden test (none exist).

## Copy table (provisional, no UI phase; Italian verbatim)

| Place | Copy | Note |
|-------|------|------|
| Journal row / details — life | «Vita: 40 / 100» | D-09 |
| Journal row — resting | «A riposo: in forze fra 1 h 20 min» | D-09, `formatGameDuration` |
| Journal row — defeated | «Sconfitto: torna fra 3 h» | D-09 |
| Journal row / details — companion potion wait | «Pozione: pronta fra 20 min» | pattern «pronta fra …» (Phase 18) |
| Journal parchment — subtitle | «Worg» (species, smaller) | D-20 |
| Details — recovery time | «Recupero completo: 10 h» | from `recoveryTime` |
| Details — rename | «Dai un nome» / «Cambia nome» | D-19 |
| Potion sheet — companion parchment | «Dai a Fenrir» | D-08 |
| Potion refusal title (companion) | «Pozione non data» | character keeps «Pozione non bevuta» |
| Potion refusal — defeated | «Fenrir è sconfitto: solo il riposo lo rimette in forze» | `PET_DEFEATED` |
| Potion refusal — companion wait | «Fenrir non reggerebbe un'altra pozione: pronta fra 20 min» | mirror of `potion_notice.dart:33-34` |
| Potion refusal — full life | «Questa pozione non farebbe nulla a Fenrir adesso» | `ITEM_NO_EFFECT` |
| Equip refusal — defeated | title «Compagno non equipaggiato» (existing) + «È ancora sconfitto: aspetta che torni in forze» | `PET_DEFEATED` on `equipPet` |
| Name prompt | title «Come chiamerai il tuo Worg?», field «Nome», «Chiamalo così», «Più tardi» | D-18 |
| Name refused | «Il nome non è accettato dalle cronache, scegline un altro» | reuse `character_creation_messages.dart:34-35` |
| Name UX errors | «Il nome deve avere almeno 2 lettere», «Il nome può avere al massimo 20 caratteri», «Solo lettere, spazi, apostrofi e trattini» | reuse `:13-15` |
| Rename other failures | «Connessione assente, riprova», «Qualcosa è andato storto, riprova» | existing tone |
| Result — life | «Fenrir: 120 / 300 di vita» | D-10 |
| Result — defeat | «Fenrir è stato sconfitto: riposa e tornerà fra 10 h» | D-10, C-9 |
| Result — xp | «Fenrir guadagna 12 PE» (fallback «Il tuo compagno guadagna 12 PE») | D-20, W-5 |
| Settings toggles | «Imboscate» (existing), «Compagno in forze» (new) | D-11, D-14 |
| Innkeeper | heading «Compagno: Fenrir», «120 / 300», marker «Sconfitto» at the floor | D-17 (utility) |
| Pushes | built by the BE (e.g. «Imboscata!» / «Fenrir è stato sconfitto…», «Fenrir è di nuovo in forze») | W-8, W-9 |

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged |
| V3 Session Management | no | unchanged |
| V4 Access Control | yes | `useItem` target and `renamePet` act only on the bearer's character and its own entries (BE ownership filter, authz matrix); FE sends only ids it read from its own character |
| V5 Input Validation | yes | name: client UX rules (extracted `name_rules`) + server normalisation and content filter (D-21); lenient parsing at the model boundary (bad entry → dropped/null, never the character) |
| V6 Cryptography | no | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Offensive companion name shown in pushes/streams | Tampering / Repudiation | server-side content filter (same as character name), refusal code |
| Potion on another player's companion | Elevation | BE ownership filter on the target |
| Equip of a defeated companion with a stale client | Tampering | BE `PET_DEFEATED`; FE gate is convenience |
| Names leaked in logs | Information disclosure | no `appLog` of names/results (`hardening_check.sh`) |

## Sources

### Primary (HIGH confidence)
- Codebase `feat/22-companion-defeat-rest-and-recovery` `d0cf72f4`: files cited inline; 68 files formatter-checked (`--output=none`); probe `test/_probes/phase22_probe_test.dart` (run, deleted) + `travel_progress_cubit_test.dart` (35 cases green).
- BE read-only `origin/develop` `2c462cbe`: `src/schema.gql` (`OwnedPet`, `Pet`, `UseItemResult`, `useItem`, `equipPet`, `EquipPetRequest`, `AmbushReport`, `PushEventType`, `MissionFightOutcome`, `MissionFightEffects`, `MissionFightInput`, `ParticipantOverrideInput`, `SaveMissionDraftInput`, `CommonResponse`), `src/travel/ambush/ambush-plan.ts`, `ambush-detour.ts`, `ambush.updates.ts`, `src/economy/trade/trade-pets.ts`, `src/quests/outcomes/outcome-plan.ts`, `src/models/character/owned-pet.model.ts`, `src/characters/pets/equip-pet.updates.ts`; BE `.planning/phases/23-sconfitta-riposo-recupero-compagni/23-CONTEXT.md`, `23-REPO-RULES.md`.
- Planning: `22-CONTEXT.md`, `22-REPO-RULES.md`, `21-RESEARCH.md` (format), `13-CONTEXT.md` (D-13, D-15, D-17), `16-CONTEXT.md` (D-02, D-08), `19-CONTEXT.md` (D-03, D-18), `ROADMAP.md`, `REQUIREMENTS.md`, `docs/rules/*.md`, project memory (FE 21 UAT lessons).

### Secondary / Tertiary
- None (no web sources needed: the domain is this codebase and its BE).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — nothing new.
- Architecture: HIGH for the FE map (file:line, probe, existing reroute tests); MEDIUM for the wire (BE research pending).
- Pitfalls: HIGH — each tied to a file:line or a BE read.

**Research date:** 2026-11-14
**Valid until:** the BE Phase 23 research fixes the SDL (then refresh names in both REPO-RULES).

## Recommended plan order (sequential, TDD RED → GREEN, one concern per plan)

| # | Plan | Gate | Depends on | Req |
|---|------|------|-----------|-----|
| 22-01 | Models (lenient, unselected): `OwnedPet` fields, `Pet.recoveryTime`, `CompanionOutcome` + `QuestResult.companion`, mission companion (`MissionCompanion`, `companionLifeAfter` on effects and correction), fixtures; doc comment C-10 | pre-gate | REQUIREMENTS PET IDs | PET-01, PET-06, PET-08 |
| 22-02 | Pure rules: `companionVitalityOf`, `companionDisplayNameOf`, `companion_lines.dart`, `name_rules.dart` extracted from `CharacterDraft` (refactor) | pre-gate | 22-01 | PET-01, PET-05 |
| 22-03 | `CompanionVitalityCubit` (bloc_test, fake clock) + Journal provider; `PetFragment.maxLifePoints` selected (live-safe; pins updated) | pre-gate | 22-02 | PET-01, PET-02 |
| 22-04 | Cards and details: `DetailsSheetFrame` extracted from `SpellInfoSheet`, `CompanionCard` restyle, `CompanionInfoSheet`/`CompanionInfo` (rename entry behind the switch) | pre-gate | 22-03, U-1 | PET-03 |
| 22-05 | Journal «Compagno»: three parchment states with live life, slot life, name title + species, long press → details hosted in the Journal Stack | pre-gate | 22-04 | PET-02, PET-03 |
| 22-06 | Shop and prize lists: `CompanionRow` with card + long press (shop, basket, innkeeper), shop details host (style commit of `equipment_info_display.dart` first), sell list with display names, quest-sheet prize card per U-2 | pre-gate | 22-04, U-2 | PET-03, PET-05 |
| 22-07 | Potion plumbing: `KlimmeckGraphQl.useItem(itemId, {petId})` (document unchanged), `ItemUseFailure.petDefeated` + companion wait, `PetEquipFailure.defeated`, `PotionCubit.give`, notices | pre-gate | 22-01 | PET-04 |
| 22-08 | Potion sheet: row gating (C-2), «Dai a <nome>» targets from vitality, «Bevi» off during the character's wait, companion outcome face; hidden behind the switch until the gate | pre-gate | 22-03, 22-07 | PET-04 |
| 22-09 | Name plumbing: `RenamePet` document (registry 55, pins), `CompanionRepository.rename` + `PetRenameFailure`, `CompanionNameCubit` (shell), `CompanionNameSheet` | pre-gate | 22-02 | PET-05 |
| 22-10 | Name entry points + wording: prompt after purchase (bought ids captured at `TransactionDone`), after a prize result (presenter), details «Dai un nome»/«Cambia nome»; display name in potion sheet, notices, cards (behind the switch) | pre-gate | 22-05, 22-06, 22-09 | PET-05 |
| 22-11 | Result sheet lines (life, defeat `fullLifeAt − resolvedAt`, named xp) + notifications (`petRecovered` category/toggle, `ambush` with legacy wire type, presenter suppression of `ambush|<id>`) | pre-gate | 22-01, 22-02 | PET-06, PET-07 |
| 22-12 | Innkeeper companion slider (`LifeSlider` extracted, correction JSON with `companionLifeAfter` only with a companion, recap line) | pre-gate | 22-01 | PET-08 |
| 22-13 | Schema gate on the merged BE SDL → renames RED-first if names differ → select ownedPets fields, `recoveryTime`, `QuestResultFragment.companion`, mission companion fields; `UseItem` target variable; flip the potion/rename switch; registry final; schema check 55 × OK; full suite | **gated on BE Phase 23 merge** | 22-01..22-12 | PET-09 |
| 22-14 | Device E2E (`22-HUMAN-UAT.md`, orchestrator-guided, F-10 steps), fixes in TDD during the UAT | **gated, human** | 22-13; BE boot + UAT data | PET-09 |
| 22-15 | `BACKEND-NOTES.md`, requirements mark-complete, closing docs | **gated** | 22-14 | PET-09 |

22-11 and 22-12 are independent of the Journal chain and can move earlier; 22-14/22-15 may merge (Phase 21 had them in one plan). If the BE keeps the catalogue `petId` as the only key (W-2), 22-01 drops `OwnedPet.id`; if it serves `companion` only when damaged (draft), 22-11's xp line keeps «Il tuo compagno».

## RESEARCH COMPLETE
