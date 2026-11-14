# FE Phase 21 - Code review, area A (players' mission lock + inner-place teleport)

Summary: 0 critical, 0 high, 1 medium, 4 low (5 findings). Read-only review; nothing run.

Verified OK (no finding):
- Every call site of travel start, travel preview, quest acceptance, shop buy/sell, equipItem, pet equip/unequip, spell equip/unequip and useItem is either disabled from `missionInProgress` or mapped to the banner through its classifier (`travel_failure`, `quest_acceptance_failure`, `transaction_failure`, `pet_equip_failure`, `spell_equip_failure`, `item_use_failure`, `equipment_failure`). There is no entry point the plans missed: the Board is the only caller of `accept`, the Map pawn is the only caller of `TravelCubit.preview`, and the Journal is the only caller of `equipItem`.
- D-16: the pawn label reads only `guidedMissionInProgress`. The Journal, Board and satchel read only `missionInProgress`. `QuestViewer.of` does not read lanes.
- D-23/D-31: `missionInProgress` comes after prison, awaiting-rescue, lane-busy, full, not-in-city, points and no-effect in `_availabilityOf`. A failed places read is swallowed in `_readPlaces`, because `InnkeeperRepository._guard` wraps every error as `InnkeeperException`. The players' drop rule (`MapUtils.dropTargetCity`) is untouched.
- D-30: no GraphQL document selects the three flags (grepped `lib/graphql`, `lib/repository/services`, `tool`). No `// ignore:`. No payload logging in the area.

## MEDIUM

### A-01 Inner places are droppable but invisible below the city zoom, and they beat the city
- File: `lib/screens/mainScreen/tabs/map/utils/teleport_drop.dart:57-73` (rule), `lib/screens/mainScreen/tabs/map/layers/teleport_poi_layer.dart:35-39` (visibility).
- Problem: `TeleportPoiLayer` hides the dots when `zoom < MapConstants.cityVisibleZoom` (2.5). `teleportDropTarget` has no zoom input and snaps to any place within 32 screen px.
- Scenario: the innkeeper is zoomed out, with no dots on screen, and drops the group on a city marker. A ruin or forest within 32 px of that marker (the usual case, since labels read "Rovine presso X") silently wins. The group lands in the ruin and the wizard names the wrong place, so the step 2 enemy filter uses the wrong POI types.
- Also: a drop inside a city polygon is overridden by any place within 32 px.
- Fix: pass `zoom` into `teleportDropTarget` and ignore `places` below `cityVisibleZoom`, so only visible targets are droppable. In `TeleportPawnLayer.resolvePawnDrop` read `pawnMapController.camera.zoom`. Add a test "below the city zoom the city rule applies (D-29)" in `teleport_drop_test.dart`.

## LOW

### A-02 A place with no known PoiType is labelled with the bare city name
- File: `lib/models/travel/teleport_destination.dart:57-65` (`placeLabelOf`, `ofPlace`). Test: `test/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit_test.dart:62`.
- Problem: `poiTypesFrom` drops unknown wire names. A POI whose only type is new to the client, such as `cave`, has `_placeTypeOf == null`, so `placeLabelOf` returns `cityName`. The place then looks identical to the city marker, with `isCityMarker == false` and no type for the step 2 filter.
- Test gap: the cubit test fixture `placeOf(id:'poi-cave-1', types: ['cave'])` uses a type that is not in `PoiType`. It passes only through this fallback, so the test hides the behaviour.
- Fix: make `ofPlace` return `null` when no known place type exists, for example `if (_placeTypeOf(poi) == null) return null;`. Use a real type in the test fixture (`forest`, say) and add a case "unknown type is not a destination".

### A-03 Equipment info sheet keeps an active-looking ribbon that does nothing under the lock
- File: `lib/screens/mainScreen/tabs/journal/journal.dart:259-264` with `lib/shared/components/popup/equipment_info_sheet.dart:347-355`.
- Problem: under the mission lock `onEquip` becomes `null`. The `BookmarkRibbon` is still drawn from `isEquipped != null` and its tap is `widget.onEquip?.call()`, a silent no-op with no «Missione in corso» hint. Every other locked surface (rows, Compagno, Magie) says why. No test covers the sheet under lock.
- Fix: hide the ribbon, or render it disabled with the line `missionInProgressLabel`, when `onEquip == null`. Pass `isEquipped: null` while locked, or add a `lockedLine` parameter. Add a widget test in `journal_mission_lock_test.dart`.

### A-04 The mission flag and the locked-section widget are duplicated
- Files:
  - `journal.dart:42-44` and `spells_section.dart:46-47` define the same `_isOnMission(Character)`.
  - Inline `status?.missionInProgress ?? false` in `items_section.dart:171`, `companion_section.dart:51`, `character_marker_layer.dart:1065` and `main_screen.dart:309`.
  - `_ignoreToggle` and `_missionLocked` are copied between `companion_section.dart:811-823` and `spells_section.dart:956-968`.
  - `PendingRequest._instantOrNull` duplicates `CharacterStatus._instantOrNull`.
  - Naming drifts between `isOnMission` (viewer, satchel) and `missionInProgress`.
- Why: one rule (D-16) is spread over 7 sites, so a change touches all of them.
- Fix: add `bool get isMissionLocked => status?.missionInProgress ?? false;` on `Character` (or `CharacterStatus`), and one shared `MissionLockedSection` widget under `lib/shared/components`. Move `_instantOrNull` to a shared parsing helper.

### A-05 `TeleportPawnLayer` overrides the mixin's drop path and leaves vestigial members
- File: `lib/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart:46-71`, `lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart:45-50`.
- Problem: the layer overrides `resolvePawnDrop` and turns `onPawnDragEnd(LatLng? _, City? _)` into a stub that is reached only without a release point. The mixin's `dropCities` and `MapUtils.dropTargetCity` default path are dead for this layer, and the abstract signature no longer describes what it does. Clean-code smell, not a bug.
- Fix: have the mixin take a drop resolver (`LatLng -> T`) and a null-release callback, or split the release resolution out of `PawnDragging`, so the teleport layer does not override a template method to ignore it.

# FE Phase 21 review, area B (guided mission wizard, plans 21-10..21-15)

Summary: 0 CRITICAL, 3 HIGH, 4 MEDIUM, 7 LOW (14 findings). Diff `5e1d77e2..HEAD`, BE pinned at `5b8f96fb`. Static reading only, nothing run.

## Answers to the mandatory checks

### C1. Documents and fragments against the pinned SDL: no mismatch found

Operations checked (app file:line, then SDL line in `src/schema.gql@5b8f96fb`):

- `GetMissionDraft(pendingQuestId: ID!)` (`lib/graphql/queries/mission_queries.dart:8-15`) against `missionDraft(pendingQuestId: ID!): MissionDraft` (schema:725). OK.
- `ListMissionEnemies($pendingQuestId: ID!, $showAll: Boolean)` (`mission_queries.dart:21-27`) against `missionEnemies(pendingQuestId: ID!, showAll: Boolean = false)` (schema:726). OK. A nullable variable into an argument with a default is valid, and the app always sends a non-null `showAll` (`graphql.dart` `getMissionEnemies`).
- `GetMissionPrizeOptions` (`mission_queries.dart:33-...`) against `missionPrizeOptions(characterId: ID!, pendingQuestId: ID!)` (schema:727). The selected fields `character title maxRarity block{prizeCoins xpPrize prizeItem randomLoot pet spell cure} equipment loot pets spells` all exist in `MissionPrizeOptions` and `QuestPrizes` (schema:515, 795-803). `prizeItem` is a single `AssetQuantity` and `randomLoot` is a list, as selected, and the union spreads are `EquipmentItem` and `LootItem`.
- Mutations (`lib/graphql/mutations/mission_mutations.dart`): `startMissionDraft(pendingQuestId: ID!)`, `saveMissionDraft(input: SaveMissionDraftInput!)`, `simulateMissionFight(input: SimulateMissionFightInput!)` and `discardMissionDraft(pendingQuestId: ID!)` match schema:538-551. The discard selection `successful response` matches `CommonResponse`. `completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!` matches the signature given in the brief and selects the existing `QuestResultFragment`. It is not in the pinned SDL, so it was checked against the brief only.
- `MissionDraftFragment` (`lib/graphql/fragments/mission_draft_fragment.dart:15-43`). Every field exists with the right shape.
  - Draft: `id quest questType step place startedAt updatedAt participants fights prizes`.
  - Participant: `character name title maxLifePoints pendingQuest`.
  - Fight and enemies: `verdict`, `enemies{quantity enemy{...}}`.
  - Outcome: `outcomes{character hpBefore injuriesBefore consumablesAvailable{item quantity} spellsAvailable{spell usages} simulated corrected}`.
  - Effects: `hpAfter injuriesAdded consumablesUsed spellsUsed`.
  - Prize: `prizes{character xp coins cure{lifePointsShare canHeal} items{item quantity} pet spell}`.
  - Enemy: `id name imagePath xp lifePoints legendary`.
  - Nested selections are all valid; `QuestCure` is `{lifePointsShare, canHeal}` at schema:761.
- Input shapes (`lib/models/request/mission_draft_inputs.dart`):
  - `MissionEnemyInput` sends `{enemy, quantity}` (`:21`), matching schema:429.
  - `ParticipantOverrideInput` sends `characterId, hpAfter, injuries[name], consumablesUsed[{item,quantity}], spellsUsed[{spell,usages}]` (`:92-105`), matching schema:567 and `ItemUsageInput` / `SpellUsageInput`.
  - `MissionFightInput` sends `enemies` plus optional `corrections` (`:126-132`), matching schema:452.
  - `MissionPrizeInput` sends `characterId, coins{gold,silver,copper}, cure, items[{item,quantity}], pet, spell, xp` (`:236-244`), matching schema:495. `pet` and `spell` are sent as explicit nulls, which the schema accepts (nullable ID).
  - `SaveMissionDraftInput` sends `pendingQuestId`, and `step` / `place` / `fights` / `prizes` only when present (`:274-282`). The `step` names `teleport|fights|prizes|recap` equal the SDL enum.
  - `SimulateMissionFightInput` sends `pendingQuestId, fightIndex, enemies` (`:300-304`), matching schema:954.
- Over-selection (not a mismatch): the query selects `block.prizeCoins`, `block.xpPrize` and `block.cure`, but `MissionPrizeOptions.tryFromJson` (`lib/models/mission/mission_prize_options.dart:76-96`) never reads them. See B-12.
- The registry (`tool/schema_check/schema_check_documents.dart`) lists all nine mission documents and the count test says 55.

### C2. Corrections for later fights sent together with a changed fight k: THE APP DOES IT, AND THE BE REFUSES

BE rule, in `mission-draft-save.service.ts`:
- `fightsOf` (`:259-276`) first runs `reconcileFights`, which voids k and every fight after the first changed one.
- It then calls `corrected()` for every incoming fight whose `corrections != null`, in index order.
- `corrected()` throws `OUTCOME_OVERRIDE_INVALID` when `fight.verdict == null` (`:320-321`).
- If the correction of k really changes (`sameCorrections` false), `resetFrom(updated, index+1)` voids the following fights (`:343-352`). A non-null correction for a later fight that is already corrected in the same payload is then refused.

App behaviour:
- `fightsInputWithCorrections` (`mission_draft_inputs.dart:332-344`) sends, for every fight other than k, `_servedCorrectionsOf(fight)`. That is the full list whenever the served fight has any `corrected`.
- `fightsInputWithEnemies` (`:320-329`) keeps the served corrections for every fight whose own enemies are unchanged (`_correctionsKeptFor`). It does not consider that an earlier fight changed.

Scenario 1 (via «Avanti»):
1. Fights F0 and F1 are both simulated and both «Avanti»'d, so both are corrected on the BE.
2. On F1 the innkeeper taps «Indietro» to F0 (`mission_completion_screen.dart:442-459`) and moves a slider.
3. «Avanti» on F0 calls `saveCorrections(0, ...)`. The payload has F0 with changed corrections and F1 with its served non-null corrections.
4. BE: F0 changed, so F1 is voided, then F1's non-null corrections hit `verdict == null`. The whole save is refused.
5. The app shows «Valori non accettati: controlla il modulo» and the draft is unchanged. The innkeeper can never change an earlier fight after a later one is corrected, except by «Rilancia» (which discards the correction).

Scenario 2 (enemies):
1. F0 and F1 are corrected. From F0 or F1 the innkeeper taps «Cambia nemici» and changes the enemies of F0 only.
2. `fightsInputWithEnemies` gives F0 `null` (enemies differ) and F1 its served corrections (F1's enemies are unchanged).
3. BE: reconcile voids F1, then the F1 corrections are refused with `OUTCOME_OVERRIDE_INVALID`.
4. Changing the enemies of any fight is refused whenever a later fight is corrected. Changing the last fight works.

Not affected: the forward path (simulate 0, «Avanti», simulate 1, «Avanti») sends served corrections for earlier fights that are identical on the BE (idempotent), so no refusal. «Rilancia» sends no corrections. See B-01 and B-02.

### C3. Full corrections list with `hpAfter` for every participant: verified in every save path

- `FightStep._orderedCorrections` (`fight_step.dart:87-90`) may omit a participant that has no effective effect.
- `fightsInputWithCorrections` completes through `_completedCorrections` (`mission_draft_inputs.dart:378-391`), one entry per served outcome, with fallback `MissionFightEffects(hpAfter: hpBefore)`.
- `_servedCorrectionsOf` (`:349-355`), used by the enemies path, also completes.
- `hpAfter` is a required `int` in `MissionCorrection`, so it is never absent.
- Idempotence with the BE was checked. `effectsKeyOf` compares `participantEffectsOf` JSON; the app preserves order, drops zero quantities (the BE never stores them) and re-sends the same injuries, so a repeated identical save does not void the following fights.
- Gap: the branch `...given.where(!servedIds)` (`:389`) can never be reached from the UI, since `_corrections` is only seeded from outcomes. The BE would answer `OUTCOME_NOT_PARTICIPANT` if it were reached. Dead code, see B-12.

### C4. BE caps against UI bounds; adding the cure is impossible

| Cap | BE | UI |
|---|---|---|
| Fights | ≤ 10 (`mission-draft.inputs.ts:21`) | `_canAddFight` with `maxMissionFights` (`encounters_step.dart:59-60`). OK |
| Enemy entries per fight | ≤ 10 | `_pick` with `maxEnemyEntriesPerFight` (`:91`). OK |
| Enemy quantity | 1..20 | stepper `max: maxEnemyQuantity`, `_setQuantity` returns above 20; below 1 removes the entry. OK |
| Enemies per fight | ≥ 1 (`@ArrayMinSize(1)`) | `_canGoOn` requires every fight to be non-empty. OK |
| Prize item quantity | 1..99, unique item, ≤ 500 entries | stepper `min: 1, max: 99`, `withItemQuantity` clamps, `withItemAdded` merges duplicates (`:180-201`). OK. The 500 entries cap has no UI bound, but only the served catalogue can be added, so unreachable in practice. |
| Coins / xp | integers ≥ 0, but the GraphQL `Int` scalar is 32-bit | `digitsOnly` plus `max(0, ...)`, no ceiling. See B-11. |
| `cure: true` | accepted only when the title's block has a cure (`cureFor`) | the app only ever sends `true` when the served prize has one. Safe. |

Adding the cure back is impossible.
- Evidence: `PrizesStep._rowsOf` shows `_cureRow` only `if (prize.cure)` (`prizes_step.dart:216`) and the only mutation is `withoutCure()` (`mission_draft_inputs.dart:210`). There is no way to restore it, not even after leaving and re-entering the step, because the BE stores `cure: null` after the save.
- `MissionPrizeOptions` does not model `block.cure`, although the query selects it.
- The cure row also reads `widget.draft.prizeOf(id)?.cure` (`prizes_step.dart:313`), which is `null` after a saved removal. See B-03 for the exact change.

### C5. «Luogo» when the participants read fails: confirmed, buttons disabled with no retry

- `MissionParticipantsCubit.load` (`mission_participants_cubit.dart:23-45`) does the characters read and `listPointsOfInterest` in one try. Any failure gives `MissionParticipantsFailed`.
- `PlaceStep` (`place_step.dart:31-35`) has `canAct = loaded != null && !isSubmitting`, and both buttons use `canAct`.
- The only caller of `load` is `_openServedStep` (`mission_completion_screen.dart:138-146`), run once when the draft first becomes ready. There is no retry button.
- The innkeeper must leave and reopen the wizard to retry.
- This violates D-31 («a failed inner-places read never blocks the city teleport»). `_teleportGroup` only needs `draft.participants` and never reads the loaded state.
- No test pins the Failed state in `place_step_test.dart` or in the screen test. Fix in B-04.

### C6. Invalidation UX (D-24)

- After the enemies of fight k change, the served draft gives k and the following fights `verdict == null` and `outcomes: []`. «Da simulare» comes from the served verdict (`fight_step.dart:117`, `encounters_step.dart:224-228`), never computed locally. OK.
- Fight k cannot be simulated before k-1: `_canSimulate` (`fight_step.dart:80-84`) reads the served `isSimulated` of k-1. OK.
- `MissionDraftCubit.simulate` has no guard of its own, so the BE is the judge.
- `OUTCOME_OVERRIDE_INVALID` is mapped to `InnkeeperFailure.overrideInvalid`, then to a snackbar through the `_isExitOrNewFailure` listener (`mission_completion_screen.dart:186-215`). The cubit's `_act` bumps `failureSerial` on every refusal, so every action (save, simulate, complete, discard, start) shows a visible message. The page does not advance after a refusal (`_runThenOpen`).
- Gaps:
  - The copy «controlla il modulo» is wrong for simulate and fights (B-09).
  - A refusal caused by the app's own payload (C2) is shown as a user input error and cannot be recovered from.
  - The «Da simulare» badge in the encounters list is read by index from the served draft while the local list is edited (B-10).

### C7. D-28 and D-09: confirmed

- `grep` finds no reference to `openMissionCompletion` or `MissionCompletionScreen` outside `lib/screens/innkeeper/missionCompletion/`. The wizard is unreachable from the panel.
- The draft is created only by `MissionDraftCubit.start()` (`mission_draft_cubit.dart:50-69`) on «Inizia la missione» (`start_step.dart:33`). `load()` only reads (`:30-42`).
- Every response replaces the state (`_readyAt`, `:150-155`). There is no `SharedPreferences`, `appLog`, `print` or `// ignore` in `lib/screens/innkeeper/missionCompletion`, `lib/models/mission`, the inputs file or the repository diff. `lib/models/mission/**` and the inputs file import no Flutter.
- The page choice is local navigation only (`_page`, `_fightIndex`). `_openServedStep` runs only on the first ready state.

## Findings

### CRITICAL

None.

### HIGH

**B-01. Editing an earlier fight is refused whenever a later fight is already corrected**
- File: `lib/models/request/mission_draft_inputs.dart:332-344` (`fightsInputWithCorrections`), reached from `mission_draft_cubit.dart:110-120` and the «Avanti» of the fight page (`mission_completion_screen.dart:388-404`).
- What is wrong: for every fight other than k the payload carries `_servedCorrectionsOf(fight)`. When k's correction changes, the BE voids the following fights and then refuses their non-null corrections (`mission-draft-save.service.ts:320`, `:343-352`). See the C2 scenario 1.
- Why it matters: after two fights are done, the innkeeper goes «Indietro», fixes a slider, taps «Avanti» and gets «Valori non accettati: controlla il modulo» with no way forward except «Rilancia». That discards the manual correction and is not guessable.
- Fix: send corrections only for the fight being corrected and `null` for every other fight. `null` means unchanged on the BE, and the BE voids later fights itself when k changes.
  ```dart
  corrections: index == fightIndex ? _completedCorrections(fight, corrections) : null,
  ```
  Keep the full-list rule for k. Add a RED test: draft with F0 and F1 corrected, call with k=0 and a changed hp, assert F1 has no `corrections` key.

**B-02. Changing the enemies of fight k is refused whenever a later fight is corrected**
- File: `mission_draft_inputs.dart:320-329` and `:357-366` (`fightsInputWithEnemies`, `_correctionsKeptFor`), called by `MissionDraftCubit.saveFights` (`:81-90`).
- What is wrong: `_correctionsKeptFor` decides from the fight's own enemies only. A later fight whose enemies are unchanged keeps its served corrections, while the BE has already voided it because an earlier fight changed (`reconcileFights` stops "keeping" at the first change). See C2 scenario 2.
- Why it matters: «Cambia nemici» on any fight except the last one fails whenever a later fight is corrected. The test `fightsInputWithEnemies keeps the corrections of unchanged fights only` (`mission_draft_inputs_test.dart:~199`) only covers an unchanged prefix, never a changed fight followed by a corrected one.
- Fix: send `corrections: null` for every fight in this save. The BE keeps the stored corrections of the unchanged prefix (`reconcileFights` returns the stored record) and voids the rest. `_correctionsKeptFor` and `_sameEnemies` can then be deleted. Add a RED test for "changed k, corrected k+1".

**B-04. «Luogo» is a dead end when the participants read fails, and an inner-places failure blocks the city teleport**
- File: `lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart:23-45`, `steps/place_step.dart:35-66`, `mission_completion_screen.dart:138-146` (see C5).
- What is wrong:
  - One try wraps characters and places, so a places failure disables teleport and «Resta qui».
  - There is no retry, since `load` runs only on the first ready draft.
  - D-31 says a failed inner-places read must never block the city teleport.
- Why it matters: after «Inizia la missione» the participants are already locked (D-11). With a flaky connection the innkeeper sees a page with two disabled buttons and no message, and has to leave and reopen.
- Fix:
  1. In the cubit, read characters and places separately. A failed places read returns `MissionParticipantsLoaded(places: const {})`, so labels degrade to an empty string and nothing else breaks.
  2. In `PlaceStep` enable «Teletrasporta il gruppo» on `!isSubmitting` alone (it only needs `draft.participants`) and keep «Resta qui» gated on loaded characters.
  3. When the state is `MissionParticipantsFailed`, show a message and a «Riprova» button calling `context.read<MissionParticipantsCubit>().load(ids)`.
  4. Tests: Failed state with the teleport enabled and a retry that calls `load`; cubit test where `listPointsOfInterest` throws but characters load.

### MEDIUM

**B-03. The innkeeper can remove the cure but never put it back**
- File: `lib/models/mission/mission_prize_options.dart:76-96`, `mission_draft_inputs.dart:210`, `steps/prizes_step.dart:216` and `:312-321`.
- What is wrong: see C4. There is no toggle to add a cure that the block has, and no model field for `block.cure`.
- Why it matters: a mistaken tap on the cure «X» is irreversible within the draft (the BE stores `cure: null`).
- Fix:
  1. Model `blockCure: QuestCure?` on `MissionPrizeOptions`, parsed with `QuestCure.tryFromJson(blockJson['cure'])`, and add it to `props`.
  2. Add `MissionPrizeInput.withCure(bool)`.
  3. In `PrizesStep`, show the cure row when `prize.cure`, rendering `lifeShareLine(options?.blockCure ?? servedCure)`. Never read `draft.prizeOf(id).cure` alone, since it is null after a saved removal.
  4. When `!prize.cure && options?.blockCure != null`, show an «Aggiungi cura» row or button (or a catalogue-sheet entry). The BE refuses `true` when the block has none, so the app is safe.
  5. Tests: add after removal, `toJson` carries `cure: true`.

**B-05. A failed enemy list read is silent: an empty bestiary with no message or retry**
- File: `steps/encounters_step.dart:142`, `components/enemy_picker.dart:27-68`, state in `missionEnemiesCubit/mission_enemies_state.dart:21-22`.
- What is wrong: `MissionEnemiesState.failure` is kept but never read by the UI. On failure the picker shows an empty list (the loader only shows while `isLoading && visible.isEmpty`).
- Why it matters: the innkeeper sees an empty list and thinks there are no enemies for the place. Recovery is accidental (toggle «Mostra tutti» or leave and re-enter).
- Fix: in `EnemyPicker`, when `state.failure != null && state.enemies.isEmpty`, show a text and a «Riprova» button calling `cubit.load()`. Add a widget test.

**B-06. A failed prize options read is silent and disables «Aggiungi premio» without a retry**
- File: `steps/prizes_step.dart:204-249`, state `missionPrizeOptionsCubit/mission_prize_options_state.dart:18`.
- What is wrong: `failures` is written by the cubit (`mission_prize_options_cubit.dart:48-52`) and never read. `canAdd` requires `options != null`, so the button is disabled and names fall back to «oggetto» (`unnamedItemLabel`).
- Why it matters: the innkeeper cannot add any prize after a transient failure and gets no message. A retry happens only by re-entering the step.
- Fix: in `_header`, when `state.failures[id] != null`, show a «Riprova» action calling `loadFor(id)` (the cubit already supports retrying a failure, see its doc comment). Add a widget test.

**B-07. Changing the enemies leaves the draft step at «prizes» or «recap» while fights are «Da simulare»**
- File: `mission_completion_screen.dart:375-385` (`_saveFights` passes `step: hasFights ? null : prizes`).
- What is wrong: a trip back to «Scontri» saves the new fights without moving the stored step. If the innkeeper leaves before re-simulating, resume (`_pageOf(draft.step)`) opens straight on «Riepilogo» (or «Premi') with unsimulated fights, and «Completa» is enabled with no gate (`recap_step.dart:123-128`). The recap lines show the fights without a verdict and no PV line.
- Why it matters: the innkeeper can complete a mission with fights that were never simulated. What the BE does with that is not in the pinned SDL (`completeGuidedMission` is not in `5b8f96fb`), so the guard decision is yours.
- Fix: send `step: MissionDraftStep.fights` when `hasFights`, so resume reopens on «Scontri». Optionally disable «Completa» while any `fight.isSimulated == false`, and add a test.

### LOW

**B-08. `FightStep` is not keyed by fight index**
- File: `mission_completion_screen.dart:321-328`, `steps/fight_step.dart:60-68`.
- What is wrong: when the page moves from fight k to another fight, `didUpdateWidget` reseeds only if the two served fights differ. Two consecutive fights with identical `MissionFight` values (same enemies and same outcomes, for example no damage at full HP) keep the unsaved slider edits of the previous fight, and «Avanti» would save them on the other fight.
- Fix: `FightStep(key: ValueKey(_fightIndex), ...)`.

**B-09. «controlla il modulo» is shown for refusals that have no form**
- File: `mission_completion_screen.dart:59-60` and `:226-233`.
- What is wrong: `OUTCOME_OVERRIDE_INVALID` also comes from simulate, fights saves and prize saves (BE caps and order rules).
- Fix: neutral copy such as «Valori non accettati», or a per-action message.

**B-10. «Da simulare» or «Vittoria» in the encounters list is wrong after removing or adding fights locally**
- File: `steps/encounters_step.dart:223-228` (`_statusOf` reads `widget.draft.fights[index]`) while `_fights` is edited locally (`_removeFight`, `_addFight`).
- What is wrong: after removing card 0, the old card 1 now sits at index 0 and shows the verdict of the removed fight.
- Fix: keep the served status per local entry (a record of picks plus the served `verdict`), or hide the status once the local list differs from the served one.

**B-11. Coins and xp field parsing**
- File: `steps/prizes_step.dart:127` (`int.tryParse(text) ?? 0`) and `:293-310`.
- What is wrong: a string over 19 digits parses to `null` and silently becomes `0` while the field still shows the digits. A value above 2^31-1 is sent as GraphQL `Int`, which the server coerces and rejects as `BAD_USER_INPUT`, shown only as «Qualcosa è andato storto, riprova».
- Fix: limit the input length (for example `LengthLimitingTextInputFormatter(9)`) or clamp to 2147483647 and put the constant in `mission_limits.dart`; add a test.

**B-12. Dead code, dead selection and magic numbers outside `mission_limits.dart`**
- `fightsInputOf` (`mission_draft_inputs.dart:311`) is used only by tests.
- The branch `...given.where(...)` (`:389`) is unreachable from the UI.
- `block.prizeCoins`, `block.xpPrize` and (until B-03) `block.cure` are fetched in `mission_queries.dart` and never read.
- The literal `1` for the minimum prize item quantity appears in `prizes_step.dart:351` and `mission_draft_inputs.dart:192`.
- The literal `1` for the minimum life appears in `correction_section.dart:87-93`.
- Fix: delete or use the dead pieces, add `minPrizeItemQuantity` (and a life floor if you want to name it) to `mission_limits.dart`.

**B-13. Small robustness and cosmetic items in the Luogo page**
- `PlaceStep._rowOf` (`place_step.dart:78-80`) renders «Aldo · » with a trailing separator when the place is unknown (`placeLabelFor` returns an empty string).
- `_teleportGroup` (`mission_completion_screen.dart:357`) destructures `[first, ...rest]` and would throw on an empty `draft.participants`.
- Fix: omit the separator for an empty label; guard the empty list (or disable the button).

**B-14. Test gaps**
- No test pins the C2 scenarios (changed k followed by a corrected k+1), either for the input builders or the cubit.
- No test for the participants Failed state on the place page.
- No test that a failed enemy or prize options read is visible.
- The test `the BE caps are named in one place` (`mission_draft_inputs_test.dart:301`) only asserts constants equal to literals.
- Add the RED tests listed under B-01, B-02, B-03, B-04, B-05 and B-06.
